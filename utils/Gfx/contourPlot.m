function contourPlot(gridSize, NPoints, data, plane, level, coordsType, options)
    % contourPlot - Plot contour of data at a specified level in a given plane
    %
    % This function generates a contour plot of the provided data at a specified
    % level in the chosen plane (xy, xz, or yz). It can also overlay a mesh
    % representation of an asteroid if mesh data is provided.
    %
    % contourPlot(gridSize, NPoints, data, plane, level, options)
    %
    % Inputs:
    %   gridSize:           [3x1] (double) Size of the grid in each dimension
    %   NPoints:            (double) Number of points in each dimension
    %   data:               (griddedInterpolant) Interpolant of data values at the grid points
    %   plane:              (string) Plane to plot ('xy', 'xz', 'yz') (default: 'xy')
    %   level:              (double) Level at which to plot the contour (default: 0)
    %   coordsType:         (string) Type of coordinates ('linear', 'radial') (default: 'radial')
    %   options:            (struct) Structure containing options for plotting 
    %       .meshData:          (struct) Mesh data to overlay (default: [])
    %       .center:            [3x1] (double) Center of the asteroid (default: [0; 0; 0])
    %       .nContours:         (double) Number of contour levels (default: 30)
    %       .colorbarLabel:     (string) Label for the colorbar (default: "")

    arguments
        gridSize            (3,1)   double
        NPoints             (1,1)   double
        data                (1,1)   griddedInterpolant
        plane               {mustBeMember(plane,["xy","xz","yz"])} = "xy"
        level               (1,1)   double = 0;
        coordsType          {mustBeMember(coordsType,["linear","radial"])} = "radial"

        options.meshData                struct = [];
        options.center          (3,1)   double = [0; 0; 0]
        options.nContours       (1,1)   double = 30;
        options.colorbarLabel   (1,1)   string = "";
    end

    xdata = linspace(-gridSize(1), gridSize(1), NPoints);
    ydata = linspace(-gridSize(2), gridSize(2), NPoints);
    zdata = linspace(-gridSize(3), gridSize(3), NPoints);

    % Permutation order from meshgrid to ndgrid
    P = [2 1 3];

    switch plane
        case "xy"
            [X, Y] = meshgrid(xdata, ydata);
            Xq = permute(X, P);
            Yq = permute(Y, P);

            switch coordsType
                case "linear"
                    Gs = squeeze(data(Xq, Yq, level*ones(size(Xq))));
                case "radial"
                    [radius, polar, azimuth] = cart2Sphere(xdata, ydata, level);
                    Gs = squeeze(data(radius, polar, azimuth));
            end

            xl = 'X [m]'; yl = 'Y [m]';
            viewAngle = [0 90];

        case "xz"
            [X, Y] = meshgrid(xdata, zdata);
            Xq = permute(X, P);
            Yq = permute(Y, P);
            
            switch coordsType
                case "linear"
                    Gs = squeeze(data(Xq, level*ones(size(Xq)), Yq));
                case "radial"
                    [radius, polar, azimuth] = cart2Sphere(xdata, level, zdata);
                    Gs = squeeze(data(radius, polar, azimuth));
            end
            
            xl = 'X [m]'; yl = 'Z [m]';
            viewAngle = [0 90];

        case "yz"
            [X, Y] = meshgrid(ydata, zdata);
            Xq = permute(X, P);
            Yq = permute(Y, P);

            switch coordsType
                case "linear"
                    Gs = squeeze(data(level*ones(size(Xq)), Xq, Yq));
                case "radial"
                    [radius, polar, azimuth] = cart2Sphere(level, ydata, zdata);
                    Gs = squeeze(data(radius, polar, azimuth));
            end
            
            xl = 'Y [m]'; yl = 'Z [m]';
            viewAngle = [0 90];

        otherwise
            error("plane must be 'xy', 'xz' or 'yz'.");
    end

    contourf(Xq, Yq, Gs, options.nContours);
    xlabel(xl); ylabel(yl);
    view(viewAngle);
    cb = colorbar;

    if ~strcmpi(options.colorbarLabel, "")
        ylabel(cb, options.colorbarLabel, 'Interpreter', 'latex', 'FontSize', 12);
    end
    if ~isempty(options.meshData)
        drawMesh(options.meshData);
    end
end