function [gravStruct, griddedInterp] = generateGravitationalMatrix(asteroidData, coords, options)

    arguments
        asteroidData            (1,1)   struct
        coords                  (1,1)   struct

        options.useParallel     (1,1) logical = false
        options.useLaplacian    (1,1) logical = false
        options.reshape         (1,1) logical = true
        options.interpVal       (:, 1) string ...
            {mustBeMember(options.interpVal, ["none"; "all"; "potential"; "attraction"; "attraction norm"; "gradient"; "laplacian"])} ...
            = "none"
    end

    meshData = asteroidData.mesh;
    density = asteroidData.density;

    switch coords.type
        case "linear"
            X = coords.X;
            Y = coords.Y;
            Z = coords.Z;
            pointMats = [X(:) Y(:) Z(:)];
        case "radial"
            R_vect = coords.R;
            theta_vect = coords.theta;
            phi_vect = coords.phi;
            [R, Th, Phi] = ndgrid(R_vect, theta_vect, phi_vect);
            pointMats = [R(:) Th(:) Phi(:)];
        otherwise
            error("Unsupported coordinate type: %s", coords.type);
    end

    N = size(pointMats, 1);

    gravPot = cell(N, 1);
    gravAtt = cell(N, 1);
    gravGrad = cell(N, 1);
    gravLaplace = cell(N, 1);


    laplaceTol = 1e-6;
    pw = PoolWaitbar(size(pointMats, 1), "Gravity model generation for n="+num2str(size(pointMats, 1)) + " points");

    coords_type = coords.type;
    useLaplacian = options.useLaplacian;
    updatePoints = false;

    if options.useParallel
        warning('off','MATLAB:mir_warning_maybe_uninitialized_temporary');
        parfor ii = 1:size(pointMats, 1)
            switch coords_type
                case "linear"
                    currPoint = pointMats(ii, :)';
                case "radial"
                    currPoint = sphere2Cart(pointMats(ii, :))';
                otherwise
                    error("Unsupported coordinate type: %s", coords_type);
            end
            [gravPot{ii}, gravAtt{ii}, gravGrad{ii}, gravLaplace{ii}] = ...
                runGravModel(meshData, currPoint, density, useLaplacian, laplaceTol);
            increment(pw);
        end
        warning('on','MATLAB:mir_warning_maybe_uninitialized_temporary');
    else
        for ii = 1:size(pointMats, 1)
            switch coords_type
                case "linear"
                    currPoint = pointMats(ii, :)';
                case "radial"
                    currPoint = sphere2Cart(pointMats(ii, :))';
                otherwise
                    error("Unsupported coordinate type: %s", coords_type);
            end
            [gravPot{ii}, gravAtt{ii}, gravGrad{ii}, gravLaplace{ii}] = ...
                runGravModel(meshData, currPoint, density, useLaplacian, laplaceTol);
            
            increment(pw);
        end
    end

    delete(pw);

    switch coords.type
        case "linear"
            NPointsX = size(X, 1);
            NPointsY = size(Y, 2);
            NPointsZ = size(Z, 3);
        case "radial"
            NPointsX = length(R_vect);
            NPointsY = length(theta_vect);
            NPointsZ = length(phi_vect);
    end

    if options.reshape
        gravStruct.gravPot = reshape(cell2mat(gravPot), NPointsX, NPointsY, NPointsZ);
        gravStruct.gravAtt = reshape(cell2mat(cellfun(@(v) v(:).', gravAtt, 'UniformOutput', false)), NPointsX, NPointsY, NPointsZ, 3);
        gravStruct.gravAttNorm = reshape(cell2mat(cellfun(@(v) norm(v), gravAtt, 'UniformOutput', false)), NPointsX, NPointsY, NPointsZ);
        gravStruct.gravGrad = reshape(permute(cat(3, gravGrad{:}), [3, 1, 2]), NPointsX, NPointsY, NPointsZ, 3, 3);
        gravStruct.gravLaplace = reshape(cell2mat(gravLaplace), NPointsX, NPointsY, NPointsZ);
    else
        gravStruct.gravPot = cell2mat(gravPot);
        gravStruct.gravAtt = cell2mat(cellfun(@(v) v(:).', gravAtt, 'UniformOutput', false));
        gravStruct.gravAttNorm = cell2mat(cellfun(@(v) norm(v), gravAtt, 'UniformOutput', false));
        gravStruct.gravGrad = permute(cat(3, gravGrad{:}), [3, 1, 2]);
        gravStruct.gravLaplace = cell2mat(gravLaplace);
    end

    if nargout > 1 && ~strcmpi(options.interpVal, "none")

        if strcmpi(options.interpVal, "all")
            options.interpVal = ["potential"; "attraction"; "attraction norm"; "gradient"; "laplacian"];
        end

        griddedInterp = configureDictionary("string", "griddedInterpolant");
        
        for ii = 1:length(options.interpVal)

            switch lower(options.interpVal(ii))
                case "potential"
                    interpData = gravStruct.gravPot;
                case "attraction"
                    interpData = gravStruct.gravAtt;
                case "attraction norm"
                    interpData = gravStruct.gravAttNorm;
                case "gradient"
                    interpData = gravStruct.gravGrad;
                case "laplacian"
                    interpData = gravStruct.gravLaplace;
                otherwise
                    warning("Unknown interpolation value: " + options.interpVal(ii));
                    continue;
            end

            if ~options.reshape
                interpData = reshape(interpData, [NPointsX NPointsY NPointsZ size(interpData, 2:ndims(interpData))]);
            end

            griddedInterp(lower(options.interpVal(ii))) = generateInterpolant(interpData, coords);
            if strcmpi(options.interpVal(ii), "laplacian")
                griddedInterp(lower(options.interpVal(ii))).Method = 'nearest';
                griddedInterp(lower(options.interpVal(ii))).ExtrapolationMethod = 'nearest';
            end
        end
    else
        griddedInterp = {};
    end
end

function [gravPot, gravAtt, gravGrad, gravLaplace, pointChanged, newPoint] = runGravModel(meshData, currPoint, density, useLaplacian, laplaceTol)
    pointChanged = false;
    gravLaplace = computeLaplacian(meshData.faceList, currPoint);
    if useLaplacian && (abs(gravLaplace - 4*pi) < laplaceTol)
        [~, idx] = min(vecnorm(meshData.vertexList - currPoint',2,2));
        currPoint = meshData.vertexList(idx, :);
        pointChanged = true;
    end
    [gravPot, gravAtt, gravGrad] = gravitationalModel(meshData, currPoint, density);
    newPoint = currPoint;
end

function F = generateInterpolant(interpData, coords)
    if strcmpi(coords.type, "linear")
        P = [2 1 3];
        X = permute(coords.X, P);
        Y = permute(coords.Y, P);
        Z = permute(coords.Z, P);
        interpData = permute(interpData, [2 1 3:ndims(interpData)]);
    elseif strcmpi(coords.type, "radial")
        [X, Y, Z] = ndgrid(coords.R, coords.theta, coords.phi);
    end
    F = griddedInterpolant(X, Y, Z, interpData, 'linear', 'linear');

end