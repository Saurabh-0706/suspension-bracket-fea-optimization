%% analytical_beam_check.m
%
% Independent analytical estimate of peak stress at the bracket's
% critical section, using classical beam bending theory, as a
% benchmark against the ANSYS FEA result (see fea_scripts/). This is
% the "standards-based verification" step that needs no lab and no
% licensed standard document -- only a hand calculation.
%
% Defaults below now match the actual baseline bracket (cad/, Fusion 360)
% and the cross-checked quarter-car peak load (dynamics_matlab/):
% Simulink gave 3898.0 N, the ODE script gave 3953.5 N (1.4% apart) --
% F_peak here uses their average, ~3926 N. Update if you refine either.

function sigma_max = analytical_beam_check(F_peak, L, b, h)
    % F_peak : peak transverse load at the critical section [N]
    % L      : distance from load application to the critical section [m]
    % b, h   : critical section width and height [m]

    if nargin == 0
        F_peak = 3926;  % [N] -- average of the Simulink/ODE cross-checked peaks
        L = 0.08;       % [m] -- chassis edge to Ø12mm load-hole center (0.08 m nominal; hole is at x=80mm)
        b = 0.03;       % [m] -- plate width
        h = 0.01;       % [m] -- plate thickness
    end

    M = F_peak * L;              % bending moment at the section [N.m]
    I = (b * h^3) / 12;          % second moment of area [m^4]
    c = h / 2;                   % distance to extreme fiber [m]

    sigma_max = M * c / I;       % [Pa]

    fprintf('Analytical peak bending stress: %.2f MPa\n', sigma_max/1e6);
    fprintf('Compare against the ANSYS FEA max stress at the same section.\n');
    fprintf('Agreement within ~10-15%% is a reasonable target for a\n');
    fprintf('simplified beam-theory cross-check of a 3D FEA result.\n');
end
