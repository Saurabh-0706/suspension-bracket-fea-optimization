%% build_quarter_car_simulink.m
%
% Programmatically builds a quarter-car Simulink model (2-DOF: sprung mass
% + unsprung mass, connected by a suspension spring/damper, with the wheel
% connected to the road profile through the tire stiffness).
%
% Running this script in MATLAB generates and opens an .slx model. Keeping
% the model construction as a script (rather than a hand-built .slx binary)
% means the model itself is version-controlled and reproducible from source.
%
% Outputs of the model:
%   - x_s, x_u   : sprung/unsprung mass displacement
%   - F_mount    : force transmitted through the suspension mount
%                  (this is the load history fed into fea_scripts/)
%
% TODO: tune mass/stiffness/damping parameters to a representative
%       off-highway vehicle corner before using results downstream.

modelName = 'quarter_car_model';
close_system(modelName, 0); %#ok<*NASGU> % close if already open, ignore errors
new_system(modelName);
open_system(modelName);

%% Parameters (placeholder values -- replace with justified assumptions)
params.m_s  = 350;      % sprung mass per corner [kg]
params.m_u  = 45;       % unsprung mass [kg]
params.k_s  = 35000;    % suspension spring stiffness [N/m]
params.c_s  = 2500;     % suspension damping [N.s/m]
params.k_t  = 250000;   % tire stiffness [N/m]
assignin('base', 'qc_params', params);

%% Blocks: state-space realization of the 2-DOF quarter car
% States: [x_s; x_u; xdot_s; xdot_u], input: road displacement x_r
A = [ 0, 0, 1, 0;
      0, 0, 0, 1;
     -params.k_s/params.m_s,  params.k_s/params.m_s, -params.c_s/params.m_s,  params.c_s/params.m_s;
      params.k_s/params.m_u, -(params.k_s+params.k_t)/params.m_u,  params.c_s/params.m_u, -params.c_s/params.m_u ];
B = [0; 0; 0; params.k_t/params.m_u];
C = eye(4);
D = zeros(4,1);

add_block('simulink/Sources/Sine Wave', [modelName '/RoadBumpInput'], ...
    'Amplitude', '0.05', 'Frequency', '3', 'Position', [30 30 90 60]);
add_block('simulink/Continuous/State-Space', [modelName '/QuarterCarStateSpace'], ...
    'A', mat2str(A), 'B', mat2str(B), 'C', mat2str(C), 'D', mat2str(D), ...
    'Position', [150 20 320 100]);
add_block('simulink/Sinks/To Workspace', [modelName '/StatesOut'], ...
    'VariableName', 'qc_states', 'Position', [380 30 460 60]);

add_line(modelName, 'RoadBumpInput/1', 'QuarterCarStateSpace/1');
add_line(modelName, 'QuarterCarStateSpace/1', 'StatesOut/1');

% Derived signal: mount force F = k_s*(x_s - x_u) + c_s*(xdot_s - xdot_u)
add_block('simulink/Math Operations/Gain', [modelName '/ToMountForce'], ...
    'Gain', '1', 'Position', [380 100 460 130]); % placeholder -- replace with
    % a proper linear combination block (e.g. Matrix Gain with
    % [k_s -k_s c_s -c_s]) applied to the state vector once the model is
    % opened in MATLAB; left as a TODO so the exact block wiring is done
    % and visually verified inside Simulink rather than guessed here.

save_system(modelName, fullfile(pwd, [modelName '.slx']));
fprintf('Quarter-car Simulink model saved to %s.slx\n', modelName);
fprintf('TODO: wire ToMountForce as [k_s -k_s c_s -c_s] * state vector,\n');
fprintf('      replace RoadBumpInput with an ISO 8608 road profile block\n');
fprintf('      or a From Workspace bump signal for a more realistic input.\n');
