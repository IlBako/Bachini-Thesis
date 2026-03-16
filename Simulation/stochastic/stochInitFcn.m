function simIn = stochInitFcn(simIn)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %            PRE PROCESSING STOCHASTIC SIMULATION FUNCTION               %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if isempty(simIn.Variables)
        return
    end

    data = load('configData.mat', 'environment', 'actuators', 'control', 'spacecraft', 'init');
    [actuators, simIn.Variables(1,2).Value, simIn.Variables(1,1).Value] = updateDataActuators(data.actuators, simIn.Variables(1, 2).Value, simIn.Variables(1, 1).Value);
    init = updateDataInit(data.init, simIn.Variables(1, 2).Value, simIn.Variables(1, 1).Value);
    simIn = simIn.setVariable('actuators', actuators);
    simIn = simIn.setVariable('init', init);

end