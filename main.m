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
% NPoints = [25, 13, 26];
clc
% NPoints = [10, 4, 8];
NPoints = 100;
coords = generatePointGrid(asteroidData.gridSize, "radial", NPoints, min(abs(vecnorm(asteroidData.mesh.vertexList, 2, 2))));
tic
[gravStruct, gravInterpDict] = generateGravitationalMatrix(asteroidData, coords, "useParallel", true, "useLaplacian", true, "reshape", false, "interpVal", "all");
toc

%%

[X, Y, Z] = sphere2cart(coords.R, coords.theta, coords.phi);
gravAttNorm = reshape(gravStruct.gravAttNorm, size(X));

% figure; hold on; view(20,30);
% axis equal; grid on;
% xlabel("X [m]"); ylabel("Y [m]"); zlabel("Z [m]");
% 
% drawMesh(asteroidData.mesh);
% scatter3(X(:), Y(:), Z(:), 36, gravAttNorm(:), 'filled');
% colorbar

figure; hold on; grid on; axis equal;
levelPlot(X, Y, Z, gravAttNorm, 'xy', 0, 'meshData', asteroidData.mesh, 'nContours', 30, 'colorbarLabel', "$\Vert \nabla U \Vert$ $[m\ s^{-2}]$");


return

%% 

% pointMats = [coords.X(:) coords.Y(:) coords.Z(:)];
% G = 6.67430*1e-11;
% gravAttNorm = gravStruct.gravAttNorm;
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
levelPlot(coords.X, coords.Y, coords.Z, gravStruct.gravAttNorm, 'xy', 0, 'meshData', asteroidData.mesh, 'nContours', 30, 'colorbarLabel', "$\Vert \nabla U \Vert$ $[m\ s^{-2}]$");

return
%%

figure; hold on; grid on; axis equal;
contourPlot(asteroidData.gridSize, 100, griddedInterp("attraction norm"), 'xy', 0, 'meshData', asteroidData.mesh, 'nContours', 30, 'colorbarLabel', "$\Vert \nabla U \Vert$ $[m\ s^{-2}]$");