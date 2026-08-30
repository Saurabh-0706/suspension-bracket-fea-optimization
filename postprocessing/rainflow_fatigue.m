%% rainflow_fatigue.m
%
% Fatigue-damage estimate from the quarter-car mount-force history
% (dynamics_matlab/quarter_car_ode.m, or the Simulink model's logged
% F_mount_simulink), using rainflow cycle counting + Miner's rule against
% a published (not lab-measured) S-N curve for a representative
% structural steel.
%
% No toolbox required: rainflow counting is implemented below from
% scratch, following the ASTM E1049-85 (section 5.4.4) three-point
% counting method -- the same algorithm MATLAB's own Signal Processing
% Toolbox `rainflow` function and the widely-used Python `rainflow`
% package implement. This keeps the project runnable on a bare Student
% MATLAB install with no extra toolboxes.
%
% Force -> stress conversion: rather than a simplified F/Z nominal-beam
% estimate, this uses a stress-per-force factor calibrated directly from
% the converged ANSYS FEA result (see fea_scripts/ANSYS_MECHANICAL_WORKFLOW.md
% and results/mesh_convergence.csv): max von-Mises stress 998.4 MPa at the
% cross-checked peak mount force of 3900 N, i.e. ~2.56e5 Pa per N of mount
% force. Because the structure is linear-elastic (small deflections, no
% plasticity, single load case scaled up/down), this ratio is assumed to
% hold across the whole force-time history -- so the *actual* FEA stress
% concentration at the load hole is carried into the fatigue estimate,
% not just a textbook nominal-section number.
%
% Usage:
%   [t, F_mount] = quarter_car_ode();       % or load F_mount_simulink
%   [damage, blocks_to_failure, cycles] = rainflow_fatigue(t, F_mount);
%
%   % Optional: override the FEA-calibrated stress-per-force factor,
%   % e.g. if you re-run the FEA with a different peak load/geometry:
%   [damage, blocks_to_failure, cycles] = rainflow_fatigue(t, F_mount, my_stress_per_force);

function [damage, blocks_to_failure, cycles] = rainflow_fatigue(t, F_mount, stress_per_force)

    if nargin < 3 || isempty(stress_per_force)
        % Pa per N, calibrated from the converged FEA result:
        % 998.4 MPa / 3900 N (see header comment above).
        stress_per_force = 998.4e6 / 3900;
    end

    F_mount = F_mount(:)';   % row vector
    stress  = F_mount * stress_per_force;   % [Pa], scaled to the FEA hot-spot

    % --- 1. Reduce to turning points (reversals) ------------------------
    rev = get_reversals(stress);

    % --- 2. ASTM E1049-85 rainflow cycle counting -----------------------
    % cycles: [range_Pa, mean_Pa, count]  (count = 1.0 full cycle, 0.5 half cycle)
    cycles = rainflow_count(rev);

    % --- 3. Published S-N curve for a generic structural steel ---------
    % Illustrative only -- TODO: replace with a specific, cited material
    % S-N curve appropriate to the bracket material once chosen (e.g.
    % from a materials handbook or MMPDS), and note the source in report/.
    S_N_stress_MPa = [1000, 500, 300, 200, 150];   % stress amplitude
    S_N_cycles     = [1e3,  1e4, 1e5, 1e6, 1e7];   % cycles to failure

    % log-log interpolation, in ascending stress order for interp1
    logS = log10(fliplr(S_N_stress_MPa));   % [150 200 300 500 1000] -> log10
    logN = log10(fliplr(S_N_cycles));       % matching cycles-to-failure
    endurance_limit_MPa = min(S_N_stress_MPa);  % 150 MPa: treat as a fatigue limit

    % --- 4. Miner's rule: damage = sum(n_i / N_i) -----------------------
    damage = 0;
    n_cycles = size(cycles, 1);
    for i = 1:n_cycles
        amplitude_MPa = (cycles(i,1)/1e6) / 2;   % range -> amplitude
        count = cycles(i,3);

        if amplitude_MPa < endurance_limit_MPa
            continue;   % below the fatigue limit: assume no contribution
        end

        logN_i = interp1(logS, logN, log10(amplitude_MPa), 'linear', 'extrap');
        N_i = 10^logN_i;
        damage = damage + count / N_i;
    end

    if damage > 0
        blocks_to_failure = 1 / damage;
    else
        blocks_to_failure = Inf;
    end

    % --- 5. Report -------------------------------------------------------
    fprintf('Rainflow-counted cycles: %d (full + half cycles)\n', n_cycles);
    fprintf('Cumulative Miner''s-rule damage per pass of this load history: %.6g\n', damage);
    if isinf(blocks_to_failure)
        fprintf('All counted cycles fall below the assumed endurance limit (%.0f MPa amplitude)\n', endurance_limit_MPa);
        fprintf('-> effectively infinite life under this load history (per this illustrative S-N curve).\n');
    else
        fprintf('Estimated blocks-to-failure (repeats of this load history): %.1f\n', blocks_to_failure);
        if nargin >= 1 && ~isempty(t) && numel(t) > 1
            block_duration_s = t(end) - t(1);
            total_s = blocks_to_failure * block_duration_s;
            fprintf('If this %.2fs history repeats continuously, estimated time to Miner''s-rule failure: %.3g hours (%.3g days)\n', ...
                block_duration_s, total_s/3600, total_s/86400);
        end
    end
