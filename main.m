clc; clearvars; close all;

addpath("classes\");
addpath("utils\");

%% Load mesh

meshData = readStl('models\Kleopatra_Ostro.stl');

%% Draw mesh
if false
figure; hold on; view(20,30);
axis equal; grid on;
xlabel("X [m]"); ylabel("Y [m]"); zlabel("Z [m]");

drawMesh(meshData);
end
%% Gravitational model

gridSize = (max(meshData.vertexList) - min(meshData.vertexList)).*2.5;

[gravStruct, coords] = generateGravitationalMatrix(meshData, 20, gridSize, 4881);

%%

figure; hold on; grid on; axis equal;
contourPlot(coords.X, coords.Y, coords.Z, gravStruct.gravAttNorm, 'xy', 'level', 0.1020, 'meshData', meshData, 'nContours', 30);
