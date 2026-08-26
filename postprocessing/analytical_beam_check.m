%% analytical_beam_check.m
%
% Independent analytical estimate of peak stress at the bracket's
% critical section, using classical beam bending theory, as a
% benchmark against the ANSYS FEA result (see fea_scripts/). This is
% the "standards-based verification" step that needs no lab and no
% licensed standard document -- only a hand calculation.
%
% TODO: replace the placeholder geometry/load with the actual baseline
% bracket dimensions and the peak load from quarter_car_ode.m /
% build_quarter_car_simulink.m.

function sigma_max = analytical_beam_check(F_peak, L, b, h)
    % F_peak : peak transverse load at the critical section [N]
    % L      : distance from load application to the critical section [m]
    % b, h   : critical section width and height [m]

    if nargin == 0
        F_peak = 2500;  % [N], placeholder -- replace with FEA/dynamics result
        L = 0.08;       % [m]
        b = 0.03;       % [m]
        h = 0.01;       % [m]
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
