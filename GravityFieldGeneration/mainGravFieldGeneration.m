clc; clearvars; close all;

addpath("utils\");
addpath(genpath("..\Utils\"));

%% Load asteroid Data

asteroidData = generateAsteroidData("Kleopatraz", "Z", "X", 4.64e18, "filename", "..\AsteroidModels\Kleopatra_Ostro.stl", "diameterTol", 1);

%% Draw mesh
if false
figure; hold on; view(20,30);
axis equal; grid on;
xlabel("X [m]"); ylabel("Y [m]"); zlabel("Z [m]");

drawMesh(asteroidData.mesh);
end

%% Gravitational model
% NPoints = 100;
NPoints = 25;
coords = generatePointGrid(asteroidData.gridSize, "radial", NPoints, min(vecnorm(asteroidData.mesh.vertexList, 2, 2)));
tic
[gravStruct, gravInterpDict] = generateGravitationalMatrix(asteroidData, coords, "useParallel", true, "useLaplacian", true, "reshape", true, "interpVal", "all");
toc

%%

[X, Y, Z] = sphere2cart(coords.R, coords.theta, coords.phi);
% gravAttNorm = reshape(gravStruct.gravAttNorm, size(X));
% 
% figure; hold on; view(20,30);
% axis equal; grid on;
% xlabel("X [m]"); ylabel("Y [m]"); zlabel("Z [m]");

% drawMesh(asteroidData.mesh);
% scatter3(X(:), Y(:), Z(:), 36, 'filled', 'MarkerFaceAlpha', 0.5, 'MarkerEdgeAlpha', 0.5);
% colorbar
% 
% figure; hold on; grid on; axis equal;
% levelPlot(X, Y, Z, gravAttNorm, 'xy', 0, 'meshData', asteroidData.mesh, 'nContours', 30, 'colorbarLabel', "$\Vert \nabla U \Vert$ $[m\ s^{-2}]$");
% 
% 
% return

%% 

% pointMats = [X(:) Y(:) Z(:)];
% G = 6.67430*1e-11;
% gravAttNorm = gravStruct.gravAttNorm(:);
% 
% tic
% parfor ii = 1:size(pointMats, 1)
%     if isnan(gravAttNorm(ii))
%         sphereGravNorm{ii} = nan;
%     else
%         sphereGravNorm{ii} = G*5.972168e24/(norm(pointMats(ii, :)))^2;
%     end
% end
% 
% sphereGravNorm = cell2mat(sphereGravNorm)';
% gravErr = sphereGravNorm - gravAttNorm;
% gravPercErr = gravErr ./ sphereGravNorm*100;
% 
% toc

%% 

figure; hold on; grid on; axis equal;
levelPlot(X, Y, Z, gravStruct.gravAttNorm, 'xy', 0, 'nContours', 30, 'meshData', asteroidData.mesh, 'colorbarLabel', "$\Vert \nabla U \Vert$ $[m\ s^{-2}]$");
% levelPlot(X, Y, Z, gravStruct.gravAttNorm, 'xy', 0, 'nContours', 30, 'colorbarLabel', "$\Vert \nabla U \Vert$ $[m\ s^{-2}]$");

%%

figure; hold on; grid on; axis equal;
contourPlot(asteroidData.gridSize, 100, gravInterpDict("attraction norm"), 'xy', 0, 'nContours', 30, 'meshData', asteroidData.mesh, 'colorbarLabel', "$\Vert \nabla U \Vert$ $[m\ s^{-2}]$");
% contourPlot(asteroidData.gridSize, 100, gravInterpDict("attraction norm"), 'xy', 0, 'nContours', 30, 'colorbarLabel', "$\Vert \nabla U \Vert$ $[m\ s^{-2}]$");