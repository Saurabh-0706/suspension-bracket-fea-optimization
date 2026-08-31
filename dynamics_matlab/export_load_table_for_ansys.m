%% export_load_table_for_ansys.m
%
% Downsamples the quarter-car mount-force time history (quarter_car_ode.m)
% to a small table suitable for pasting into ANSYS Mechanical's Tabular
% Data grid for a Transient Structural time-varying Force load -- feeding
% the FEA the actual dynamic load history instead of just its peak.
%
% Why downsample at all: the ODE output has 2000 time points. ANSYS
% Tabular Data technically supports far more than that, but a Transient
% Structural solve does one full structural solve PER time point in the
% table, so 2000 points would mean 2000 solves -- far too slow on a
% laptop/Student license. ~50 points is enough to capture the shape of
% the bump event and its ring-down while keeping solve time reasonable.
%
% The one point that MUST NOT be lost to downsampling is the true peak --
% it's the most structurally important moment in the whole history -- so
% this explicitly checks for it and inserts it if plain even-spacing
% would have skipped over it.
%
% Usage:
%   [t, F_mount] = quarter_car_ode();
%   export_load_table_for_ansys(t, F_mount);
%
%   % optional: choose a different point count or output path
%   export_load_table_for_ansys(t, F_mount, 60, '../results/my_load_table.csv');

function export_load_table_for_ansys(t, F_mount, n_points, out_csv)

    if nargin < 3 || isempty(n_points)
        n_points = 50;
    end
    if nargin < 4 || isempty(out_csv)
        out_csv = '../results/ansys_load_table.csv';
    end

    t = t(:);
    F_mount = F_mount(:);
    n = numel(t);

    % Evenly-spaced sample indices across the whole history (always
    % includes the very first and very last point).
    idx = round(linspace(1, n, n_points));
    idx = unique(idx);

    % Guarantee the true peak sample is included even if uniform
    % decimation would otherwise step over it.
    [~, peak_idx] = max(abs(F_mount));
    if ~any(idx == peak_idx)
        idx = sort([idx, peak_idx]);
    end

    t_sample = t(idx);
    F_sample = F_mount(idx);

    T = table(t_sample, F_sample, 'VariableNames', {'Time_s', 'Force_N'});
    writetable(T, out_csv);

    fprintf('Wrote %d-point downsampled load table to %s\n', numel(idx), out_csv);
    fprintf('Sampled peak force: %.1f N (original peak: %.1f N -- should match exactly)\n', ...
        max(abs(F_sample)), max(abs(F_mount)));

    fprintf('\n--- Copy these two columns directly into ANSYS Mechanical''s Tabular Data grid ---\n');
    fprintf('(click the first empty Time cell in the grid, then paste)\n\n');
    fprintf('Time [s]\tForce [N]\n');
    for i = 1:numel(idx)
        fprintf('%.6f\t%.4f\n', t_sample(i), F_sample(i));
    end
end
