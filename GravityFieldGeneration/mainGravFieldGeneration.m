% Main script to generate gravitational field of an asteroid using polyhedral method

clc; clearvars; close all;

addpath("src\");
addpath(genpath("..\Utils\"));

%% Load asteroid Data

asteroidData = generateAsteroidData("Kleopatra", "Z", "X", 4.64e18, "filename", "..\AsteroidModels\Kleopatra_Ostro.stl", "diameterTol", 1);

%% Draw mesh

if false
figure; hold on; view(20,30);
axis equal; grid on;
xlabel("X [m]"); ylabel("Y [m]"); zlabel("Z [m]");

drawMesh(asteroidData.mesh);
end

%% Gravitational model

NPoints = 25;
coords = generatePointGrid(asteroidData.gridSize, "radial", NPoints, min(vecnorm(asteroidData.mesh.vertexList, 2, 2)));
tic
[gravStruct, gravInterpDict] = generateGravitationalMatrix(asteroidData, coords, "useParallel", true, "useLaplacian", true, "reshape", true, "interpVal", "all");
toc

switch coords.type
    case "linear"
        X = coords.X;
        Y = coords.Y;
        Z = coords.Z;
    case "radial"
        [X, Y, Z] = sphere2Cart(coords.radius, coords.polar, coords.azimuth);
    otherwise
        error("Unsupported coordinate type: %s", coords.type);
end

%% 

figure; hold on; grid on; axis equal;
levelPlot(coords, gravStruct.gravAttNorm, 'xy', 0, 'nContours', 30, 'meshData', asteroidData.mesh, 'colorbarLabel', "$\Vert \nabla U \Vert$ $[m\ s^{-2}]$");

%%

figure; hold on; grid on; axis equal;
contourPlot(asteroidData.gridSize, 100, gravInterpDict("attraction norm"), 'xy', 0, coords.type, 'nContours', 30, 'meshData', asteroidData.mesh, 'colorbarLabel', "$\Vert \nabla U \Vert$ $[m\ s^{-2}]$");