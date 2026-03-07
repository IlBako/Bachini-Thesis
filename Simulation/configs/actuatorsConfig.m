function actuators = actuatorsConfig()

%% Reaction wheel

a = 1/sqrt(3);
actuators.rw.A = [-a a a -a; -a -a a a; a a a a];

% Maximum rotational velocity
max_omega = 3600*2*pi/60; % [rad/s] 
% Maximum hr for pointing
actuator_data.hr_max_point = 12;
% [N*m*s] Nominal rotation speed for no control
actuator_data.hr_nom = actuator_data.hr_max_point/3;
% Inertia of the wheel
Ir = actuator_data.hr_max_point/max_omega;
% Maximum hr for slew
actuator_data.hr_max_slew = 12/6;
% Maximum hr_dot
actuator_data.hr_dot_max = 0.2;
% [rad/s] nominal rotation speed
actuator_data.wr_nom = actuator_data.hr_nom/Ir;



end