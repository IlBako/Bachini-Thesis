function actuators = actuatorsConfig()

%% Reaction wheel - Honeywell HR16-75 in Pyramid configuration

% (4-wheel pyramid, a = 1/sqrt(3))
a = 1/sqrt(3);
A = [-a a a -a; -a -a a a; a a a a];
A_inv = pinv(A);

% SINGLE WHEEL PARAMETERS

maxOmega_single = 6000*2*pi/60;                     % [rad/s] Maximum rotational velocity
actuators.rw.hrMax_single = 75;                     % [Nms] Maximum momentum
Ir = actuators.rw.hrMax_single/maxOmega_single;     % [Kg m^2] % Inertia of the wheel
actuators.rw.hrDotMax_single = 0.4;                 % [Nm] Maximum reaction torque

% CONFIGURATION PARAMTERS (4 wheels together)
actuators.rw.hrMax_total = actuators.rw.hrMax_single;           % [Nms] Maximum torque is limited by single wheel one
actuators.rw.hrThreshold = 0.75*actuators.rw.hrMax_single;      % [Nms] Threshold before desaturation
actuators.rw.hrDotMax_total = 4*a*actuators.rw.hrDotMax_single; % [Nm] Maximum total torque per each axis = 4/sqrt(3)*0.4

%% Attitude thrusters for desaturation (Busek BGT-X5)

actuators.thDesat.rp = ...
[0.5  0.8  0.625;
-0.5  0.8  0.625;
 0.5  0.8 -0.625;
-0.5  0.8 -0.625;
 0.5 -0.8  0.625;
-0.5 -0.8  0.625;
 0.5 -0.8 -0.625;
-0.5 -0.8 -0.625];

% Thrusters outward direction
actuators.thDesat.thrustDir = 1/sqrt(2) * ...
[1  1  0;
-1  1  0;
 1  1  0;
-1  1  0;
 1 -1  0;
-1 -1  0;
 1 -1  0;
-1 -1  0];

% B matrix
B_tau = zeros(3,8);
for i = 1:8
    B_tau(:,i) = cross(actuators.thDesat.rp(i,:)', actuators.thDesat.thrustDir(i,:)');
end
actuators.thDesat.B = B_tau;
actuators.thDesat.B_inv = pinv(B_tau);

actuators.thDesat.Tmax = 0.5;       % [N] Maximum thrust
actuators.thDesat.kDesat = 1.5e-4;  % [1/s] Desaturation rate gain

end