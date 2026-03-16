function [actuators, parameters, modFactors] = updateDataActuators(actuators, parameters, modFactors)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%               FUNCTION FOR STOCHASTIC PARAMETER UPDATE                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    actuators     struct
    parameters  struct
    modFactors  double
end

index = [parameters(:).type] == "Actuators";
actuatorsParameters = parameters(index);
parameters = parameters(~index);
actuatorsModFactors = modFactors(index);
modFactors = modFactors(~index);
for i = 1:length(actuatorsParameters)
    actuatorsParameters(i).modFactor = actuatorsModFactors(i);
    switch actuatorsParameters(i).name
        case 'hrMaxTotal'
            actuatorsParameters(i).value = actuators.rw.hrMax_total;
            value = applyModFactor(actuatorsParameters(i), 1);
            actuators.rw.hrMax_total = value;
        case 'hrDotMaxTotal'
            actuatorsParameters(i).value = actuators.rw.hrDotMax_total;
            value = applyModFactor(actuatorsParameters(i), 1);
            actuators.hrDotMax_total = value;
        case 'TmaxDesat'
            actuatorsParameters(i).value = actuators.thDesat.Tmax;
            value = applyModFactor(actuatorsParameters(i), 1);
            actuators.thDesat.Tmax = value;
        otherwise
            error(strcat('Parameter: <', actuatorsParameters(i).name ,'> not known'));
    end
end


end