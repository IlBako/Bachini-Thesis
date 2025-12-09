function asteroidData = generateAsteroidData(name, maxIAxis, minIAxis, mass, options)
    % generateAsteroidData - Generate asteroid data structure from STL file
    % 
    % This function reads an ascii STL file representing the shape of an
    % asteroid and computes various physical properties such as diameter,
    % mass, density, and moments of inertia. The user can specify which
    % axes correspond to the maximum and minimum inertia axis.
    %
    % asteroidData = generateAsteroidData(name, maxIAxis, minIAxis, mass, options)
    %
    % Inputs:
    %   name:               (string) Name of the asteroid
    %   maxIAxis:           (string) Axis corresponding to maximum inertia ("X", "Y", or "Z")
    %   minIAxis:           (string) Axis corresponding to minimum inertia ("X", "Y", or "Z")
    %   mass:               (double) Mass of the asteroid (must be positive)
    %   options:            (struct) Optional parameters:
    %       .filename       (string) Path to the STL file (default: name + ".stl")
    %       .diameterTol    (double) Tolerance for diameter computation (default: 1e-3)
    %
    % Outputs:
    %   asteroidData:       (struct) Structure containing asteroid properties:
    %       .name           (string) Name of the asteroid
    %       .mass           (double) Mass of the asteroid
    %       .mesh           (struct) Mesh data from STL file
    %       .center         (double) Center of mass from STL data
    %       .volume         (double) Volume from STL data
    %       .density        (double) Density computed from mass and volume
    %       .gridSize       (double) Suggested grid size for simulations 2.5x max along each axis
    %       .Dp             (double) Diameter along maximum inertia axis
    %       .De             (double) Diameter along minimum inertia axis
    %       .inertia        (double) Principal moments of inertia [Ix, Iy, Iz]

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

    gridSize = (max(meshData.vertexList) - min(meshData.vertexList)).*2.5;

    %% Compute principal moments of inertia

    m = mass/size(meshData.vertexList, 1);
    Ix = m * sum(meshData.vertexList(:, 2).^2 + meshData.vertexList(:, 3).^2);
    Iy = m * sum(meshData.vertexList(:, 1).^2 + meshData.vertexList(:, 3).^2);
    Iz = m * sum(meshData.vertexList(:, 1).^2 + meshData.vertexList(:, 2).^2);

    %% Set asteroid data
    asteroidData.name = name;                   % Name of the asteroid
    asteroidData.mass = mass;                   % Mass of the asteroid
    asteroidData.mesh = meshData;               % Mesh data from STL file
    asteroidData.center = data.center;          % Center of mass from STL data
    asteroidData.volume = data.volume;          % Volume from STL data
    asteroidData.density = mass/data.volume;    % Density computed from mass and volume
    asteroidData.gridSize = gridSize;           % Suggested grid size for simulations 2.5x max along each axis
    asteroidData.Dp = Dp;                       % Diameter along maximum inertia axis   
    asteroidData.De = De;                       % Diameter along minimum inertia axis
    asteroidData.inertia = [Ix Iy Iz];          % Principal moments of inertia [Ix, Iy, Iz]


end

function diameter = computeDiameter(vertexList, axisIdx, tol)
    % computeDiameter - Computes diameter of the asteroid along a specified axis
    %
    % diameter = computeDiameter(vertexList, axisIdx, tol)
    %
    % Inputs:
    %   vertexList:    [N x 3] List of vertex coordinates from STL file
    %   axisIdx:       (int) Axis index (1 for X, 2 for Y, 3 for Z)
    %   tol:           (double) Tolerance for considering vertices along the axis
    %
    % Outputs:
    %   diameter:      (double) Computed diameter along the specified axis
    
    other = setdiff(1:3, axisIdx);
    mask = all(abs(vertexList(:, other)) < tol, 2);
    vals = vertexList(mask, axisIdx);
    if isempty(vals)
        diameter = 0;
    else
        diameter = max(vals) - min(vals);
    end
end