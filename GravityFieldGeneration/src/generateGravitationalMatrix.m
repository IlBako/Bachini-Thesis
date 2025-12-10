function [gravStruct, griddedInterp] = generateGravitationalMatrix(asteroidData, coords, options)
    % generateGravitationalMatrix - Compute gravitational field over a grid of points
    %
    % This function computes the gravitational potential, attraction,
    % gradient, and Laplacian over a specified grid of points for a given
    % asteroid model. It can also generate gridded interpolants for the
    % computed gravitational values.
    %
    % [gravStruct, griddedInterp] = generateGravitationalMatrix(asteroidData, coords, options)
    %
    % Inputs:
    %   asteroidData:      (struct) Structure containing asteroid mesh and density
    %   coords:            (struct) Structure containing the grid points
    %   options:           (struct) Structure containing options for computation
    %       .useParallel:     (logical) Whether to use parallel processing (default: false)
    %       .useLaplacian:    (logical) Whether to use Laplacian check (default: false)
    %       .reshape:         (logical) Whether to reshape output arrays (default: true)
    %       .interpVal:       (string or string array) Values to interpolate 
    %                           ('none', 'all', 'potential', 'attraction', 'attraction norm',
    %                            'gradient', 'laplacian') (default: 'none')
    %
    % Outputs:
    %   gravStruct:        (struct) Structure containing gravitational field data
    %       .gravPot:       (array) Gravitational potential at grid points
    %       .gravAtt:       (array) Gravitational attraction vectors at grid points
    %       .gravAttNorm:   (array) Norm of gravitational attraction at grid points
    %       .gravGrad:      (array) Gravitational gradient tensors at grid points
    %       .gravLaplace:   (array) Gravitational Laplacian at grid points
    %   griddedInterp:      (dictionary) Dictionary containing gridded interpolants 

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
            radiusVect = coords.radius;
            polarVect = coords.polar;
            azimuthVect = coords.azimuth;
            [radiusMat, polarMat, azimuthMat] = ndgrid(radiusVect, polarVect, azimuthVect);
            pointMats = [radiusMat(:) polarMat(:) azimuthMat(:)];
        otherwise
            error("Unsupported coordinate type: %s", coords.type);
    end

    N = size(pointMats, 1);

    % Preallocate output cells
    gravPot = cell(N, 1);
    gravAtt = cell(N, 1);
    gravGrad = cell(N, 1);
    gravLaplace = cell(N, 1);

    % Tolerance for Laplacian check
    laplaceTol = 1e-6;
    pw = PoolWaitbar(size(pointMats, 1), "Gravity model generation for n="+num2str(size(pointMats, 1)) + " points");

    % Extract options to solve parfor warnings
    coordsType = coords.type;
    useLaplacian = options.useLaplacian;

    if options.useParallel
        parfor ii = 1:size(pointMats, 1)
            if strcmpi(coordsType, "linear")
                currPoint = pointMats(ii, :)';
            elseif strcmpi(coordsType, "radial")
                currPoint = sphere2Cart(pointMats(ii, :))';
            else
                error("Unsupported coordinate type: %s", coordsType);
            end
            [gravPot{ii}, gravAtt{ii}, gravGrad{ii}, gravLaplace{ii}] = ...
                runGravModel(meshData, currPoint, density, useLaplacian, laplaceTol);
            increment(pw);
        end
    else
        for ii = 1:size(pointMats, 1)
            if strcmpi(coordsType, "linear")
                currPoint = pointMats(ii, :)';
            elseif strcmpi(coordsType, "radial")
                currPoint = sphere2Cart(pointMats(ii, :))';
            else
                error("Unsupported coordinate type: %s", coordsType);
            end
            [gravPot{ii}, gravAtt{ii}, gravGrad{ii}, gravLaplace{ii}] = ...
                runGravModel(meshData, currPoint, density, useLaplacian, laplaceTol);
            
            increment(pw);
        end
    end

    % Close waitbar once gravity field generation is complete
    delete(pw);

    switch coords.type
        case "linear"
            NPointsX = size(X, 1);
            NPointsY = size(Y, 2);
            NPointsZ = size(Z, 3);
        case "radial"
            NPointsX = length(radiusVect);
            NPointsY = length(polarVect);
            NPointsZ = length(azimuthVect);
    end

    % Default output size is Nx1 (or Nx3 or Nx3x3), but can be reshaped to
    % align with grid dimensions
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

    % Generate gridded interpolants dictionary only if necessary
    if nargout > 1 && ~strcmpi(options.interpVal, "none")

        if strcmpi(options.interpVal, "all")
            options.interpVal = ["potential"; "attraction"; "attraction norm"; "gradient"; "laplacian"];
        end

        % Preallocate dictionary with defined key-value types
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
            
            % Set nearest method for Laplacian to avoid extrapolation issues
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
    % runGravModel - Helper function to compute gravitational field at a point
    %
    % This function computes the gravitational potential, attraction,
    % gradient, and Laplacian at a given point. 
    % If the Laplacian check is enabled and the computed Laplacian is
    % close to 4*pi (so the point is considered to be inside the mesh), 
    % the point is snapped to the nearest vertex of the mesh and the
    % gravitational field is recomputed.
    %
    % [gravPot, gravAtt, gravGrad, gravLaplace, pointChanged, newPoint] = runGravModel(meshData, currPoint, density, useLaplacian, laplaceTol) 
    %
    % Inputs:
    %   meshData:           (struct) Structure containing asteroid mesh data
    %   currPoint:          [3x1] (double) Current point in Cartesian coordinates
    %   density:            (double) Density of the asteroid
    %   useLaplacian:       (logical) Whether to use Laplacian check
    %   laplaceTol:         (double) Tolerance for Laplacian check
    %
    % Outputs:
    %   gravPot:            (double) Gravitational potential at currPoint
    %   gravAtt:            [3x1] (double) Gravitational attraction vector at currPoint
    %   gravGrad:           [3x3] (double) Gravitational gradient tensor at currPoint
    %   gravLaplace:        (double) Gravitational Laplacian at currPoint
    %   pointChanged:      (logical) Whether the point was changed due to Laplacian check
    %   newPoint:          [3x1] (double) New point if changed, else same as currPoint
    
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
    % generateInterpolant - Create a gridded interpolant for given data and coordinates
    %
    % This function creates a gridded interpolant for the provided
    % interpolation data based on the coordinate structure.
    %
    % F = generateInterpolant(interpData, coords)
    %
    % Inputs:
    %   interpData:     (array) Data to be interpolated
    %   coords:         (struct) Structure containing the grid points
    %
    % Outputs:
    %   F:              (griddedInterpolant) Gridded interpolant for the data

    if strcmpi(coords.type, "linear")
        % As linear grid is generated using meshgrid, dimensions
        % need to be permuted to align with ndgrid format used by griddedInterpolant
        P = [2 1 3];
        X = permute(coords.X, P);
        Y = permute(coords.Y, P);
        Z = permute(coords.Z, P);
        interpData = permute(interpData, [2 1 3:ndims(interpData)]);
    elseif strcmpi(coords.type, "radial")
        [X, Y, Z] = ndgrid(coords.radius, coords.polar, coords.azimuth);
    end

    F = griddedInterpolant(X, Y, Z, interpData, 'linear', 'linear');
end