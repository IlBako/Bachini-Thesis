function contourPlot(X, Y, Z, data, plane, options)

    arguments
        X                           double
        Y                           double
        Z                           double
        data                (:,1)   double
        plane               {mustBeMember(plane,["xy","xz","yz"])} = "xy"
        options.level       (1,1)   double = 0;

        options.meshData            struct = [];
        options.nContours   (1,1)   double = 30;
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
            [~, k] = min(abs(vals - options.level));
            Xs = X(:, :, k);
            Ys = Y(:, :, k);
            Gs = data(:, :, k);
            xl = 'X [m]'; yl = 'Y [m]';
            viewAngle = [0 90];

        case "xz"
            vals = squeeze(Y(1,:,1));
            [~, k] = min(abs(vals - options.level));
            Xs = squeeze(X(:, k, :));
            Ys = squeeze(Z(:, k, :)); % vertical axis (Z)
            Gs = squeeze(data(:, k, :));
            xl = 'X [m]'; yl = 'Z [m]';
            viewAngle = [0 90];

        case "yz"
            vals = squeeze(X(:,1,1));
            [~, k] = min(abs(vals - options.level));
            Xs = squeeze(Y(k, :, :)); % Y axis
            Ys = squeeze(Z(k, :, :)); % Z axis
            Gs = squeeze(data(k, :, :));
            xl = 'Y [m]'; yl = 'Z [m]';
            viewAngle = [0 90];

        otherwise
            error("plane must be 'xy', 'xz' or 'yz'.");

    end

    contour(Xs, Ys, Gs, options.nContours);
    xlabel(xl); ylabel(yl);
    view(viewAngle);
    colorbar;
    if ~isempty(options.meshData)
        drawMesh(options.meshData);
    end
end