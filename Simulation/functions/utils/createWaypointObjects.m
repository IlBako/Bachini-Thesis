function createWaypointObjects(modelName, waypoints)

modelWorkspace = get_param(modelName, "ModelWorkspace");

assignParam(modelWorkspace, "WP_dtArc",            waypoints.dtArc);
assignParam(modelWorkspace, "WP_STMArcs",          waypoints.STMArcs);
assignParam(modelWorkspace, "WP_proxRadius",       waypoints.proxRadius);
assignParam(modelWorkspace, "WP_waypointPosition", waypoints.waypointPosition);
assignParam(modelWorkspace, "WP_waypointVelocity", waypoints.waypointVelocity);

% The number of waypoints needs to be a define (compile-time constant)
p = Simulink.Parameter;
p.Value = int32(waypoints.NWaypoints);
p.CoderInfo.StorageClass = 'Custom';
p.CoderInfo.CustomStorageClass = 'Define';
assignin(modelWorkspace, 'WP_NWaypoints', p);

end

function assignParam(mw,name,value)
    p = Simulink.Parameter;
    p.Value = value;
    p.CoderInfo.StorageClass = 'ExportedGlobal';
    assignin(mw,name,p);
end