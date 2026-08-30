%% optimize_mass.m
%
% Constrained mass-minimization over bracket plate thickness, subject to
% a max-allowable-stress constraint, using calibrated physics-based
% surrogate models for mass and stress (not a fitted response surface --
% see the "How these models were built" note below).
%
% NOTE ON SCOPE: the earlier version of this script optimized 3
% parameters (thickness, rib height, fillet radius). The actual baseline
% CAD (cad/, Fusion 360) is a flat plate with corner fillets and 3 holes
% -- there is no rib feature, and no FEA data exists at any fillet radius
% other than the baseline 6mm. Rather than fabricate a model for
% parameters we have no data on, this version optimizes the one
% parameter we *do* have a validated relationship for: plate thickness.
%
% How these models were built (both calibrated to the SAME real data
% point -- your 1.2mm-mesh converged FEA run, see results/mesh_convergence.csv):
%
%   mass_fn:  the baseline geometry is a constant cross-section
%   (planform area fixed, only thickness varies), so mass is *exactly*
%   linear in thickness for this geometry: mass = k_mass * thickness.
%   k_mass = (baseline mass) / (baseline thickness) = 0.20801 kg / 10 mm.
%
%   stress_fn: net-section beam bending theory (see
%   postprocessing/analytical_beam_check.m) says stress scales as
%   1/thickness^2 for a fixed load and fixed in-plane geometry. The
%   *analytical* net-section prediction at 10mm (1046.9 MPa) was within
%   4.9% of the real FEA result (998.4 MPa) -- see the conversation
%   around analytical_beam_check.m -- so this scales the same 1/t^2
%   formula by that correction factor to match the real FEA point
%   exactly at t=10mm, while keeping the physically-correct 1/t^2 shape
%   for other thicknesses.
%
% ASSUMPTION YOU SHOULD CHECK: max_allowable_stress_MPa below assumes
% ANSYS's default "Structural Steel" (yield = 250 MPa) with a 1.5 safety
% factor against yield, applied to the peak dynamic mount load used as
% an equivalent static design load (standard practice -- consistent with
% how F_peak was derived and used throughout this project). If you
% assigned a different material in ANSYS Engineering Data, update the
% 250 (and the safety factor, if you want a different margin).

function optimize_mass()

    thickness0_mm = 10.0;   % baseline (cad/, Fusion 360)
    lb = 3.0;               % [mm] thinnest plausibly manufacturable/stiff plate
    ub = 30.0;              % [mm] wide enough that the constraint, not the
                             %      bound, determines the answer

    yield_MPa = 250;             % ANSYS default "Structural Steel" -- CHECK THIS
    safety_factor = 1.5;         % standard static safety factor against yield
    max_allowable_stress_MPa = yield_MPa / safety_factor;

    objective = @(t) mass_fn(t);
    nonlcon = @(t) deal(stress_fn(t) - max_allowable_stress_MPa, []); % c(t) <= 0

    options = optimoptions('fmincon', 'Display', 'iter', 'Algorithm', 'sqp');
    [t_opt, mass_opt] = fmincon(objective, thickness0_mm, [], [], [], [], lb, ub, nonlcon, options);

    mass_baseline = mass_fn(thickness0_mm);
    stress_baseline = stress_fn(thickness0_mm);
    stress_opt = stress_fn(t_opt);

    fprintf('\n--- Baseline (10mm) ---\n');
    fprintf('Stress: %.1f MPa   Mass: %.4f kg   Allowable: %.1f MPa\n', ...
        stress_baseline, mass_baseline, max_allowable_stress_MPa);

    fprintf('\n--- Optimized ---\n');
    fprintf('Thickness: %.2f mm   Stress: %.1f MPa   Mass: %.4f kg\n', ...
        t_opt, stress_opt, mass_opt);

    pct_change = 100 * (mass_opt - mass_baseline) / mass_baseline;
    if mass_opt < mass_baseline
        fprintf('-> %.1f%% MASS REDUCTION vs. baseline, still meeting the stress constraint.\n', -pct_change);
    else
        fprintf('-> Baseline THICKNESS IS INSUFFICIENT for a %.1fx safety factor against %.0f MPa yield:\n', safety_factor, yield_MPa);
        fprintf('   optimizer had to INCREASE thickness by %.1f%% (mass +%.1f%%) to reach a feasible design.\n', ...
            100*(t_opt/thickness0_mm - 1), pct_change);
    end
end

function m = mass_fn(t)
    % Calibrated to baseline: 0.20801 kg at 10mm, exactly linear because
    % only thickness changes (planform/hole geometry held fixed).
    k_mass = 0.20801 / 10.0;   % [kg/mm]
    m = k_mass * t;
end

function s = stress_fn(t)
    % Net-section beam bending (~1/t^2), calibrated to match the real
    % FEA result of 998.4 MPa at t=10mm (see header comment).
    k_stress = 99840.0;   % [MPa * mm^2], calibrated coefficient
    s = k_stress ./ (t.^2);
end
