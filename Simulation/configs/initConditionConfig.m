function init = initConditionConfig(control)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                CONFIGURATION FILE FOR INITIAL CONDITIONS                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% States configuration
init.scPosition = control.rr0;
init.scVelocity = control.vv0;
init.quaternion = [1 0 0 0];
% init.quaternion = eul2quat(deg2rad([5 3 5]));
% init.quaternion = eul2quat(deg2rad([50 30 25]));
init.scAngularVel = [0;0;4.0684e-4];
% init.scAngularVel = [0.17;-0.17;0.64]*1e-3;

% Asteroid's initial condition from Horizon ephemerides
% init.asteroidPosition = [9.480122260086653*1e10 -1.391513535153634*1e11 -4.012615919845328*1e9];
% init.asteroidVelocity = [2.820518130926961*1e4 1.050490431845516*1e4 -7.030392966153935*1e2];

init.asteroidPosition = [-7.196047536227861*1e10 1.237537497550310*1e11 1.334211277663944*1e10];
init.asteroidVelocity = [-3.022101184313919*1e4 -1.206882420071105*1e4 -1.151739648262923*1e3];

end