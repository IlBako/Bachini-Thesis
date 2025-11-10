function [gravStruct, coords] = generateGravitationalMatrix(asteroidData, NPoints, options)

    arguments
        asteroidData            (1,1)   struct
        NPoints                 (1,1)   double

        options.useParallel     (1,1) logical = false
        options.useLaplacian    (1,1) logical = false
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