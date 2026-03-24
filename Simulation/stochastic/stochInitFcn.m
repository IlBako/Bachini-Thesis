function simIn = stochInitFcn(simIn)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %            PRE PROCESSING STOCHASTIC SIMULATION FUNCTION               %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if isempty(simIn.Variables)
        return
    end

    modelWorkspace = get_param(simIn.ModelName, 'ModelWorkspace');

    baseActuators = getVariable(modelWorkspace, 'actuators');
    baseInit      = getVariable(modelWorkspace, 'init');

    v1 = simIn.Variables(1,1).Value;
    v2 = simIn.Variables(1,2).Value;

    [updatedActuators, v2, v1] = updateDataActuators(baseActuators, v2, v1);
    updatedInit = updateDataInit(baseInit, v2, v1);
    simIn = simIn.setVariable('actuators', updatedActuators, 'Workspace', simIn.ModelName);
    simIn = simIn.setVariable('init', updatedInit, 'Workspace', simIn.ModelName);

    simIn.Variables(1,1).Value = v1;
    simIn.Variables(1,2).Value = v2;
    
    clear updatedActuators updatedInit v1 v2;

end