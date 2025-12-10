function levelPlot(coords, data, plane, level, options)
    % levelPlot - Plot contour of data at a specified level in a given plane
    %
    % This function generates a contour plot of the provided data at a specified
    % level in the chosen plane (xy, xz, or yz). It can also overlay a mesh
    % representation of an asteroid if mesh data is provided.
    % 
    % levelPlot(coords, data, plane, level, options)
    % 
    % Inputs:
    %   coords:             (struct) Structure containing grid coordinates
    %   data:               (array) Data values at the grid points
    %   plane:              (string) Plane to plot ('xy', 'xz', 'yz') (default: 'xy')
    %   level:              (double) Level at which to plot the contour (default: 0)
    %   options:            (struct) Structure containing options for plotting
    %       .meshData:          (struct) Mesh data to overlay (default: [])
    %       .center:            [3x1] (double) Center of the asteroid (default: [0; 0; 0])
    %       .nContours:         (double) Number of contour levels (default: 30)
    %       .colorbarLabel:     (string) Label for the colorbar (default: "")

    arguments
        coords              struct
        data                double
        plane               {mustBeMember(plane,["xy","xz","yz"])} = "xy"
        level       (1,1)   double = 0;

        options.meshData            struct = [];
        options.center      (3,1)   double = [0; 0; 0]
        options.nContours   (1,1)   double = 30;
        options.colorbarLabel (1,1) string = "";
    end

    X = coords.X;
    Y = coords.Y;
    Z = coords.Z;

    if isvector(data) && numel(data) == numel(X)
        data = reshape(data, size(X));
    end
    if ~isequal(size(X), size(Y), size(Z), size(data))
        error('X, Y, Z must have the same size and data must be a vector matching numel(X).');
    end

    switch plane
        case "xy"
            switch coords.type
                case "linear"
                    vals = squeeze(Z(1,1,:));
                    [~, k] = min(abs(vals - level));
                    Xs = X(:, :, k);
                    Ys = Y(:, :, k);
                    Gs = data(:, :, k);
                case "radial"
                    vals = squeeze(Z(1,:,1));
                    [~, k] = min(abs(vals - level));
                    Xs = squeeze(X(:, k, :));
                    Ys = squeeze(Y(:, k, :));
                    Gs = squeeze(data(:, k, :));
            end
            xl = 'X [m]'; yl = 'Y [m]';
            viewAngle = [0 90];

        case "xz"
            switch coords.type
                case "linear"
                    vals = squeeze(Y(:,1,1));
                    [~, k] = min(abs(vals - level));
                    Xs = squeeze(X(k, :, :));
                    Ys = squeeze(Z(k, :, :)); % vertical axis (Z)
                    Gs = squeeze(data(:, k, :));
                case "radial"
                    vals = squeeze(Y(1,1,:));
                    [~, k] = min(abs(vals - level));
                    Xs = squeeze(X(:, :, k));
                    Ys = squeeze(Z(:, :, k));
                    Gs = squeeze(data(:, :, k));
            end
            xl = 'X [m]'; yl = 'Z [m]';
            viewAngle = [0 90];

        case "yz"
            switch coords.type
                case "linear"
                    vals = squeeze(X(1,:,1));
                    [~, k] = min(abs(vals - level));
                    Xs = squeeze(Y(:, k, :)); % Y axis
                    Ys = squeeze(Z(:, k, :)); % Z axis
                    Gs = squeeze(data(:, k, :));
                case "radial"
                    vals = squeeze(X(1,1,:));
                    [~, k] = min(abs(vals - level));
                    Xs = squeeze(Y(:, :, k)); % Y axis
                    Ys = squeeze(Z(:, :, k)); % Z axis
                    Gs = squeeze(data(:, :, k));
            end
            xl = 'Y [m]'; yl = 'Z [m]';
            viewAngle = [0 90];

        otherwise
            error("plane must be 'xy', 'xz' or 'yz'.");

    end

    contourf(Xs, Ys, Gs, options.nContours);
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