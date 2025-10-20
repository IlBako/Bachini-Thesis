function [gravStruct, coords] = generateGravitationalMatrix(meshData, NPoints, gridSize, density)

    arguments
        meshData    (1,1)   struct
        NPoints     (1,1)   double
        gridSize    (1,3)   double
        density     (1,1)   double
    end
    
    xdata = linspace(-gridSize(1), gridSize(1), NPoints);
    ydata = linspace(-gridSize(2), gridSize(2), NPoints);
    zdata = linspace(-gridSize(3), gridSize(3), NPoints);

    [X, Y, Z] = meshgrid(xdata, ydata, zdata);

    gravPot = nan(numel(X), 1);
    gravAtt = nan(numel(X), 3);
    gravGrad = nan(numel(X), 3, 3);
    gravLaplace = nan(numel(X), 1);

    for ii = 1:numel(X)
        currPoint = [X(ii) Y(ii) Z(ii)]';
        [gravPot(ii), gravAtt(ii, :), gravGrad(ii, :, :), gravLaplace(ii)] = gravitationalModel(meshData, currPoint, density);
    end
    gravAttNorm = vecnorm(gravAtt, 2, 2);

    gravStruct.gravPot = gravPot;
    gravStruct.gravAtt = gravAtt;
    gravStruct.gravAttNorm = gravAttNorm;
    gravStruct.gravGrad = gravGrad;
    gravStruct.gravLaplace = gravLaplace;

    coords.X = X;
    coords.Y = Y;
    coords.Z = Z;
end