function laplacian = computeLaplacian(faceList, fieldPoint)
    % computeLaplacian - Compute the Laplacian of the gravitational potential
    %
    % This function computes the Laplacian of the gravitational potential
    % at a specified field point given the asteroid's mesh faces.
    %
    % laplacian = computeLaplacian(faceList, fieldPoint)
    % 
    % Inputs:
    %   faceList:       (cell array) List of face objects from the asteroid mesh
    %   fieldPoint:     (1x3 double) Coordinates of the field point [x, y, z]
    %
    % Outputs:
    %   laplacian:     (double) Laplacian of the gravitational potential at the field point
    %
    % References:
    %   [1] Werner, Robert & Scheeres, D.. (1996). 
    %       Exterior Gravitation of a Polyhedron Derived and Compared with Harmonic and Mascon Gravitation 
    %       Representations of Asteroid 4769 Castalia. Celestial Mechanics and Dynamical Astronomy. 
    %       65. 313-344. 10.1007/BF00053511. 

    % Laplacian is computed as the sum of the solid angles of all faces
    laplacian = 0;
    for ii = 1:length(faceList)
        laplacian = laplacian + faceList{ii}.computeOmegaf(fieldPoint);
    end

end