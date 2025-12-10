function coords = generatePointGrid(gridSize, type, NPoints, minRad, maxRad)
    % generatePointGrid - Generate a 3D grid of points for gravitational field evaluation
    %
    % This function generates a 3D grid of points based on the specified
    % grid size, type (linear or radial), and number of points.
    % 
    % coords = generatePointGrid(gridSize, type, NPoints, minRad, maxRad)
    %
    % Inputs:
    %   gridSize:       [3x1] (double) Size of the grid in each dimension [X; Y; Z] 
    %   type:           (string) Type of grid to generate ('linear' or 'radial')
    %   NPoints:        [1x1] or [3x1] (double) Number of points in each dimension
    %   minRad:         (double) Minimum radius for radial grid (default: 0)
    %   maxRad:         (double) Maximum radius for radial grid (default: max(gridSize))
    %
    % Outputs:
    %   coords:         (struct) Structure containing the generated grid points
    %       .X:         (3D array) X-coordinates of the grid points
    %       .Y:         (3D array) Y-coordinates of the grid points
    %       .Z:         (3D array) Z-coordinates of the grid points
    %       .type:      (string) Type of grid generated ('linear' or 'radial')
    %       .radius:    (1D array) Radii for radial grid (only for 'radial' type)
    %       .polar:     (1D array) Polar angles for radial grid (only for 'radial' type)
    %       .azimuth:   (1D array) Azimuthal angles for radial grid (only for 'radial' type)

    arguments
        gridSize    (3,1) double
        type        (1,1) string {mustBeMember(type, ["linear", "radial"])}
        NPoints     (:,1) double
        minRad      (1,1) double = 0
        maxRad      (1,1) double = max(gridSize)
    end

    switch(type)
        case "linear"
            if isscalar(NPoints)
                NPointsX = NPoints;
                NPointsY = NPoints;
                NPointsZ = NPoints;
            elseif length(NPoints) == 3
                NPointsX = NPoints(1);
                NPointsY = NPoints(2);
                NPointsZ = NPoints(3);
            else
                error("NPoints must be either 1x1 or 3x1");
            end
            
            xData = linspace(-gridSize(1), gridSize(1), NPointsX);
            yData = linspace(-gridSize(2), gridSize(2), NPointsY);
            zData = linspace(-gridSize(3), gridSize(3), NPointsZ);

            [X, Y, Z] = meshgrid(xData, yData, zData);

        case "radial"
            if isscalar(NPoints)
                % Polar coordinates use half the points as it's in [0, pi]
                % instead of [0, 2pi)
                NPointsRadius = NPoints;
                NPointsPolar = ceil(NPoints/2);
                NPointsAzimuth = NPoints;
            elseif length(NPoints) == 3
                NPointsRadius = NPoints(1);
                NPointsPolar = NPoints(2);
                NPointsAzimuth = NPoints(3);
            else
                error("NPoints must be either 1x1 or 3x1");
            end
            
            radius = logspace(log10(0.9*minRad), log10(maxRad), NPointsRadius);
            polar = linspace(1e-6, pi-1e-6, NPointsPolar);
            azimuth = linspace(0, 2*pi, NPointsAzimuth);

            [X, Y, Z] = sphere2Cart(radius, polar, azimuth);

            coords.radius = radius;
            coords.polar = polar;
            coords.azimuth = azimuth;

        otherwise
            error('The grid type must be either "linear" or "radial"!');
    end

    coords.X = X;
    coords.Y = Y;
    coords.Z = Z;
    coords.type = type;

end