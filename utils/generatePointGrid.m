function coords = generatePointGrid(gridSize, type, NPoints, minRad)

    arguments
        gridSize    (3,1) double
        type        (1,1) string {mustBeMember(type, ["linear", "radial"])}
        NPoints     (:,1) double
        minRad      (1,1) double = 0
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
            
            xdata = linspace(-gridSize(1), gridSize(1), NPointsX);
            ydata = linspace(-gridSize(2), gridSize(2), NPointsY);
            zdata = linspace(-gridSize(3), gridSize(3), NPointsZ);

            [X, Y, Z] = meshgrid(xdata, ydata, zdata);

        case "radial"
            if isscalar(NPoints)
                NPointsR = NPoints;
                NPointsTheta = ceil(NPoints/2);
                NPointsPhi = NPoints;
            elseif length(NPoints) == 3
                NPointsR = NPoints(1);
                NPointsTheta = NPoints(2);
                NPointsPhi = NPoints(3);
            else
                error("NPoints must be either 1x1 or 3x1");
            end

            maxRad = max(gridSize);
            
            R = logspace(log10(0.9*minRad), log10(maxRad), NPointsR);
            theta = linspace(1e-6, pi-1e-6, NPointsTheta);
            phi = linspace(0, 2*pi, NPointsPhi);
            % phi(end) = [];

            [X, Y, Z] = sphere2cart(R, theta, phi);

            coords.R = R;
            coords.theta = theta;
            coords.phi = phi;

        otherwise
            error('The grid type must be either "linear" or "radial"!');
    end

    coords.X = X;
    coords.Y = Y;
    coords.Z = Z;
    coords.type = type;

end