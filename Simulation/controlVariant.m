classdef controlVariant < Simulink.IntEnumType
    enumeration
        ORBIT_KEEPING (1)
        DISTANCE_KEEPING (2)
        WAYPOINT (3)
        NO_CONTROL (4)
    end
end