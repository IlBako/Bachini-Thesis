function [U, dU, ddU] = gravitationalModel(meshData, fieldPoint, density, G)
    % gravitationalModel - Compute the gravitational model at a field point
    %
    % This function computes the gravitational potential, its gradient,
    % and its Hessian at a specified field point given the asteroid's mesh data.
    %
    % [U, dU, ddU] = gravitationalModel(meshData, fieldPoint, density, G)
    %
    % Inputs:
    %   meshData:           (struct) Structure containing the asteroid's mesh data
    %       .edgeList:      (cell array) List of mesh's edges
    %       .faceList:      (cell array) List of mesh's edges
    %   fieldPoint:         [3x1] (double) Coordinates of the field point [x; y; z]
    %   density:            (double) Density of the asteroid [kg/m^3]
    %   G:                  (double) Gravitational constant [N m^2/kg^2] (default: 6.67430e-11)
    % 
    % Outputs:
    %   U:             (double) Gravitational potential at the field point [m^s/s^2]
    %   dU:            (3x1 double) Gradient of the gravitational potential at the field point [m/s^2]
    %   ddU:           (3x3 double) Hessian of the gravitational potential at the field point [1/s^2]
    
    % References:
    %   [1] Werner, Robert & Scheeres, D.. (1996). 
    %       Exterior Gravitation of a Polyhedron Derived and Compared with Harmonic and Mascon Gravitation 
    %       Representations of Asteroid 4769 Castalia. Celestial Mechanics and Dynamical Astronomy. 
    %       65. 313-344. 10.1007/BF00053511. 

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

        if all(re == 0) || isinf(Le)
            continue
        end
        
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