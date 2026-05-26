function parallelSetUpFcn()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             COMMON VARIABLES WORKERS ASSIGNMENT FUNCTION                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

m0 = memory;
fileID = fopen('worker_memory_log.txt','a');
fprintf(fileID, 'PID %d | Naked Worker RAM: %.2f GB\n', ...
    uint32(feature('getpid')), m0.MemUsedMATLAB/1e9);
fclose(fileID);

persistent isInitialized

if isempty(isInitialized)

    data = load('configData.mat');
    modelName = data.simulation.modelName;

    load_system(modelName);
    modelWorkspace = get_param(modelName, 'ModelWorkspace');

    vars = {'environment', 'actuators', 'control', 'spacecraft', ...
        'init', 'simulation', 'gravAtt', 'gravLaplace', 'ctrlVar'};

    for ii = 1:length(vars)
        assignin(modelWorkspace, vars{ii}, data.(vars{ii}));
    end

    m_start = memory;
    load_system(data.simulation.modelName);
    m_after_load = memory;
    set_param(data.simulation.modelName, 'FastRestart', 'off');
    for ii = 1:length(data.simulation.toWorkspace)
        set_param(data.simulation.modelName + "/" + data.simulation.toWorkspace(ii), 'Commented', 'off');
    end

    %% Load BVH tree

    BVH = data.environment.asteroidData.BVH;
    assignin(modelWorkspace, "BVH_bboxMin", BVH.bboxMin);
    assignin(modelWorkspace, "BVH_bboxMax", BVH.bboxMax);
    assignin(modelWorkspace, "BVH_left", BVH.left);
    assignin(modelWorkspace, "BVH_right", BVH.right);
    assignin(modelWorkspace, "BVH_fStart", BVH.fStart);
    assignin(modelWorkspace, "BVH_fCount", BVH.fCount);
    assignin(modelWorkspace, "BVH_faces", BVH.faces);
    assignin(modelWorkspace, "BVH_vertexList", BVH.vertexList);
    assignin(modelWorkspace, "BVH_normals", BVH.normals);

    if data.simulation.variants.control == controlVariant.WAYPOINT
        waypoints = data.control.waypoints;
        assignin(modelWorkspace, "WP_dtArc",                waypoints.dtArc);
        assignin(modelWorkspace, "WP_STMArcs",              waypoints.STMArcs);
        assignin(modelWorkspace, "WP_proxRadius",           waypoints.proxRadius);
        assignin(modelWorkspace, "WP_burnStrategy",         waypoints.burnStrategy);
        assignin(modelWorkspace, "WP_waypointPosition",     waypoints.waypointPosition);
        assignin(modelWorkspace, "WP_waypointVelocity",     waypoints.waypointVelocity);
        assignin(modelWorkspace, 'asteroidAngularVelocity', data.environment.asteroidAngularVelocity);
    end


    %% Fast Restart Setup
    set_param(modelName, 'FastRestart', 'on');
    m_before_update = memory;
    set_param(modelName, 'SimulationCommand', 'update');
    set_param(modelName, 'Dirty', 'off')
    m_after_update = memory;

    fileID = fopen('worker_memory_log.txt','a');
    fprintf(fileID, 'PID %d | Load Model: %.2f GB | Update Diagram: %.2f GB\n', ...
        uint32(feature('getpid')), ...
        (m_after_load.MemUsedMATLAB - m_start.MemUsedMATLAB)/1e9, ...
        (m_after_update.MemUsedMATLAB - m_before_update.MemUsedMATLAB)/1e9);
    fclose(fileID);
    
    %% Suppress Warnings
    warning('off');
    Simulink.sdi.clear;
    set_param(data.simulation.modelName, 'SignalLogging', 'off');
    clear data BVH waypoints
    isInitialized = true;
end

%% Compute ram usage
% Log memory usage to a text file (since you can't see the command window)
m = memory;
memUsedGB = m.MemUsedMATLAB / 1e9;

% Append to a log file so you can watch it in real-time
fileID = fopen('worker_memory_log.txt','a');
fprintf(fileID, 'Worker ID: %d | RAM: %.2f GB | Time: %s\n', ...
    uint32(feature('getpid')), memUsedGB, datestr(now));
fclose(fileID);
end