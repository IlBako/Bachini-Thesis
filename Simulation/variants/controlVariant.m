classdef controlVariant < Simulink.IntEnumType
    enumeration
        ORBIT_KEEPING (1)
        DISTANCE_KEEPING (2)
        WAYPOINT (3)
        NO_CONTROL (4)
    end
    methods (Static)
        function retVal = getHeaderFile()
            retVal = 'control_types.h'; % This ensures the C-code knows the values
        end
        function retVal = getDefaultValue()
            retVal = controlVariant.NO_CONTROL;
        end
    end
end