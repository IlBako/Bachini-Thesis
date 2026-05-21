clc; clearvars; close all;

addpath("..\GravityFieldGeneration\src\");

simData = load('nomData.mat');
gravData = load(simData.gravDataPath);
wpData = load(simData.waypointsPath);
simOut = simData.simOut;
dvCmdData = squeeze(simOut.dvCmdLog.Data);
dvCmdIdxs = find(any(diff(dvCmdData, 1, 2) ~= 0, 1)) + 1;
if any(dvCmdData(:,1) ~= 0) && (isempty(dvCmdIdxs) || dvCmdIdxs(1) ~= 1)
    dvCmdIdxs = [1, dvCmdIdxs];
end

params.mesh = gravData.asteroidData.mesh;
params.density = gravData.asteroidData.density;
params.angVel = [0;0;4.0684e-4]; % BENNU

numBurns = length(dvCmdIdxs);
burnRec = nan(numBurns, 3);
TRec = nan(1e2, numBurns+1);
YRec = nan(1e2, 6, numBurns+1);
odeOpts = odeset('RelTol', 1e-6, 'AbsTol', 1e-9);

%%

t0 = simOut.time(1);
if ~isempty(dvCmdIdxs)
    t1 = simOut.time(dvCmdIdxs(1));
else
    t1 = simOut.time(end);
end
Y0 = [simOut.SCState.position.Data(1,:)'; simOut.SCState.velocity.Data(1, :)'];
Y0_init = Y0;
if t1 > t0
    tspan = linspace(t0, t1, 1e2);
    [T, Y] = ode45(@(t, y) odeFcn(t, y, params), tspan, Y0(:), odeOpts);
else
    T = repmat(t0, 1e2, 1);
    Y = repmat(Y0', 1e2, 1);
end
TRec(:, 1) = T;
YRec(:, :, 1) = Y;

%%

for ii = 1:length(dvCmdIdxs)
    idx = dvCmdIdxs(ii);
    t0 = simOut.time(idx);
    if ii == length(dvCmdIdxs)
        t1 = simOut.time(end);
    else
        t1 = simOut.time(dvCmdIdxs(ii+1));
    end
    tspan = linspace(t0, t1, 1e2);
    dvCmd = simOut.dvCmdLog.Data(:, idx);
    pos = Y(end, 1:3);
    vel = Y(end, 4:6);
    burnRec(ii, :) = pos;
    Y0 = [pos(:); vel(:) + dvCmd(:)];
    [T, Y] = ode45(@(t, y) odeFcn(t, y, params), tspan, Y0, odeOpts);
    TRec(:,ii+1) = T;
    YRec(:, :, ii+1) = Y;
    fprintf("Leg %d/%d completed!\n", ii, length(dvCmdIdxs));
end

%%

f = figure; hold on; view(33,11);
axis equal; grid on;
xlabel("X [m]"); ylabel("Y [m]"); zlabel("Z [m]");
drawMesh(params.mesh);
for ii = 1:size(YRec, 3)
    if ii == 1
        scatter3(Y0(1), Y0(2), Y0(3), 50, 'r', 'filled');
    else
        scatter3(burnRec(ii-1, 1), burnRec(ii-1, 2), burnRec(ii-1, 3), 'k', 'filled');
    end
    plot3(YRec(:, 1, ii), YRec(:, 2, ii), YRec(:, 3, ii), 'b', 'LineWidth', 1)
end

%%

proxRadius = 50;

f = figure; hold on; view(0,90);
axis equal; grid on;
xlabel("X [m]"); ylabel("Y [m]"); zlabel("Z [m]");
drawMesh(params.mesh);
hTraj = plot3(squeeze(YRec(:, 1, :)), squeeze(YRec(:, 2, :)), squeeze(YRec(:, 3, :)), 'b', 'LineWidth', 1);
if numel(hTraj) > 1
    set(hTraj(2:end), 'HandleVisibility', 'off');
end
set(hTraj(1), 'DisplayName', 'Trajectory');

[sp.X, sp.Y, sp.Z] = sphere;
for ii = 1:wpData.NWaypoints
    if ii == 1
        s = scatter3(wpData.wp_r(ii,1), wpData.wp_r(ii, 2), wpData.wp_r(ii,3), 50, 'm', 'filled', 'DisplayName', 'Waypoints');
    else
        s = scatter3(wpData.wp_r(ii,1), wpData.wp_r(ii, 2), wpData.wp_r(ii,3), 50, 'm', 'filled', 'HandleVisibility', 'off');
    end
    dtRow = dataTipTextRow("idx",ii);
    s.DataTipTemplate.DataTipRows(end+1) = dtRow;
    mesh(sp.X*proxRadius+wpData.wp_r(ii, 1), sp.Y*proxRadius+wpData.wp_r(ii, 2), sp.Z*proxRadius+wpData.wp_r(ii, 3), 'EdgeColor', 'none', 'FaceColor', 'cyan', 'FaceAlpha', 0.25, 'HandleVisibility', 'off');
end

for ii = 1:length(burnRec)
    if ii == 1
        s = scatter3(burnRec(ii,1), burnRec(ii,2), burnRec(ii,3), 'k', 'filled', 'DisplayName', 'Maneuvers');
    else
        s = scatter3(burnRec(ii,1), burnRec(ii,2), burnRec(ii,3), 'k', 'filled', 'HandleVisibility','off');
    end
    dtRow = dataTipTextRow("currentWaypointIdx", ii);
    s.DataTipTemplate.DataTipRows(end+1) = dtRow;
end

scatter3(YRec(1, 1, 1), YRec(1, 2, 1), YRec(1, 3, 1), 25, 'g', 'filled', 'DisplayName', "Start position");
scatter3(YRec(end, 1, end), YRec(end, 2, end), YRec(end, 3, end), 25, 'r', 'filled', 'DisplayName', "End position");

legend('Interpreter', 'latex', 'Location', 'northeast');

%%

% Build full propagated trajectory from YRec and compare with simOut
tY = reshape(TRec, [], 1);
rY = reshape(permute(YRec(:, 1:3, :), [1 3 2]), [], 3);

valid = ~any(isnan(rY),2) & ~isnan(tY);
tY = tY(valid);
rY = rY(valid,:);

% Interpolate simOut trajectory at propagated times
simT = simOut.SCState.position.Time;
simR = simOut.SCState.position.Data;
% ensure numeric times
tY_num = tY;
Rsim_interp = interp1(simT, simR, tY_num, 'linear');

errVec = rY - Rsim_interp;
errNorm = vecnorm(errVec, 2, 2);

% 3D comparison plot
fcmp3 = figure; hold on; view(33,11);
axis equal; grid on;
xlabel('X [m]'); ylabel('Y [m]'); zlabel('Z [m]');
drawMesh(params.mesh);
plot3(simR(:,1), simR(:,2), simR(:,3), 'Color', [0.5 0.5 0.5], 'LineWidth', 1, 'DisplayName', 'simOut Trajectory');
plot3(rY(:,1), rY(:,2), rY(:,3), 'b', 'LineWidth', 1.5, 'DisplayName', 'Propagated (YRec)');
scatter3(rY(1,1), rY(1,2), rY(1,3), 40, 'g', 'filled', 'DisplayName', 'Start');
scatter3(rY(end,1), rY(end,2), rY(end,3), 40, 'r', 'filled', 'DisplayName', 'End');
legend('Location','northeast');

% 2D error plots
ferr = figure; tiledlayout(3,1);
nexttile;
plot(tY_num, errNorm, 'b-', 'LineWidth', 1.2);
ylabel('Position error [m]'); grid on;
nexttile;
plot(tY_num, errVec(:,1), 'r', tY_num, errVec(:,2), 'g', tY_num, errVec(:,3), 'b');
ylabel('Component error [m]'); legend('e_x','e_y','e_z'); grid on;
nexttile;
histogram(errNorm, 50); xlabel('Error [m]'); ylabel('Counts'); title(sprintf('Error mean=%.3f m, max=%.3f m', mean(errNorm), max(errNorm)));




%% 

function dY = odeFcn(~, Y, params)
    r = Y(1:3);
    v = Y(4:6);

    [~, gravAcc] = gravitationalModel(params.mesh, r, params.density);

    dY = zeros(6, 1);
    dY(1:3) = v;
    dY(4:6) = gravAcc - 2*cross(params.angVel, v) - cross(params.angVel, cross(params.angVel, r));
end
