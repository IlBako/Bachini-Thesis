function model = modelInitializer(environment, actuators, control, spacecraft, init, simulation)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%            CONFIGURATION FILE FOR SIMULATION INITIALIZATION             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Simulation Parameters Configuration
load_system(simulation.modelName);
set_param(simulation.modelName, ...
    'StopTime', simulation.simulationTime, ...
    'FixedStep', simulation.simulationTimeStep, ...
    'SolverType', simulation.solverType, ...
    'Solver', simulation.solver, ...
    'SimulationMode', simulation.executionMode, ...
    'Debug', simulation.debugMode, ...
    'FastRestart', simulation.fastRestart);

%% Parameter Assignment
model = Simulink.SimulationInput(simulation.modelName);
model = model.setVariable('environment', environment);
model = model.setVariable('actuators', actuators);
model = model.setVariable('control', control);
model = model.setVariable('spacecraft', spacecraft);
model = model.setVariable('init', init);

%% Variant Assignment
model = model.setVariable('variants', simulation.variants);

%% Assign BVH objects
createBVHObjects(simulation.modelName, environment.asteroidData.BVH);

%% Assign waypoint objects if necessary
if simulation.variants.control == controlVariant.WAYPOINT
    createWaypointObjects(simulation.modelName, control.waypoints);
    modelWorkspace = get_param(simulation.modelName, "ModelWorkspace");
    p = Simulink.Parameter;
    p.Value = environment.asteroidAngularVelocity;
    p.CoderInfo.StorageClass = 'ExportedGlobal';
    assignin(modelWorkspace, 'asteroidAngularVelocity', p);
end

end