%%
clc; clearvars; close all;

rng default

addpath("..\src\");
addpath(genpath("..\..\Utils\"));

asteroidData = generateAsteroidData("Sphere", "Z", "X", 5.972e24, "filename", "..\..\AsteroidModels\Sphere.stl", "diameterTol", 1000);

load("..\..\GravityData\Sphere\final\Sphere_100.mat");

N = 1e2;
radius = coords.radius;
radius_min = min(radius);
radius_max = max(radius);
polar = coords.polar;
azimuth = coords.azimuth;

pointsMat = zeros(N, 3);
sphMat = zeros(N,3);

idx = 0;

R = (rand(N,1) * (radius_max^3 - radius_min^3) + radius_min^3).^(1/3);
th = acos(1 - 2*rand(N,1)); % Gives uniform distribution over the sphere surface
phi = 2*pi*rand(N,1);

for ii = 1:N
    sphMat(ii, :) = [R(ii) th(ii) phi(ii)];
    pointsMat(ii, :) = sphere2Cart(R(ii), th(ii), phi(ii));
end

%%

simOut = sim("interpTest.slx");

simPot = squeeze(simOut.gravPot);
simAtt = squeeze(simOut.gravAtt);
simLaplace = squeeze(simOut.gravLaplace);


%% 

meshData = asteroidData.mesh;
faceList = meshData.faceList;
density = asteroidData.density;

gravPot = cell(N, 1);
gravAtt = cell(N, 1);
gravLaplace = cell(N, 1);

pw = PoolWaitbar(N, "Gravity model generation for N = " + num2str(N) + " points");

parfor ii = 1:N
    currPoint = pointsMat(ii, :)';
    gravLaplace{ii} = computeLaplacian(faceList, currPoint);
    [gravPot{ii}, gravAtt{ii}] = gravitationalModel(meshData, currPoint, density);
    increment(pw);
end

delete(pw);

gravPot = cell2mat(gravPot);
gravAtt = cell2mat(cellfun(@(v) v(:).', gravAtt, 'UniformOutput', false));
gravLaplace = cell2mat(gravLaplace);

return

%%

clc; clearvars; close all

load("Output\kleopatra_1e5.mat");

N = size(pointsMat,1);

simPot = squeeze(simOut.gravPot);
simAtt = squeeze(simOut.gravAtt);
simLaplace = squeeze(simOut.gravLaplace);

%%

errPot = nan(N, 1);
errPotRel = nan(N, 1);
errAttNorm = nan(N, 1);
errAttNormRel = nan(N, 1);
errLaplace = nan(N, 1);
errLaplaceRel = nan(N, 1);
thErr = nan(N,1);

counter = 0;

for ii = 1:N
    if abs(gravLaplace(ii) - 4*pi) < 1e-6
        counter = counter + 1;
        continue
    end
    errPot(ii) = abs(gravPot(ii) - simPot(ii));
    errPotRel(ii) = abs(gravPot(ii) - simPot(ii))/abs(gravPot(ii));
    errAttNorm(ii) = abs(norm(gravAtt(ii, :)) - norm(simAtt(ii, :)));
    errAttNormRel(ii) = abs(norm(gravAtt(ii, :)) - norm(simAtt(ii, :)))/norm(gravAtt(ii, :));
    errLaplace(ii) = abs(gravLaplace(ii) - simLaplace(ii));
    errLaplaceRel(ii) = abs(gravLaplace(ii) - simLaplace(ii))/abs(gravLaplace(ii));
    cos_theta = dot(gravAtt(ii,:),simAtt(ii,:)) / (norm(gravAtt(ii, :)) * norm(simAtt(ii, :)));
    cos_theta = max(min(cos_theta, 1), -1); % Clamp to [-1, 1]
    thErr(ii) = acos(cos_theta);
end

%%

f = figure;
tiledlayout(1,3);
nexttile
hold on; grid on;
plot(sphMat(:,1)./1e3, errPotRel*100, 'x');
xlabel("Radius $[km]$", 'Interpreter', 'latex')
ylabel("$\varepsilon_U$ $[\%]$", 'Interpreter', 'latex')

nexttile
hold on; grid on;
plot(sphMat(:,1)./1e3, errAttNormRel*100, 'x');
xlabel("Radius $[km]$", 'Interpreter', 'latex')
ylabel("$\varepsilon_{\Vert \nabla U \Vert}$ $[\%]$", 'Interpreter', 'latex')

nexttile
hold on; grid on;
plot(sphMat(:,1)./1e3, rad2deg(thErr), 'x');
xlabel("Radius $[km]$", 'Interpreter', 'latex')
ylabel("$\varepsilon_{\angle \nabla U }$ $[deg]$", 'Interpreter', 'latex')

f = figureRefine(f, 0.8, 2);
% savefig(f, "errScatterKleopatra.fig");
% exportgraphics(f, "errScatterKleopatra.pdf", 'ContentType', 'vector')

%%

f = figure;
tiledlayout(1,3);
% nexttile
% histogram(errPot);
nexttile
histogram(errPotRel*100);
% xlim([0 0.04]) % Kleopatra
xlim([0 14e-3]) % Bennu
% xlim([0 0.008]) % Sphere
xlabel("$\varepsilon_U$ $[\%]$", 'Interpreter', 'latex')
% nexttile
% histogram(errAttNorm);
nexttile
histogram(errAttNormRel*100, 1e2);
% xlim([0 0.15]) % Kleopatra
xlim([0 0.12]) % Bennu
% xlim([0 0.1]) % Sphere
xlabel("$\varepsilon_{\Vert \nabla U \Vert}$ $[\%]$", 'Interpreter', 'latex')
% nexttile
% histogram(errLaplace);
nexttile
histogram(rad2deg(thErr), 1e2);
% xlim([0 0.04]); % Kleopatra
% xlim([0 15e-3]); % Bennu
xlim([0 0.015]);
xlabel("$\varepsilon_{\angle \nabla U }$ $[deg]$", 'Interpreter', 'latex')
sgtitle("Sphere")

%%

% idxs_pot = errPotRel*100 <= 0.1; % Kleopatra
idxs_pot = errPotRel*100 <= 0.011; % Bennu
% idxs_pot = errPotRel*100 <= 0.008; % Sphere
fprintf("Potential: mean = %.4f%%, std = %.4f%%\n", mean(errPotRel(idxs_pot)*100, 'omitnan'), std(errPotRel(idxs_pot)*100, 'omitnan'));

% idxs_att = errAttNormRel*100 <= 0.7; % Kleopatra
idxs_att = errAttNormRel*100 <= 0.105; % Bennu
% idxs_att = errAttNormRel*100 <= 0.1; % Sphere
fprintf("Acceleration Norm: mean = %.4f%%, std = %.4f%%\n", mean(errAttNormRel(idxs_att)*100, 'omitnan'), std(errAttNormRel(idxs_att)*100, 'omitnan'));

% idxs_th = rad2deg(thErr) <= 0.2; % Kleopatra
idxs_th = rad2deg(thErr) <= 0.02; % Bennu
% idxs_th = rad2deg(thErr) <= 0.015; % Sphere
fprintf("Acceleration Angle: mean = %.4f deg, std = %.4f deg\n", mean(rad2deg(thErr(idxs_th)), 'omitnan'), std(rad2deg(thErr(idxs_th)), 'omitnan'));

%%

f = figure; hold on; grid on;
histogram(errPotRel*100);
% xlim([0 0.04]) % Kleopatra
% xlim([0 14e-3]) % Bennu
xlim([0 0.008]) % Sphere
xlabel("$\varepsilon_U$ $[\%]$", 'Interpreter', 'latex')
ax = gca;
ax.XAxis.Exponent = 0;
ax.YAxis.Exponent = 3;
f = figureRefine(f, 0.32);
% savefig(f, "errPotHistSphere.fig")
% exportgraphics(f, "errPotHistSphere.pdf", 'ContentType', 'vector');


f = figure; hold on; grid on;
histogram(errAttNormRel*100, 1e2);
% xlim([0 0.15]) % Kleopatra
% xlim([0 0.12]) % Bennu
xlim([0 0.1]) % Sphere
xlabel("$\varepsilon_{\Vert \nabla U \Vert}$ $[\%]$", 'Interpreter', 'latex')
ax = gca;
% ax.XAxis.Exponent = 0;
ax.YAxis.Exponent = 3;
f = figureRefine(f, 0.32);
% savefig(f, "errAccNormHistSphere.fig")
% exportgraphics(f, "errAccNormHistSphere.pdf", 'ContentType', 'vector');

f = figure; hold on; grid on;
histogram(rad2deg(thErr), 1e2);
% xlim([0 0.04]); % Kleopatra
% xlim([0 15e-3]); % Bennu
xlim([0 0.015]);
xlabel("$\varepsilon_{\angle \nabla U }$ $[deg]$", 'Interpreter', 'latex')
ax = gca;
% ax.XAxis.Exponent = 0;
ax.YAxis.Exponent = 3;
f = figureRefine(f, 0.32);
% savefig(f, "errAccAngleHistSphere.fig")
% exportgraphics(f, "errAccAngleHistSphere.pdf", 'ContentType', 'vector');

%%

f = figure;
tiledlayout(1,3);
nexttile
hold on; grid on;
histogram(errPotRel*100, 7.5e2);
xlim([0 0.04]) % Kleopatra
% xlim([0 11e-3]) % Bennu
% xlim([0 0.008]) % Sphere
xlabel("$\varepsilon_U$ $[\%]$", 'Interpreter', 'latex')
ax = gca;
ax.XAxis.Exponent = 0;
ax.YAxis.Exponent = 3;
ylabel("Count");


nexttile
hold on; grid on;
histogram(errAttNormRel*100, 5e2);
xlim([0 0.15]) % Kleopatra
% xlim([0 0.12]) % Bennu
% xlim([0 0.1]) % Sphere
xlabel("$\varepsilon_{\Vert \nabla U \Vert}$ $[\%]$", 'Interpreter', 'latex')
ax = gca;
ax.XAxis.Exponent = 0;
ax.YAxis.Exponent = 3;

nexttile
hold on; grid on;
histogram(rad2deg(thErr), 5e2);
xlim([0 0.03]); % Kleopatra
% xlim([0 15e-3]); % Bennu
% xlim([0 0.015]); % Sphere
xlabel("$\varepsilon_{\angle \nabla U }$ $[deg]$", 'Interpreter', 'latex')
ax = gca;
ax.XAxis.Exponent = 0;
ax.YAxis.Exponent = 3;
f = figureRefine(f, 1, 3);
savefig(f, "errHistKleopatra.fig")
exportgraphics(f, "errHistKleopatra.pdf", 'ContentType', 'vector');
