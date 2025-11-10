function asteroidData = generateAsteroidData(name, maxIAxis, minIAxis, mass, options)
    
    arguments
        name                (1,1) string
        maxIAxis            (1,1) string {mustBeMember(maxIAxis, ["X", "Y", "Z"])}
        minIAxis            (1,1) string {mustBeMember(minIAxis, ["X", "Y", "Z"])}
        mass                (1,1) double {mustBePositive}    

        options.filename    (1,1) string {mustBeFile} = name + ".stl"
        options.diameterTol (1,1) double = 1e-3
    end
    
    [meshData, data] = readStl(options.filename);

    % map "X","Y","Z" -> 1,2,3
    axesList = ["X","Y","Z"];
    maxIdx = find(axesList == maxIAxis, 1);
    minIdx = find(axesList == minIAxis, 1);

    asteroidData.maxIAxis = maxIdx;
    asteroidData.minIAxis = minIdx;

    Dp = computeDiameter(meshData.vertexList, maxIdx, options.diameterTol);
    De = computeDiameter(meshData.vertexList, minIdx, options.diameterTol);

    asteroidData.Dp = Dp;
    asteroidData.De = De;

    gridSize = (max(meshData.vertexList) - min(meshData.vertexList)).*2.5;

    %% Compute principal moments of inertia

    m = mass/size(meshData.vertexList, 1);
    Ix = m * sum(meshData.vertexList(:, 2).^2 + meshData.vertexList(:, 3).^2);
    Iy = m * sum(meshData.vertexList(:, 1).^2 + meshData.vertexList(:, 3).^2);
    Iz = m * sum(meshData.vertexList(:, 1).^2 + meshData.vertexList(:, 2).^2);

    %% Set asteroid data
    asteroidData.name = name;
    asteroidData.mass = mass;
    asteroidData.mesh = meshData;
    asteroidData.center = data.center;
    asteroidData.volume = data.volume;
    asteroidData.density = mass/data.volume;
    asteroidData.gridSize = gridSize;
    asteroidData.inertia = [Ix Iy Iz];


end


% helper nested function to compute span along axis where the other two coords ~ 0
function diameter = computeDiameter(vertexList, axisIdx, tol)
    other = setdiff(1:3, axisIdx);
    mask = all(abs(vertexList(:, other)) < tol, 2);
    vals = vertexList(mask, axisIdx);
    if isempty(vals)
        diameter = 0;
    else
        diameter = max(vals) - min(vals);
    end
end