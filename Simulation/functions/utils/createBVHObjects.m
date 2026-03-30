function createBVHObjects(modelName, BVH)

modelWorkspace = get_param(modelName, "ModelWorkspace");

assignParam(modelWorkspace, "BVH_bboxMin", BVH.bboxMin);
assignParam(modelWorkspace, "BVH_bboxMax", BVH.bboxMax);
assignParam(modelWorkspace, "BVH_left", BVH.left);
assignParam(modelWorkspace, "BVH_right", BVH.right);
assignParam(modelWorkspace, "BVH_fStart", BVH.fStart);
assignParam(modelWorkspace, "BVH_fCount", BVH.fCount);
assignParam(modelWorkspace, "BVH_faces", BVH.faces);
assignParam(modelWorkspace, "BVH_vertexList", BVH.vertexList);
assignParam(modelWorkspace, "BVH_normals", BVH.normals);

end

function assignParam(mw,name,value)
    p = Simulink.Parameter;
    p.Value = value;
    p.CoderInfo.StorageClass = 'ExportedGlobal';
    assignin(mw,name,p);
end