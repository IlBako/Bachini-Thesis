function model = stochasticInitializer(stochastic, environment, actuators, control, spacecraft, init, simulation)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       CONFIGURATION FILE FOR STOCHASTIC SIMULATION INITIALIZATION       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Parpool Creation
if isempty(gcp('nocreate')) % Parpool Creation
    parpool;
end

%% Model Loading
load_system(simulation.modelName);
set_param(simulation.modelName, ...
    'StopTime', simulation.simulationTime, ...
    'FixedStep', simulation.simulationTimeStep, ...
    'SolverType', simulation.solverType, ...
    'Solver', simulation.solver);

%% Output Configuration
simulation.toWorkspace = ["External Environment/Spacecraft State"; ...
                          "External Environment/Asteroid State"; ...
                          "External Environment/Accelerations"; ...
                          "Actuators Bus"; ...
                          "Distance And Shadow/Illuminated State"; ...
                          "Attitude Control/q target"; ...
                          "Attitude Control/w target"; ...
                          "Attitude Control/control Tau"; ...
                          "Distance And Shadow/Illuminated State"; ...
                          "Distance And Shadow/Illuminated State";];

if simulation.variants.control == "ORBIT_KEEPING"
    simulation.toWorkspace = [simulation.toWorkspace; ...
                              "Control Unit/Orbit Keeping Control/control Acceleration"];
end

%% Define gravity matrices
gravAtt = Simulink.Parameter(environment.gravStruct.gravAtt);
gravAtt.CoderInfo.StorageClass = 'Auto';
gravAtt.CoderInfo.CustomStorageClass = "Default";
gravLaplace = Simulink.Parameter(environment.gravStruct.gravLaplace);
gravLaplace.CoderInfo.StorageClass = 'Auto';
gravLaplace.CoderInfo.CustomStorageClass = "Default";

%% Parameter Assignment and Common Data Saving
model = Simulink.SimulationInput(simulation.modelName);
save('configData.mat', 'environment', 'actuators', 'control', 'spacecraft', 'init', 'simulation', 'gravAtt', 'gravLaplace');

%% Stochastic Parameters Assignment
model = model.setModelParameter('FastRestart', stochastic.fastRestart);
model = model.setModelParameter("SimulationMode",stochastic.executionMode);
% model = model.setPostSimFcn(@(simulationOutput) stochOutFcn(simulationOutput));
model = model.setPreSimFcn(@(simIn) stochInitFcn(simIn));
model = repmat(model,stochastic.simulationNumber,1);

%% Stochastic Variables Assignment
stochVariables = stochastic.variables;
if ~isempty(stochVariables)
    hWait = waitbar(0, 'Configuring simulation inputs...', 'Name', 'Stochastic Initialization');
    parfor_progress = parallel.pool.DataQueue;
    afterEach(parfor_progress, @(~) updateWaitbar(hWait, stochastic.simulationNumber));
    stochFactors = [stochVariables.modFactor];
    stochVariables = rmfield(stochVariables, 'modFactor');
    parfor i = 1:stochastic.simulationNumber   
        model(i) = model(i).setVariable('stochasticFactors', stochFactors(i, :));
        model(i) = model(i).setVariable('stochasticVariables', stochVariables);
        send(parfor_progress, i);
    end
    close(hWait);
    clear updateWaitbar; 
end


end