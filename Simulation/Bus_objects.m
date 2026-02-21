function Bus_objects() 
% BUS_OBJECTS initializes a set of bus objects in the MATLAB base workspace 

% Bus object: SCState 
clear elems;
elems(1) = Simulink.BusElement;
elems(1).Name = 'position';
elems(1).Dimensions = 3;
elems(1).DimensionsMode = 'Fixed';
elems(1).DataType = 'double';
elems(1).Complexity = 'real';
elems(1).Min = [];
elems(1).Max = [];
elems(1).DocUnits = '';
elems(1).Description = '';

elems(2) = Simulink.BusElement;
elems(2).Name = 'velocity';
elems(2).Dimensions = 3;
elems(2).DimensionsMode = 'Fixed';
elems(2).DataType = 'double';
elems(2).Complexity = 'real';
elems(2).Min = [];
elems(2).Max = [];
elems(2).DocUnits = '';
elems(2).Description = '';

elems(3) = Simulink.BusElement;
elems(3).Name = 'q_SB';
elems(3).Dimensions = 4;
elems(3).DimensionsMode = 'Fixed';
elems(3).DataType = 'double';
elems(3).Complexity = 'real';
elems(3).Min = [];
elems(3).Max = [];
elems(3).DocUnits = '';
elems(3).Description = '';

elems(4) = Simulink.BusElement;
elems(4).Name = 'ang_velocity';
elems(4).Dimensions = 3;
elems(4).DimensionsMode = 'Fixed';
elems(4).DataType = 'double';
elems(4).Complexity = 'real';
elems(4).Min = [];
elems(4).Max = [];
elems(4).DocUnits = '';
elems(4).Description = '';

SCState = Simulink.Bus;
SCState.HeaderFile = '';
SCState.Description = '';
SCState.DataScope = 'Auto';
SCState.Alignment = -1;
SCState.PreserveElementDimensions = 0;
SCState.Elements = elems;
clear elems;
assignin('base','SCState', SCState);

% Bus object: Accelerations 
clear elems;
elems(1) = Simulink.BusElement;
elems(1).Name = 'SC_lin';
elems(1).Dimensions = 3;
elems(1).DimensionsMode = 'Fixed';
elems(1).DataType = 'double';
elems(1).Complexity = 'real';
elems(1).Min = [];
elems(1).Max = [];
elems(1).DocUnits = '';
elems(1).Description = '';

elems(2) = Simulink.BusElement;
elems(2).Name = 'SC_ang';
elems(2).Dimensions = 3;
elems(2).DimensionsMode = 'Fixed';
elems(2).DataType = 'double';
elems(2).Complexity = 'real';
elems(2).Min = [];
elems(2).Max = [];
elems(2).DocUnits = '';
elems(2).Description = '';

elems(3) = Simulink.BusElement;
elems(3).Name = 'asteroid_lin';
elems(3).Dimensions = 3;
elems(3).DimensionsMode = 'Fixed';
elems(3).DataType = 'double';
elems(3).Complexity = 'real';
elems(3).Min = [];
elems(3).Max = [];
elems(3).DocUnits = '';
elems(3).Description = '';

Accelerations = Simulink.Bus;
Accelerations.HeaderFile = '';
Accelerations.Description = '';
Accelerations.DataScope = 'Auto';
Accelerations.Alignment = -1;
Accelerations.PreserveElementDimensions = 0;
Accelerations.Elements = elems;
clear elems;
assignin('base','Accelerations', Accelerations);

% Bus object: AsteroidState 
clear elems;
elems(1) = Simulink.BusElement;
elems(1).Name = 'position';
elems(1).Dimensions = 3;
elems(1).DimensionsMode = 'Fixed';
elems(1).DataType = 'double';
elems(1).Complexity = 'real';
elems(1).Min = [];
elems(1).Max = [];
elems(1).DocUnits = '';
elems(1).Description = '';

elems(2) = Simulink.BusElement;
elems(2).Name = 'velocity';
elems(2).Dimensions = 3;
elems(2).DimensionsMode = 'Fixed';
elems(2).DataType = 'double';
elems(2).Complexity = 'real';
elems(2).Min = [];
elems(2).Max = [];
elems(2).DocUnits = '';
elems(2).Description = '';

AsteroidState = Simulink.Bus;
AsteroidState.HeaderFile = '';
AsteroidState.Description = '';
AsteroidState.DataScope = 'Auto';
AsteroidState.Alignment = -1;
AsteroidState.PreserveElementDimensions = 0;
AsteroidState.Elements = elems;
clear elems;
assignin('base','AsteroidState', AsteroidState);

