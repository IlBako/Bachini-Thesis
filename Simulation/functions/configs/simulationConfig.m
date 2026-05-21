function simulation = simulationConfig(control)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%               CONFIGURATION FILE FOR SIMULATION SETTINGS                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Simulation parameters
simulation.startPosThreshold = 25;
simulation.nOrbits = 1;

%% Simulation execution setup
simulation.modelName                       = 'ARIES';
% simulation.simulationTime                  = '1.728e5';               % [s] 
% simulation.simulationTime                  = '64800';               % [s] 
% simulation.simulationTime                  = '8*2*pi*sqrt(40e3^3/309687520)';               % [s] 
simulation.simulationTime                  = strcat(num2str(simulation.nOrbits), '*2*pi*sqrt(350^3/4.8916)');               % [s] 
simulation.simulationTimeStep              = '1e-1';              % [s] simulation integration timestep (fixed step solvers)
simulation.solver                          = 'ode4';              % solver algorithm: 'ode4', 'ode45', 'ode15s', etc.
simulation.solverType                      = 'fixed-step';        % 'fixed-step' or 'variable-step'
simulation.executionMode                   = 'rapid-accelerator';       % 'normal', 'accelerator' or 'rapid-accelerator'
simulation.fastRestart                     = 'off';               % 'on' or 'off'
simulation.debugMode                       = 'off';               % 'on', 'off'

%% Model variants setup
simulation.variants.control                = control.orbitKeepingAlg;
simulation.variants.attTarget              = attitudeTargetVariant.INERTIAL;
simulation.variants.attActuator            = attActuatorVariant.REACTION_WHEELS_PYRAMID;

end