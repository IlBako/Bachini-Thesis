function levelPlot(X, Y, Z, data, plane, level, options)

    arguments
        X                           double
        Y                           double
        Z                           double
        data                        double
        plane               {mustBeMember(plane,["xy","xz","yz"])} = "xy"
        level       (1,1)   double = 0;

        options.meshData            struct = [];
        options.center      (3,1)   double = [0; 0; 0]
        options.nContours   (1,1)   double = 30;
        options.colorbarLabel (1,1) string = "";
    end

    if isvector(data) && numel(data) == numel(X)
        data = reshape(data, size(X));
    end
    if ~isequal(size(X), size(Y), size(Z), size(data))
        error('X, Y, Z must have the same size and data must be a vector matching numel(X).');
    end

    switch plane
        case "xy"
            vals = squeeze(Z(1,1,:));
            [~, k] = min(abs(vals - level));
            Xs = X(:, :, k);
            Ys = Y(:, :, k);
            Gs = data(:, :, k);
            xl = 'X [m]'; yl = 'Y [m]';
            viewAngle = [0 90];

        case "xz"
            vals = squeeze(Y(1,:,1));
            [~, k] = min(abs(vals - level));
            Xs = squeeze(X(:, k, :));
            Ys = squeeze(Z(:, k, :)); % vertical axis (Z)
            Gs = squeeze(data(:, k, :));
            xl = 'X [m]'; yl = 'Z [m]';
            viewAngle = [0 90];

        case "yz"
            vals = squeeze(X(:,1,1));
            [~, k] = min(abs(vals - level));
            Xs = squeeze(Y(k, :, :)); % Y axis
            Ys = squeeze(Z(k, :, :)); % Z axis
            Gs = squeeze(data(k, :, :));
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