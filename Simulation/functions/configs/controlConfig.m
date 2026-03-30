function [control, spacecraft] = controlConfig(asteroidMu)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                CONFIGURATION FILE FOR CONTROL PARAMETERS                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Spacecraft configs

spacecraft.scMass = 600;

% Principal moments of Intertia [Kg*m^2]
I = [206.13261565 178.01640914 128.13379354];
% Principal inertia matrix [Kg*m^2]
spacecraft.I_mat = diag(I);
% Inverse of intertia matrix
spacecraft.I_inv = inv(spacecraft.I_mat);

% Normal of S/C panel
spacecraft.normalsMat = [0  0  1;
                         0  0 -1;
                         1  0  0;
                        -1  0  0;
                         0  1  0;
                         0 -1  0
                         0  0  1;
                         0  0  1;
                         0  0 -1;
                         0  0 -1];

% Area of S/C panels
spacecraft.areaMat = [1*1.6*ones(2,1);
                      1*1.25*ones(2,1);
                      1.6*1.25*ones(2,1);
                      6*2.115*ones(4,1)];

% Specular reflection coefficient of S/C  panels
spacecraft.cSpec = [0.6*ones(6,1);
                    0.1*ones(4,1)];

% Diffraction coefficient of S/C panels
spacecraft.cDiff = [0.1*ones(6,1);
                    0.1*ones(2,1);
                    0.3*ones(2,1)];

% Asteroid CoM to panels vector
spacecraft.rPMat = [0     0   0.625;
                    0     0  -0.625;
                    0    -0.8 0;
                    0     0.8 0;
                    0.5   0   0;
                   -0.5   0   0;
                   -1.757 0   0;
                   -1.757 0   0;
                    1.757 0   0;
                    1.757 0   0];


%% Orbit keeping algorithm

control.frequency = 1;  % [Hz] frequency of command block

% X-Y orbit (a = 120km, e = 0, i = 0, OM = 0, om = 0, theta = 0)

% Y-Z orbit (a = 40km, e = 0, i = 90, OM = 90, om = 0, theta = 0)

% Test orbit from "3D plausible orbital stability close to asteroid (216)
% Kleopatra" (a = 312.5km, e = 0.2, i = 180, OM = 0, om = 0, theta = 0) 
% For test orbit: vS0 = [-6.05798274507417 -91.6645500432013 0.0329814808174932]

% 2nd test orbit from "3D plausible orbital stability close to asteroid (216)
% Kleopatra" (a = 200km, e = 0.3, i = 180, OM = 0, om = 0, theta = 0) 
% For test orbit: vS0 = [0 -101.014522388756 0]

% BENNU: (a = 350 m, e = 0, i = 45°, OM = 45°, om = 0°, theta = 0°)
% ITOKAWA: (a = 350 m, e = 0.1, i = 90°, OM = 90°, om = 90°, theta = 0°)

% Target keplerian elements
a_target = 350;
e_target = 0;
i_target = deg2rad(45);
OM_target = deg2rad(45);
om_target = deg2rad(0);
theta_start = 0;

control.kep_target = [a_target, e_target, i_target, OM_target, om_target];

% Target orbit parameters (angular momentum and eccentricity)
control.h_target = sqrt(asteroidMu*a_target*(1-e_target^2))*...
                    [sin(i_target)*sin(OM_target); -sin(i_target)*cos(OM_target); cos(i_target)];
control.ecc_target = e_target*[cos(OM_target)*cos(om_target) - sin(OM_target)*sin(om_target)*cos(i_target);
                                     sin(OM_target)*cos(om_target) + cos(OM_target)*sin(om_target)*cos(i_target);
                                     sin(om_target)*sin(i_target)];

% Initial condition from keplerian orbit

[control.rr0, control.vv0] = kep2car(a_target, e_target, i_target, OM_target, om_target, theta_start, asteroidMu);

% BENNU: lambda = [2, 2], K = 1e-2*eye(3), phi = 5
% ITOKAWA: lambda = [2, 2], K = diag([1e-2, 1.1, 1e-2]), phi = 5
% KLEOPATRA: lambda = [2, 2], K = diag([1e-2, 5.57*1e3, 1e-2]), phi = 20

% Control paramters of the SMC
control.lambdaR = 2;
control.lambdaN = 2;
control.K = 1e-2*eye(3);
control.phi = 5*diag(control.K);
control.sPlus = 0;
control.sMinus = -realmax;

%% Attitude control

% control.kq = 0.267; % Nm
% control.kw = 17;   % Nms
% control.phiQuat = 0.3;

% Starting value of kw: max(diag(spacecraft.I_mat))/min(diag(spacecraft.I_mat))*ones(1,3)

control.kw = 7.5*max(diag(spacecraft.I_mat))/min(diag(spacecraft.I_mat))*ones(1,3);
control.katt = 2.5e-3*diag(spacecraft.I_mat) .* [1 1 1]';

end