clc; clearvars; close all;

addpath("classes\");
addpath("utils\");

%% Load asteroid Data

asteroidData = generateAsteroidData("67P", "Z", "X", 1e13, "filename", "models\67P_C-G.stl", "diameterTol", 100);

%% Draw mesh
if false
figure; hold on; view(20,30);
axis equal; grid on;
xlabel("X [m]"); ylabel("Y [m]"); zlabel("Z [m]");

drawMesh(asteroidData.mesh);
end

%% Gravitational model
tic
[gravStruct, coords] = generateGravitationalMatrix(asteroidData, 10, "useParallel", true, "useLaplacian", false);
toc

%%

figure; hold on; grid on; axis equal;
contourPlot(coords.X, coords.Y, coords.Z, gravStruct.gravAttNorm, 'xy', 'level', 0.1020, 'meshData', asteroidData.mesh, 'nContours', 30, 'colorbarLabel', "$\Vert \nabla U \Vert$ $[m\ s^{-2}]$");
