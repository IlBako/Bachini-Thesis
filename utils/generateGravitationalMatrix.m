function [gravStruct, coords, griddedInterp] = generateGravitationalMatrix(asteroidData, NPoints, options)

    arguments
        asteroidData            (1,1)   struct
        NPoints                 (1,1)   double

        options.useParallel     (1,1) logical = false
        options.useLaplacian    (1,1) logical = false
        options.interpVal       (:, 1) string 
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

    gravStruct.gravPot = cell2mat(gravPot);
    gravStruct.gravAtt = cell2mat(cellfun(@(v) v(:).', gravAtt, 'UniformOutput', false));
    gravStruct.gravAttNorm = cell2mat(cellfun(@(v) norm(v), gravAtt, 'UniformOutput', false));
    gravStruct.gravGrad = permute(cat(3, gravGrad{:}), [3, 1, 2]);
    gravStruct.gravLaplace = cell2mat(gravLaplace);

    coords.X = X;
    coords.Y = Y;
    coords.Z = Z;

    if nargout > 2 && ~isempty(options.interpVal)

        if strcmpi(options.interpVal, "all")
            options.interpVal = ["potential"; "attraction"; "attraction norm"; "gradient"; "laplacian"];
        end

        griddedInterp = cell(length(options.interpVal), 2);
        
        for ii = 1:length(options.interpVal)
            griddedInterp{ii, 1} = options.interpVal(ii);

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
            griddedInterp{ii, 2} = generateInterpolant(interpData, coords);
        end
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

    F = griddedInterpolant(X, Y, Z, interpData, 'linear');
end