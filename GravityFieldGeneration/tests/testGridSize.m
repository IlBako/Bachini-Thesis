clc; clearvars; close all;

rng default

addpath("..\src\");
addpath(genpath("..\..\Utils\"));

% asteroidData = generateAsteroidData("Sphere", "Z", "X", 5.972e24, "filename", "..\..\AsteroidModels\Sphere.stl", "diameterTol", 1000);

baseData = load("Output\bennu_1e5.mat");

gravData{1} = load("..\..\GravityData\Bennu\final\Bennu_10.mat");
gravData{2} = load("..\..\GravityData\Bennu\final\Bennu_25.mat");
gravData{3} = load("..\..\GravityData\Bennu\final\Bennu_50.mat");
gravData{4} = load("..\..\GravityData\Bennu\final\Bennu_100.mat");

pointsMat = baseData.pointsMat;
sphMat = baseData.sphMat;
N = size(pointsMat, 1);

%%

simPot = cell(4,1);
simAtt = cell(4,1);
simLaplace = cell(4,1);
gravSize = cell(4,1);

for ii = 1:length(gravData)
    gravStruct = gravData{ii}.gravStruct;
    radius = gravData{ii}.coords.radius;
    polar = gravData{ii}.coords.polar;
    azimuth = gravData{ii}.coords.azimuth;
    tic
    simOut = sim("interpTest.slx");
    toc

    simPot{ii} = squeeze(simOut.gravPot);
    simAtt{ii} = squeeze(simOut.gravAtt);
    simLaplace{ii} = squeeze(simOut.gravLaplace);
    gravSize{ii} = 5/2*gravData{ii}.NPoints + 4/2*gravData{ii}.NPoints^3 * 8;
    fprintf("Finished run %d of %d\n", ii, length(gravData));
end

gravSize = cell2mat(gravSize);


%% 1. Initialization for Plots
idxs = abs(baseData.gravLaplace - 4*pi) > 1e-6;
colors = fliplr(["blue", "red", "green", "yellow"]);

% Arrays to store means for the decay plot
gridSizes      = zeros(length(gravData), 1);
meanErrPot     = zeros(length(gravData), 1);
meanErrAttNorm = zeros(length(gravData), 1);
meanErrAngle   = zeros(length(gravData), 1);

% Setup Histogram Figure
figHist = figure('Position', [100, 100, 1200, 400], 'Name', 'Histograms');
ax1 = subplot(1, 3, 1); hold on; grid on; xlabel('$\varepsilon_U$ $[\%]$', 'Interpreter', 'latex'); ylabel('Count');
ax2 = subplot(1, 3, 2); hold on; grid on; xlabel('$\varepsilon_{||\nabla U||}$ $[\%]$', 'Interpreter', 'latex'); % ylabel('Counts');
ax3 = subplot(1, 3, 3); hold on; grid on; xlabel('$\varepsilon_{\angle \nabla U}$ $[deg]$', 'Interpreter', 'latex'); % ylabel('Counts');

% 2. Vectorized Math & Histogram Plotting
for ii = 1:length(gravData)
    % Extract masked data
    baseAtt = baseData.gravAtt(idxs, :);
    simA    = simAtt{ii}(idxs, :);
    basePot = baseData.gravPot(idxs);
    simP    = simPot{ii}(idxs);
    
    % Calculations
    errPotRel = abs(basePot - simP) ./ abs(basePot);
    
    baseAttNorm = vecnorm(baseAtt, 2, 2);
    simAttNorm  = vecnorm(simA, 2, 2);
    errAttNormRel = abs(baseAttNorm - simAttNorm) ./ baseAttNorm;
    
    dotProd = sum(baseAtt .* simA, 2); 
    cos_theta = max(min(dotProd ./ (baseAttNorm .* simAttNorm), 1), -1);
    thErr_deg = rad2deg(acos(cos_theta));
    
    % Store means and grid size for the decay plot
    gridSizes(ii)      = gravData{ii}.NPoints;
    meanErrPot(ii)     = mean(errPotRel) * 100;
    meanErrAttNorm(ii) = mean(errAttNormRel) * 100;
    meanErrAngle(ii)   = mean(thErr_deg);
    
    % Plot Histograms
    dispName = num2str(gravData{ii}.NPoints);
    histogram(ax1, errPotRel * 100, 100, 'DisplayName', dispName, 'FaceColor', colors(ii));
    histogram(ax2, errAttNormRel * 100, 35, 'DisplayName', dispName, 'FaceColor', colors(ii));
    histogram(ax3, thErr_deg, 100, 'DisplayName', dispName, 'FaceColor', colors(ii));
end
legend(ax2, 'Location', 'north');

xlim(ax1, [0 1.4])
xlim(ax2, [0 13])
xlim(ax3, [0 2.1])

ax2.YAxis.Exponent = 4;

figHist = figureRefine(figHist, 1, 3);
% savefig(figHist, "histTradeoff.fig");
% exportgraphics(figHist, "histTradeoff.pdf", 'ContentType', 'vector');

%% 3. Error Decay Line Plots
figDecay = figure('Position', [150, 150, 1200, 400], 'Name', 'Error Decay vs Grid Size');

% Potential Error Decay
subplot(1, 3, 1);
plot(gridSizes, meanErrPot, '-o', 'LineWidth', 2, 'MarkerSize', 6);
grid on;
xlabel('Grid Size ($N_{points}$)', 'Interpreter', 'latex');
ylabel('Mean $\varepsilon_U$ $[\%]$', 'Interpreter', 'latex');
title('Potential Error Decay');
xticks([0 10 25 50 100])

% Acceleration Norm Error Decay
subplot(1, 3, 2);
plot(gridSizes, meanErrAttNorm, '-o', 'LineWidth', 2, 'MarkerSize', 6);
grid on;
xlabel('Grid Size ($N_{points}$)', 'Interpreter', 'latex');
ylabel('Mean $\varepsilon_{||\nabla U||}$ $[\%]$', 'Interpreter', 'latex');
title('Acceleration Norm Decay');
xticks([0 10 25 50 100])

% Acceleration Angle Error Decay
subplot(1, 3, 3);
plot(gridSizes, meanErrAngle, '-o', 'LineWidth', 2, 'MarkerSize', 6);
grid on;
xlabel('Grid Size ($N_{points}$)', 'Interpreter', 'latex');
ylabel('Mean $\varepsilon_{\angle \nabla U}$ $[deg]$', 'Interpreter', 'latex');
title('Acceleration Angle Decay');
xticks([0 10 25 50 100])

figDecay = figureRefine(figDecay, 1, 2.75);
% savefig(figDecay, "errorDecay.fig");
% exportgraphics(figDecay, "errorDecay.pdf", 'ContentType', 'vector');