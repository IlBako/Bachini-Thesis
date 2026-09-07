clc; clearvars; close all;

rng default

addpath("..\src\");
addpath(genpath("..\..\Utils\"));

asteroidData = generateAsteroidData("Sphere", "Z", "X", 5.972e24, "filename", "..\..\AsteroidModels\Sphere.stl", "diameterTol", 1000);

load("..\..\GravityData\Sphere\final\Sphere_100.mat");

%%

G = 6.67430*1e-11;
gravPot = gravStruct.gravPot(:);
gravAttNorm = gravStruct.gravAttNorm(:);
pointMats = [coords.X(:) coords.Y(:) coords.Z(:)];

gravPot = gravPot(vecnorm(pointMats, 2,2) >= 6371000);
gravAttNorm = gravAttNorm(vecnorm(pointMats, 2,2) >= 6371000);
pointMats = pointMats(vecnorm(pointMats, 2,2) >= 6371000, :);

r = vecnorm(pointMats,2,2);
r2 = r.^2;
sphereGravPot = G*5.972168e24./r;
sphereGravNorm = G*5.972168e24./r2;

gravPotErr = sphereGravPot - gravPot;
gravPercPotErr = gravPotErr ./ sphereGravPot * 100;
gravAccErr = sphereGravNorm - gravAttNorm;
gravPercAttErr = gravAccErr ./ sphereGravNorm * 100;

absGravPotErr = abs(sphereGravPot - gravPot);
absGravPercPotErr = absGravPotErr ./ abs(sphereGravPot) * 100;
absGravAccErr = abs(sphereGravNorm - gravAttNorm);
absGravPercAttErr = absGravAccErr ./ abs(sphereGravNorm) * 100;

%%

f = figure; hold on; grid on;
plot(r./1e3 - 6371, gravPercPotErr, '.', 'MarkerSize', 4.5);
ylabel("$U$ Error $[\%]$", 'Interpreter', 'latex');
xlabel("Distance from surface $[km]$", 'Interpreter', 'latex');
f = figureRefine(f, 0.48);
savefig(f, "errPotSphere.fig");
exportgraphics(f, "errPotSphere.png", "Resolution", 900);


f = figure; hold on; grid on;
plot(r./1e3 - 6371, gravPercAttErr, '.', 'MarkerSize', 4.5);
ylabel("$\Vert \nabla U \Vert$ Error $[\%]$", 'Interpreter', 'latex');
xlabel("Distance from surface $[km]$", 'Interpreter', 'latex');
f = figureRefine(f, 0.48);
savefig(f, "errAccSphere.fig");
exportgraphics(f, "errAccSphere.png", "Resolution", 900);

%%

fprintf("Potential: mean = %.4f%%, std = %.4f%%\n", mean(absGravPercPotErr), std(absGravPercPotErr));
fprintf("Acceleration: mean = %.4f%%, std = %.4f%%\n", mean(absGravPercAttErr), std(absGravPercAttErr));