end


function rev = get_reversals(series)
    % Reduce a signal to its turning points (local peaks/valleys), plus
    % the first and last sample. ASTM E1049-85 reversals definition.
    n = numel(series);
    if n < 2
        rev = series;
        return;
    end
    x_last = series(1);
    x = series(2);
    d_last = x - x_last;
    rev = x_last;
    for k = 3:n
        x_next = series(k);
        if x_next == x
            continue;   % flat spot, no new information
        end
        d_next = x_next - x;
        if d_last * d_next < 0
            rev(end+1) = x; %#ok<AGROW>
        end
        x_last = x;
        x = x_next;
        d_last = d_next;
    end
    rev(end+1) = series(n);
end


function cycles = rainflow_count(rev)
    % ASTM E1049-85 section 5.4.4 three-point rainflow counting,
    % implemented with a simple stack. Returns Nx3: [range, mean, count].
    cycles = zeros(0, 3);
    stack = [];
    n = numel(rev);
    for idx = 1:n
        stack(end+1) = rev(idx); %#ok<AGROW>
        while numel(stack) >= 3
            x1 = stack(end-2);
            x2 = stack(end-1);
            x3 = stack(end);
            X = abs(x3 - x2);
            Y = abs(x2 - x1);
            if X < Y
                break;   % not enough closure yet, need another reversal
            elseif numel(stack) == 3
                % Y spans the very first point of the whole series --
                % count it as a half cycle and drop the front point.
                rng = abs(stack(2) - stack(1));
                mn  = 0.5 * (stack(2) + stack(1));
                cycles(end+1, :) = [rng, mn, 0.5]; %#ok<AGROW>
                stack(1) = [];
            else
                % Y is a closed interior cycle -- count it as a full cycle
                % and discard its two points, keeping the newest point.
                rng = abs(x2 - x1);
                mn  = 0.5 * (x2 + x1);
                cycles(end+1, :) = [rng, mn, 1.0]; %#ok<AGROW>
                last = stack(end);
                stack(end) = [];
                stack(end) = [];
                stack(end) = [];
                stack(end+1) = last;
            end
        end
    end
    % Drain whatever is left as half cycles (the "residual" of the load history).
    while numel(stack) > 1
        rng = abs(stack(2) - stack(1));
        mn  = 0.5 * (stack(2) + stack(1));
        cycles(end+1, :) = [rng, mn, 0.5];
        stack(1) = [];
    end
end
