function [stochastic] = stochasticConfiguration()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%               CONFIGURATION FILE FOR STOCHASTIC ANALYSIS                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Simulation Settings
stochastic.simulationNumber                     = 500;
stochastic.executionMode                        ='accelerator';
stochastic.fastRestart                          ='on';

%% Uncertainty Parameters Selection - Initial State
stochastic.activeParameters.positionX           = true;
stochastic.activeParameters.positionY           = true;
stochastic.activeParameters.positionZ           = true;
stochastic.activeParameters.velocityX           = false;
stochastic.activeParameters.velocityY           = false;
stochastic.activeParameters.velocityZ           = false;
stochastic.activeParameters.roll                = true;
stochastic.activeParameters.pitch               = true;
stochastic.activeParameters.yaw                 = true;
stochastic.activeParameters.omegaX              = false;
stochastic.activeParameters.omegaY              = false;
stochastic.activeParameters.omegaZ              = false;

%% Uncertainty Parameters Selection - Actuators
stochastic.activeParameters.hrMaxTotal          = false;
stochastic.activeParameters.hrDotMaxTotal       = false;
stochastic.activeParameters.TmaxDesat           = false;

%% Uncertainty Parameters Creations - Actuators
stochastic.parameters.actuators = [];
stochastic.parameters.actuators = createParameter("hrMaxTotal", 6, 0, 5/3, stochastic.simulationNumber, stochastic.parameters.actuators);
stochastic.parameters.actuators = createParameter("hrDotMaxTotal", 6, 0, 0.1/3, stochastic.simulationNumber, stochastic.parameters.actuators);
stochastic.parameters.actuators = createParameter("TmaxDesat", 6, 0, 0.5/3, stochastic.simulationNumber, stochastic.parameters.actuators);

%% Uncertainty Parameters Creations - Initial conditions
stochastic.parameters.init = [];
stochastic.parameters.init = createParameter("positionX", 7, 0, 50, stochastic.simulationNumber, stochastic.parameters.init);
stochastic.parameters.init = createParameter("positionY", 7, 0, 50, stochastic.simulationNumber, stochastic.parameters.init);
stochastic.parameters.init = createParameter("positionZ", 7, 0, 50, stochastic.simulationNumber, stochastic.parameters.init);
stochastic.parameters.init = createParameter("velocityX", 7, 0, 0.5, stochastic.simulationNumber, stochastic.parameters.init);
stochastic.parameters.init = createParameter("velocityY", 7, 0, 0.5, stochastic.simulationNumber, stochastic.parameters.init);
stochastic.parameters.init = createParameter("velocityZ", 7, 0, 0.5, stochastic.simulationNumber, stochastic.parameters.init);
stochastic.parameters.init = createParameter("roll", 1, 0, 2*pi, stochastic.simulationNumber, stochastic.parameters.init);
stochastic.parameters.init = createParameter("pitch", 1, 0, 2*pi, stochastic.simulationNumber, stochastic.parameters.init);
stochastic.parameters.init = createParameter("yaw", 1, 0, 2*pi, stochastic.simulationNumber, stochastic.parameters.init);
stochastic.parameters.init = createParameter("omegaX", 7, 0, 1e-4/3, stochastic.simulationNumber, stochastic.parameters.init);
stochastic.parameters.init = createParameter("omegaY", 7, 0, 1e-4/3, stochastic.simulationNumber, stochastic.parameters.init);
stochastic.parameters.init = createParameter("omegaZ", 7, 0, 1e-4/3, stochastic.simulationNumber, stochastic.parameters.init);

%% Uncertainty Variables Compiling - Actuators
stochastic.variables = [];

len = length(stochastic.variables);
idx = 1;
for ii = len+1:len+length(stochastic.parameters.actuators)
    if stochastic.activeParameters.(stochastic.parameters.actuators(ii-len).name)
        stochastic.variables(idx+len).modFactor = stochastic.parameters.actuators(ii-len).modFactor;
        stochastic.variables(idx+len).distribution = stochastic.parameters.actuators(ii-len).distribution;
        stochastic.variables(idx+len).name = stochastic.parameters.actuators(ii-len).name;
        stochastic.variables(idx+len).type = "Actuators";
        idx = idx + 1;
    end
end

%% Uncertainty Variables Compiling - Initial conditions

len = length(stochastic.variables);
idx = 1;
for ii = len+1:len+length(stochastic.parameters.init)
    if stochastic.activeParameters.(stochastic.parameters.init(ii-len).name)
        stochastic.variables(idx+len).modFactor = stochastic.parameters.init(ii-len).modFactor;
        stochastic.variables(idx+len).distribution = stochastic.parameters.init(ii-len).distribution;
        stochastic.variables(idx+len).name = stochastic.parameters.init(ii-len).name;
        stochastic.variables(idx+len).type = "Init";
        idx = idx + 1;
    end
end

end
