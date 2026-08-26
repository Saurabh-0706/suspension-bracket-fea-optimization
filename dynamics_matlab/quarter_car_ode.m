%% quarter_car_ode.m
%
% Independent MATLAB ODE solution of the same 2-DOF quarter-car system
% built in Simulink (build_quarter_car_simulink.m). Solving the same
% physics two different ways and comparing results is the cross-check
% step referenced in the README -- if this script and the Simulink model
% disagree, that's a sign of a modeling error before any FEA is trusted.
%
% Usage:
%   [t, F_mount, peak_force] = quarter_car_ode();

function [t, F_mount, peak_force] = quarter_car_ode()

    % Same placeholder parameters as build_quarter_car_simulink.m --
    % TODO: keep these in sync, or refactor into a shared params file.
    p.m_s = 350;   p.m_u = 45;
    p.k_s = 35000; p.c_s = 2500;
    p.k_t = 250000;

    tspan = linspace(0, 2, 2000);
    x0 = zeros(4,1); % [x_s, x_u, xdot_s, xdot_u]

    road = @(t) 0.05 * sin(2*pi*3*t) .* (t < 1); % simple bump, TODO: replace
                                                   % with an ISO 8608 profile
                                                   % or measured input

    [t, x] = ode45(@(t,x) qc_deriv(t, x, p, road), tspan, x0);

    x_s = x(:,1); x_u = x(:,2);
    xdot_s = x(:,3); xdot_u = x(:,4);

    F_mount = p.k_s*(x_s - x_u) + p.c_s*(xdot_s - xdot_u);
    peak_force = max(abs(F_mount));

    fprintf('Peak suspension mount force (ODE model): %.1f N\n', peak_force);
    fprintf('Compare this against qc_states from the Simulink model --\n');
    fprintf('agreement within a few %% validates both models.\n');

    figure;
    plot(t, F_mount);
    xlabel('Time [s]'); ylabel('Mount force [N]');
    title('Quarter-car suspension mount force (MATLAB ODE cross-check)');
    grid on;
end

function dxdt = qc_deriv(t, x, p, road)
    x_s = x(1); x_u = x(2); xdot_s = x(3); xdot_u = x(4);
    x_r = road(t);

    xddot_s = (-p.k_s*(x_s-x_u) - p.c_s*(xdot_s-xdot_u)) / p.m_s;
    xddot_u = ( p.k_s*(x_s-x_u) + p.c_s*(xdot_s-xdot_u) - p.k_t*(x_u-x_r)) / p.m_u;

    dxdt = [xdot_s; xdot_u; xddot_s; xddot_u];
end
