function [gravStruct, coords, griddedInterp] = generateGravitationalMatrix(asteroidData, NPoints, options)

    arguments
        asteroidData            (1,1)   struct
        NPoints                 (1,1)   double

        options.useParallel     (1,1) logical = false
        options.useLaplacian    (1,1) logical = false
        options.reshape         (1,1) logical = true
        options.interpVal       (:, 1) string ...
            {mustBeMember(options.interpVal, ["none"; "all"; "potential"; "attraction"; "attraction norm"; "gradient"; "laplacian"])} ...
            = "none"
    end

    gridSize = asteroidData.gridSize;
    meshData = asteroidData.mesh;
    density = asteroidData.density;

    xdata = linspace(-gridSize(1), gridSize(1), NPoints);
    ydata = linspace(-gridSize(2), gridSize(2), NPoints);
    zdata = linspace(-gridSize(3), gridSize(3), NPoints);

    [X, Y, Z] = meshgrid(xdata, ydata, zdata);

    gravPot = cell(numel(X), 1);
    gravAtt = cell(numel(X), 1);
    gravGrad = cell(numel(X), 1);
    gravLaplace = cell(numel(X), 1);

    pointMats = [X(:) Y(:) Z(:)];

    laplaceTol = 1e-6;
    pw = PoolWaitbar(size(pointMats, 1), "Gravity model generation for n="+num2str(size(pointMats, 1)) + " points");

    if options.useParallel
        useLaplacian = options.useLaplacian;
        parfor ii = 1:size(pointMats, 1)
            currPoint = pointMats(ii, :)';
            [gravPot{ii}, gravAtt{ii}, gravGrad{ii}, gravLaplace{ii}] = ...
                runGravModel(meshData, currPoint, density, useLaplacian, laplaceTol);
            increment(pw);
        end
    else
        for ii = 1:size(pointMats, 1)
            currPoint = pointMats(ii, :)';
            [gravPot{ii}, gravAtt{ii}, gravGrad{ii}, gravLaplace{ii}] = ...
                runGravModel(meshData, currPoint, density, options.useLaplacian, laplaceTol);
            increment(pw);
        end
    end

    delete(pw);

    if options.reshape
        gravStruct.gravPot = reshape(cell2mat(gravPot), NPoints, NPoints, NPoints);
        gravStruct.gravAtt = reshape(cell2mat(cellfun(@(v) v(:).', gravAtt, 'UniformOutput', false)), NPoints, NPoints, NPoints, 3);
        gravStruct.gravAttNorm = reshape(cell2mat(cellfun(@(v) norm(v), gravAtt, 'UniformOutput', false)), NPoints, NPoints, NPoints);
        gravStruct.gravGrad = reshape(permute(cat(3, gravGrad{:}), [3, 1, 2]), NPoints, NPoints, NPoints, 3, 3);
        gravStruct.gravLaplace = reshape(cell2mat(gravLaplace), NPoints, NPoints, NPoints);
    else
        gravStruct.gravPot = cell2mat(gravPot);
        gravStruct.gravAtt = cell2mat(cellfun(@(v) v(:).', gravAtt, 'UniformOutput', false));
        gravStruct.gravAttNorm = cell2mat(cellfun(@(v) norm(v), gravAtt, 'UniformOutput', false));
        gravStruct.gravGrad = permute(cat(3, gravGrad{:}), [3, 1, 2]);
        gravStruct.gravLaplace = cell2mat(gravLaplace);
    end

    coords.X = X;
    coords.Y = Y;
    coords.Z = Z;

    if nargout > 2 && ~strcmpi(options.interpVal, "none")

        if strcmpi(options.interpVal, "all")
            options.interpVal = ["potential"; "attraction"; "attraction norm"; "gradient"; "laplacian"];
        end

        griddedInterp = configureDictionary("string", "griddedInterpolant");
        
        for ii = 1:length(options.interpVal)

            switch lower(options.interpVal(ii))
                case "potential"
                    interpData = reshape(gravStruct.gravPot, NPoints, NPoints, NPoints);
                    interpData = permute(interpData, [2 1 3]);
                case "attraction"
                    interpData = reshape(gravStruct.gravAtt, NPoints, NPoints, NPoints, 3);
                    interpData = permute(interpData, [2 1 3 4]);
                case "attraction norm"
                    interpData = reshape(gravStruct.gravAttNorm, NPoints, NPoints, NPoints);
                    interpData = permute(interpData, [2 1 3]);
                case "gradient"
                    interpData = reshape(gravStruct.gravGrad, NPoints, NPoints, NPoints, 3, 3);
                    interpData = permute(interpData, [2 1 3 4 5]);
                case "laplacian"
                    interpData = reshape(gravStruct.gravLaplace, NPoints, NPoints, NPoints);
                    interpData = permute(interpData, [2 1 3]);
                otherwise
                    warning("Unknown interpolation value: " + options.interpVal(ii));
                    continue;
            end
            griddedInterp(lower(options.interpVal(ii))) = generateInterpolant(interpData, coords);
            if strcmpi(options.interpVal(ii), "laplacian")
                griddedInterp(lower(options.interpVal(ii))).Method = 'nearest';
            end
        end
    else
        griddedInterp = {};
    end
end

function [gravPot, gravAtt, gravGrad, gravLaplace] = runGravModel(meshData, currPoint, density, useLaplacian, laplaceTol)
    gravLaplace = computeLaplacian(meshData.faceList, currPoint);
    if useLaplacian && (abs(gravLaplace - 4*pi) < laplaceTol)
        gravPot = nan;
        gravAtt = nan(1,3);
        gravGrad = nan(3,3);
    else
        [gravPot, gravAtt, gravGrad] = gravitationalModel(meshData, currPoint, density);
    end
end

function F = generateInterpolant(interpData, coords)
    P = [2 1 3];
    X = permute(coords.X, P);
    Y = permute(coords.Y, P);
    Z = permute(coords.Z, P);

    F = griddedInterpolant(X, Y, Z, interpData, 'linear', 'none');
end