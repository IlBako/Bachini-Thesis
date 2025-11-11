function contourPlot(gridSize, Npoints, data, plane, level, options)
    arguments
        gridSize            (3,1)   double
        Npoints             (1,1)   double
        data                (1,1)   griddedInterpolant
        plane               {mustBeMember(plane,["xy","xz","yz"])} = "xy"
        level               (1,1)   double = 0;

        options.meshData                struct = [];
        options.center          (3,1)   double = [0; 0; 0]
        options.nContours       (1,1)   double = 30;
        options.colorbarLabel   (1,1)   string = "";
    end

    xdata = linspace(-gridSize(1), gridSize(1), Npoints);
    ydata = linspace(-gridSize(2), gridSize(2), Npoints);
    zdata = linspace(-gridSize(3), gridSize(3), Npoints);

    % Permutation order from meshgrid to ndgrid
    P = [2 1 3];

    switch plane
        case "xy"
            [X, Y] = meshgrid(xdata, ydata);
            Xq = permute(X, P);
            Yq = permute(Y, P);
            Gs = data(Xq, Yq, level*ones(size(Xq)));
            xl = 'X [m]'; yl = 'Y [m]';
            viewAngle = [0 90];

        case "xz"
            [X, Y] = meshgrid(xdata, zdata);
            Xq = permute(X, P);
            Yq = permute(Y, P);
            Gs = data(Xq, level*ones(size(Xq)), Yq);
            xl = 'X [m]'; yl = 'Z [m]';
            viewAngle = [0 90];

        case "yz"
            [X, Y] = meshgrid(ydata, zdata);
            Xq = permute(X, P);
            Yq = permute(Y, P);
            Gs = data(level*ones(size(Xq)), Xq, Yq);
            xl = 'Y [m]'; yl = 'Z [m]';
            viewAngle = [0 90];

        otherwise
            error("plane must be 'xy', 'xz' or 'yz'.");
    end

    contour(Xq, Yq, Gs, options.nContours);
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