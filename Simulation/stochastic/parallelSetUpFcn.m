function parallelSetUpFcn()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             COMMON VARIABLES WORKERS ASSIGNMENT FUNCTION                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    load('configData.mat', 'environment', 'actuators', 'control', 'spacecraft', 'init', 'simulation', 'gravAtt', 'gravLaplace');
    assignin('base', 'environment', environment);
    assignin('base', 'actuators',   actuators);
    assignin('base', 'control',     control);
    assignin('base', 'spacecraft',  spacecraft);
    assignin('base', 'init',        init);
    assignin('base', 'simulation',  simulation);
    assignin('base', 'gravAtt',     gravAtt);
    assignin('base', 'gravLaplace', gravLaplace);
    
    load_system(simulation.modelName);
    set_param(simulation.modelName, 'FastRestart', 'off');
    for ii = 1:length(simulation.toWorkspace)
        set_param(simulation.modelName + "/" + simulation.toWorkspace(ii), 'Commented', 'off');
    end

    %% Fast Restart Setup
    set_param(simulation.modelName, 'FastRestart', 'on');

    %% Load BVH tree
    createBVHObjects(simulation.modelName, environment.asteroidData.BVH);

    %% Suppress Warnings
    warning('off');
end