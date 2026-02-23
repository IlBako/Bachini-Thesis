

% Tests
% configs.sim.rS0 = [0 120e3 0];
% configs.sim.rS0 = [120e3 0 0];
% configs.sim.vS0 = [0 -100 0];
% configs.sim.rS0 = [112.2124e3 0 0];
% configs.sim.vS0 = [1.0784 -99 -100];

% X-Y orbit (a = 120km, e = 0, i = 0, OM = 0, om = 0, theta = 0)
% Y-Z orbit (a = 40km, e = 0, i = 90, OM = 90, om = 0, theta = 0)
a_target = 40e3;
e_target = 0;
i_target = deg2rad(90);
OM_target = deg2rad(90);
om_target = 0;
configs.control.mu = 6.67430*1e-11*asteroidData.mass;
configs.control.kep_target = [a_target, e_target, i_target, OM_target, om_target];
configs.control.h_target = sqrt(configs.control.mu*120e3*(1-0^2))*...
                            [sin(i_target)*sin(OM_target); -sin(i_target)*cos(OM_target); cos(i_target)];
configs.control.ecc_target = e_target*[cos(OM_target)*cos(om_target) - sin(OM_target)*sin(om_target)*cos(i_target);
                                     sin(OM_target)*cos(om_target) + cos(OM_target)*sin(om_target)*cos(i_target);
                                     sin(om_target)*sin(i_target)];
configs.control.lambdaR = 2;
configs.control.lambdaN = 2;
configs.control.K = 1e-2*eye(3);
configs.control.phi = 5*diag(configs.control.K);
[rr0, vv0] = kep2car(a_target, e_target, i_target, OM_target, om_target, 0, configs.control.mu);
configs.sim.rS0 = rr0;
configs.sim.vS0 = vv0;

clear a_target e_target i_target OM_target om_target

configs.sim.q0 = [1 0 0 0];
configs.sim.w0 = [0 0 0];
configs.sim.rB0 = [9.317464358520074*1e10 3.097354857658076*1e11 -4.604296964939199*1e10];
configs.sim.vB0 = [-2.008619498700183*1e4 8.505798212350415*1e3 -4.348614882994651*1e3];
configs.grav.laplaceTol = 1e-6;
configs.sim.Tf = 2e5;
% configs.sim.Tf = 1.5e8;


configs.env.mu_sun = 1.32712440017987E+20;

configs.asteroid.wb = [0;0;3.3118e-4];

configs.sc.m_sc = 600;

% Principal moments of Intertia [Kg*m^2]
I = [206.13261565 178.01640914 128.13379354];
% Principal inertia matrix [Kg*m^2]
configs.sc.I_mat = diag(I);
% Inverse of intertia matrix
configs.sc.I_inv = inv(configs.sc.I_mat);

% Normal of S/C panel
configs.sc.n_mat = [0  0  1;
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
configs.sc.A_mat = [1*1.6*ones(2,1);
                    1*1.25*ones(2,1);
                    1.6*1.25*ones(2,1);
                    6*2.115*ones(4,1)];

% Specular reflection coefficient of S/C  panels
configs.sc.c_spec = [0.6*ones(6,1);
                     0.1*ones(4,1)];

% Diffraction coefficient of S/C panels
configs.sc.c_diff = [0.1*ones(6,1);
                     0.1*ones(2,1);
                     0.3*ones(2,1)];

% Asteroid CoM to panels vector
configs.sc.r_p_mat = [0     0   0.625;
                      0     0  -0.625;
                      0    -0.8 0;
                      0     0.8 0;
                      0.5   0   0;
                     -0.5   0   0;
                     -1.757 0   0;
                     -1.757 0   0;
                      1.757 0   0;
                      1.757 0   0];

%% Sphere configs
% configs.sim.x0 = [0 8117.9 0]*1e3;
% configs.sim.v0 = [-7.4533 0 0]*1e3;
% configs.sim.A0 = eye(3);
% configs.sim.w0 = 0;
% configs.sim.Tf = 1e5;