function [init] = updateDataInit(init, parameters, modFactors)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%               FUNCTION FOR STOCHASTIC PARAMETER UPDATE                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    init                struct
    parameters          struct
    modFactors          double
end

euls = quat2eul(init.quaternion);

for i = 1:length(parameters)
    parameters(i).modFactor = modFactors(i);
    switch parameters(i).name
        case 'positionX'
            parameters(i).value = init.scPosition(1);
            value = applyModFactor(parameters(i), 1);
            init.scPosition(1) = value;
        case 'positionY'
            parameters(i).value = init.scPosition(2);
            value = applyModFactor(parameters(i), 1);
            init.scPosition(2) = value;
        case 'positionZ'
            parameters(i).value = init.scPosition(3);
            value = applyModFactor(parameters(i), 1);
            init.scPosition(3) = value;
        case 'velocityX'
            parameters(i).value = init.scVelocity(1);
            value = applyModFactor(parameters(i), 1);
            init.scVelocity(1) = value;
        case 'velocityY'
            parameters(i).value = init.scVelocity(2);
            value = applyModFactor(parameters(i), 1);
            init.scVelocity(2) = value;
        case 'velocityZ'
            parameters(i).value = init.scVelocity(3);
            value = applyModFactor(parameters(i), 1);
            init.scVelocity(3) = value;
        case 'roll'
            parameters(i).value = euls(1);
            value = applyModFactor(parameters(i),1);
            euls(1) = value;
        case 'pitch'
            parameters(i).value = euls(2);
            value = applyModFactor(parameters(i),1);
            euls(2) = value;
        case 'yaw'
            parameters(i).value = euls(3);
            value = applyModFactor(parameters(i),1);
            euls(3) = value;
        case 'omegaX'
            parameters(i).value = init.scAngularVel(1);
            value = applyModFactor(parameters(i), 1);
            init.scAngularVel(1) = value;
        case 'omegaY'
            parameters(i).value = init.scAngularVel(2);
            value = applyModFactor(parameters(i), 1);
            init.scAngularVel(2) = value;
        case 'omegaZ'
            parameters(i).value = init.scAngularVel(3);
            value = applyModFactor(parameters(i), 1);
            init.scAngularVel(3) = value;
        otherwise
            error(strcat('Parameter: <', parameters(i).name ,'> not known'));
    end
end

init.quaternion = eul2quat(euls);

end