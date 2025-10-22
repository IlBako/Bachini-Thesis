function [U, dU, ddU] = gravitationalModel(meshData, fieldPoint, density, G)
    % gravitationalModel - Function to compute the polyhedral gravity model
    % in a field point
    %
    % [U, dU, ddU, laplacian] = gravitationalModel(meshData, fieldPoint, density, G)
    %
    % Inputs:
    %   meshData: 
    %   fieldPoint:      
    %   density:
    %   G:
    % 
    % Outputs:
    %   U:
    %   dU:
    %   ddU:

    arguments
        meshData    (1,1)   struct
        fieldPoint  (3,1)   double
        density     (1,1)   double
        G           (1,1)   double = 6.67430*1e-11
    end

    edgeList = meshData.edgeList;
    faceList = meshData.faceList;

    edgeComp_U = 0;
    edgeComp_dU = 0;
    edgeComp_ddU = 0;

    for ii = 1:length(edgeList)
        edge = edgeList{ii};
        re = edge.vertices(:,1) - fieldPoint;
        Le = edge.computeLe(fieldPoint);
        
        edgeComp_U = edgeComp_U + re'*edge.Ee*re * Le;

        edgeComp_dU = edgeComp_dU + edge.Ee*re * Le;

        edgeComp_ddU = edgeComp_ddU + edge.Ee * Le;
    end

    faceComp_U = 0;
    faceComp_dU = 0;
    faceComp_ddU = 0;

    for ii = 1:length(faceList)
        face = faceList{ii};
        rf = face.computeRf(fieldPoint);
        omf = face.computeOmegaf(fieldPoint);
        
        faceComp_U = faceComp_U + rf'*face.Ff*rf * omf;

        faceComp_dU = faceComp_dU + face.Ff*rf * omf;

        faceComp_ddU = faceComp_ddU + face.Ff * omf;
    end

    U = 1/2*G*density*edgeComp_U - 1/2*G*density*faceComp_U;
    dU = -G*density*edgeComp_dU + G*density*faceComp_dU;
    ddU = G*density*edgeComp_ddU - G*density*faceComp_ddU;

end