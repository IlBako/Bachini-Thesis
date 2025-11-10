clc; clearvars; close all;

addpath("classes\");
addpath("utils\");

%% Load asteroid Data

asteroidData = generateAsteroidData("Kleopatra", "Z", "X", 4.64e18, "filename", "models\Kleopatra_Ostro.stl", "diameterTol", 1);

%% Draw mesh
if false
figure; hold on; view(20,30);
axis equal; grid on;
xlabel("X [m]"); ylabel("Y [m]"); zlabel("Z [m]");

drawMesh(asteroidData.mesh);
end

%% Gravitational model
tic
[gravStruct, coords] = generateGravitationalMatrix(asteroidData, 10, "useParallel", true);
toc

%%

figure; hold on; grid on; axis equal;
contourPlot(coords.X, coords.Y, coords.Z, gravStruct.gravAttNorm, 'xy', 'level', 0.1020, 'meshData', asteroidData.mesh, 'nContours', 30, 'colorbarLabel', "$\Vert \nabla U \Vert$ $[m\ s^{-2}]$");
