% Main script to run the ARIES simulator
% (ARIES: Asteroid-centered Relative Inertial and Environmental Simulator)

clc; close all; clearvars -except isProjectLoaded

options.reloadProject = false;

%% Initialization

if ~exist("isProjectLoaded", 'var'), isProjectLoaded = false; end

if ~isProjectLoaded || options.reloadProject
    repoRoot = fileparts(mfilename('fullpath'));
    addpath(genpath("..\Utils"))
    proj = openProject("ARIES.prj");
    isProjectLoaded = true;
end

%% Data loading

% gravDataPath = "..\GravityData\Kleopatra\Kleopatra_100_radial_snap_update.mat";
gravDataPath = "..\GravityData\Bennu\Bennu_100.mat";
% gravDataPath = "..\GravityData\Itokawa\Itokawa_100.mat";
environment = environmentConfig(gravDataPath);
actuators = actuatorsConfig();
[control, spacecraft] = controlConfig(environment.asteroidMu);
init = initConditionConfig(control);
simulation = simulationConfig(control);

gravAtt = Simulink.Parameter(environment.gravStruct.gravAtt);
gravAtt.CoderInfo.StorageClass = 'ExportedGlobal';
gravLaplace = Simulink.Parameter(environment.gravStruct.gravLaplace);
gravLaplace.CoderInfo.StorageClass = 'ExportedGlobal';

ctrlVar = Simulink.Parameter(simulation.variants.control);
ctrlVar.StorageClass = 'ExportedGlobal';

%% Model initialization

model = modelInitializer(environment, actuators, control, spacecraft, init, simulation);

%% Run simulation

tic
simOut = sim(model);
toc
% tic
% simOut = sim(modelName,'SimulationMode','normal');
% toc

% if simOut.time(end) < configs.sim.Tf
%     disp("Simulation finished early!");
% end

%%

f = figure; hold on; view(33,11);
axis equal; grid on;
xlabel("X [m]"); ylabel("Y [m]"); zlabel("Z [m]");
% xlim([-500 500]); ylim([-500 500]); zlim([-300 450]);
meshData = environment.asteroidData.mesh;
drawMesh(meshData);
plot3(simOut.SCState.position.Data(:,1), simOut.SCState.position.Data(:,2), simOut.SCState.position.Data(:,3), 'LineWidth', 1, 'DisplayName', 'Trajectory');
% scatter3(simOut.SCState.position.Data(end,1), simOut.SCState.position.Data(end,2), simOut.SCState.position.Data(end,3), 50, 'r', 'filled', 'DisplayName', "End position");
% scatter3(simOut.SCState.position.Data(1,1), simOut.SCState.position.Data(1,2), simOut.SCState.position.Data(1,3), 50, 'g', 'filled', 'DisplayName', "Start position");

% [sp.X, sp.Y, sp.Z] = sphere;

wpData = load("data\bennuWaypoints_orb1.mat");
for ii = 1:wpData.NWaypoints
    if ii == 1
        s = scatter3(wpData.wp_r(ii,1), wpData.wp_r(ii, 2), wpData.wp_r(ii,3), 50, 'm', 'filled', 'DisplayName', 'Waypoints');
    else
        s = scatter3(wpData.wp_r(ii,1), wpData.wp_r(ii, 2), wpData.wp_r(ii,3), 50, 'm', 'filled', 'HandleVisibility', 'off');
    end
    dtRow = dataTipTextRow("idx",ii);
    s.DataTipTemplate.DataTipRows(end+1) = dtRow;
    % mesh(sp.X*control.waypoints.proxRadius+wpData.wp_r(ii, 1), sp.Y*control.waypoints.proxRadius+wpData.wp_r(ii, 2), sp.Z*control.waypoints.proxRadius+wpData.wp_r(ii, 3), 'EdgeColor', 'none', 'FaceColor', 'cyan', 'FaceAlpha', 0.25, 'HandleVisibility', 'off');
end
burnIdxs = find(vecnorm(simOut.controlAcc.Data,2,2) ~= 0);
burnIdxs = [burnIdxs(1); burnIdxs(find(diff(burnIdxs) ~= 1)+1)];
for ii = 1:length(burnIdxs)
    if ii == 1
    s = scatter3(simOut.SCState.position.Data(burnIdxs(ii),1), simOut.SCState.position.Data(burnIdxs(ii),2), simOut.SCState.position.Data(burnIdxs(ii),3), 'k', 'filled', 'DisplayName', 'Maneuvers');
    else
    s = scatter3(simOut.SCState.position.Data(burnIdxs(ii),1), simOut.SCState.position.Data(burnIdxs(ii),2), simOut.SCState.position.Data(burnIdxs(ii),3), 'k', 'filled', 'HandleVisibility','off');
    end
    dtRow = dataTipTextRow("currentWaypointIdx",simOut.currentWaypointIdx.Data(burnIdxs(ii)));
    s.DataTipTemplate.DataTipRows(end+1) = dtRow;
end
legend('Interpreter', 'latex', 'Location', 'northeast');

f = figureRefine(f, 0.48);
% savefig(f, "gfx/Kleopatra_waypoints/Nominal_3DTraj.fig");
% exportgraphics(f, "gfx/Kleopatra_waypoints/Nominal_3DTraj.pdf", 'ContentType', 'vector');


%%
f = figure; hold on; grid on;
plot(simOut.controlAcc.Time./wpData.TRef, vecnorm(reshape(simOut.controlAcc.Data, [], 3),2,2));
xlabel("Time [orbits]", 'Interpreter', 'latex');
ylabel("$a_u$ $[m/s^2]$", 'Interpreter', 'latex');
% legend('Interpreter', 'latex', 'Location', 'northoutside', 'Orientation', 'horizontal');
title({"Control acceleration $a_u$", "$\Delta v$ = " + num2str(trapz(simOut.controlAcc.Time, vecnorm(reshape(simOut.controlAcc.Data, [], 3),2,2))) + " $[m/s]$"}, 'Interpreter', 'latex')
f = figureRefine(f, 0.8, 2);
% savefig(f, "gfx/Kleopatra_waypoints/Nominal_ControlAcc.fig");
% exportgraphics(f, "gfx/Kleopatra_waypoints/Nominal_ControlAcc.pdf", 'ContentType', 'vector');

%% 

% For each burn, the ARRIVAL error is measured at the NEXT burn
% (i.e. burn k+1 fires when spacecraft is near waypoint k+1,
%  so the position at burn k+1 start is the arrival from burn k)
nBurns = length(burnIdxs);
eps_k   = nan(nBurns - 1, 1);
tActual = nan(nBurns - 1, 1);

for ii = 1:nBurns - 1
    % State at start of burn ii+1 = arrival from burn ii
    arrivalIdx  = burnIdxs(ii + 1);

    % Waypoint the spacecraft is arriving AT
    % (current_k at arrival is the waypoint being approached,
    %  which is the next waypoint after the one that triggered burn ii)
    currWp  = simOut.currentWaypointIdx.Data(arrivalIdx);

    % Position error at arrival
    rActual = simOut.SCState.position.Data(arrivalIdx, :);
    tActual(ii) = simOut.SCState.position.Time(arrivalIdx);
    rWp     = wpData.wp_r(currWp, :);
    eps_k(ii) = norm(rActual - rWp);
end

fprintf('Mean arrival position error: %.2f m\n', mean(eps_k));
fprintf('Max  arrival position error: %.2f m\n', max(eps_k));
fprintf('Min  arrival position error: %.2f m\n', min(eps_k));

f = figure; hold on; grid on;
plot(tActual/wpData.TRef, eps_k, 'b-o');
xlabel('Time $[orbit]$', 'Interpreter', 'latex'); 
ylabel('Arrival position error $[m]$', 'Interpreter', 'latex');
% legend('Location', 'north', 'Orientation', 'horizontal', 'Interpreter', 'latex');
f = figureRefine(f, 0.8, 2);
% savefig(f, "gfx/Kleopatra_waypoints/Nominal_eps_k.fig");
% exportgraphics(f, "gfx/Kleopatra_waypoints/Nominal_eps_k.pdf", 'ContentType', 'vector');

return

%%
% Y0 = [configs.sim.rS0, configs.sim.vS0, configs.sim.q0, configs.sim.w0, configs.sim.rB0, configs.sim.vB0];
% opts = odeset('RelTol', 1e-3, 'MaxStep', 10, 'Events', @(t,y) collision_event(t, y, gravInterpDict("laplacian")));
% F = gravInterpDict("attraction");
% F.ExtrapolationMethod = 'nearest';
% params.wb = configs.asteroid.wb;
% params.I_sc = configs.sc.I_mat;
% params.I_inv = configs.sc.I_inv;
% params.m_sc = configs.sc.m_sc;
%
% tic
% [T, Y] = ode45(@(t,y) ARIES_odeFcn(t,y,F,params), [0 configs.sim.Tf], Y0, opts);
% toc
%%
if false
%% Plot results
if true
    f = figure; hold on; view(45,30);
    axis equal; grid on;
    xlabel("X [m]"); ylabel("Y [m]"); zlabel("Z [m]");
    meshData = environment.asteroidData.mesh;
    % meshData.vertexList = meshData.vertexList./1e3;
    drawMesh(meshData);
    plot3(simOut.SCState.position.Data(:,1), simOut.SCState.position.Data(:,2), simOut.SCState.position.Data(:,3), 'LineWidth', 1);
    scatter3(simOut.SCState.position.Data(end,1), simOut.SCState.position.Data(end,2), simOut.SCState.position.Data(end,3), 50, 'r', 'filled');
    scatter3(simOut.SCState.position.Data(1,1), simOut.SCState.position.Data(1,2), simOut.SCState.position.Data(1,3), 50, 'g', 'filled');
    legend("Trajectory", "End position", "Start position", 'Interpreter', 'latex', 'Location', 'northeast');
    % f = figureRefine(f, 0.48, 0);
    % savefig(f, "gfx/Bennu_OK/Bennu_3d_trajectory.fig");
    % exportgraphics(f, "gfx/Bennu_OK/Bennu_3d_trajectory.pdf", 'ContentType','vector');
end

%%

figure; hold on; grid on;
plot(simOut.SCState.position.Time, vecnorm(simOut.SCState.position.Data,2,2)/1e3)
title("$\mu="+num2str(mean(vecnorm(simOut.SCState.position.Data,2,2))/1e3)+"\ km$, $\sigma="+num2str(std(vecnorm(simOut.SCState.position.Data,2,2)))+"\ m$", 'Interpreter', 'latex')

figure; hold on; grid on;
plot(simOut.control_surface.Time, simOut.control_surface.Data);

figure; hold on; grid on;
plot(simOut.controlAcc.Time, vecnorm(squeeze(simOut.controlAcc.Data)',2,2));


%%

semiMajAxis = nan(length(simOut.SCState.position.Time),1);
rad = vecnorm(simOut.SCState.position.Data,2,2);
vel = vecnorm(simOut.SCState.velocity.Data,2,2);

for ii = 1:length(semiMajAxis)
    E = vel(ii)^2/2 - environment.asteroidMu/rad(ii);
    semiMajAxis(ii) = -environment.asteroidMu/(2*E);
end

f = figure; hold on; grid on;
plot(simOut.SCState.position.Time./86400, semiMajAxis);
xlabel("Time $[day]$", 'Interpreter', 'latex');
title({"Semi-major axis","$\mu_a = "+num2str(mean(semiMajAxis))+"\ m$, $\sigma_a = "+num2str(std(semiMajAxis))+"\ m$"}, 'Interpreter', 'latex')
% f = figureRefine(f, 0.48, 0);
% savefig(f, "gfx/Bennu_OK_120/Bennu_semimaj_ax.fig");
% exportgraphics(f, "gfx/Bennu_OK_120/Bennu_semimaj_ax.pdf", 'ContentType','vector');

f = figure; hold on; grid on;
plot(simOut.currentEcc.Time./86400, vecnorm(simOut.currentEcc.Data,2,2));
xlabel("Time $[day]$", 'Interpreter', 'latex');
title({"Eccentricity","$\mu_e = "+num2str(mean(vecnorm(simOut.currentEcc.Data,2,2)))+"$, $\sigma_e = "+num2str(std(vecnorm(simOut.currentEcc.Data,2,2)))+"$"}, 'Interpreter', 'latex')
% f = figureRefine(f, 0.48, 0);
% savefig(f, "gfx/Bennu_OK_120/Bennu_ecc.fig");
% exportgraphics(f, "gfx/Bennu_OK_120/Bennu_ecc.pdf", 'ContentType','vector');


%%

f = figure; hold on; grid on;
plot(simOut.controlAcc.Time./86400, vecnorm(squeeze(simOut.controlAcc.Data),2,2));
xlabel("Time $[day]$", 'Interpreter', 'latex');
ylabel("$u$ $[m/s^2]$", 'Interpreter', 'latex');
title({"Control acceleration $u$", "$\Delta v$ = " + num2str(trapz(simOut.controlAcc.Time, vecnorm(squeeze(simOut.controlAcc.Data),2,2))) + " $[m/s]$"}, 'Interpreter', 'latex')
% f = figureRefine(f, 0.7, 3);
% savefig(f, "gfx/Bennu_OK_120/Bennu_controlAcc.fig");
% exportgraphics(f, "gfx/Bennu_OK_120/Bennu_controlAcc.pdf", 'ContentType','vector');

return
%%

accGravNorm = nan(length(simOut.SCState.position.Time),1);
pos = simOut.SCState.position.Data;
gravAccNorm = gravInterpDict("attraction norm");

for ii = 1:length(accGravNorm)
    [R, polar, azimuth] = cart2Sphere(pos(ii,1), pos(ii,2), pos(ii,3));
    accGravNorm(ii) = gravAccNorm(R, polar, azimuth);
end

T_pos = simOut.SCState.position.Time;
accControl = interp1(simOut.controlAcc.Time, squeeze(simOut.controlAcc.Data)', T_pos, "previous");

figure; hold on; grid on;
plot(T_pos, vecnorm(accControl, 2, 2));
plot(T_pos, accGravNorm);


%%

r_B_I = simOut.AsteroidState.position.Data;
R_B_I = r_B_I./vecnorm(r_B_I, 2, 2);
C_BI = simOut.C_BI.Data;
R_B_I_reshaped = reshape(R_B_I', 3, 1, []);
R_B_B = squeeze(pagemtimes(C_BI, R_B_I_reshaped)).';

% figure; hold on; grid on; axis equal; view(20,30);
% xlim([-1 1]); ylim([-1 1]); zlim([-1 1]);
% for ii = 1:size(R_B_B, 1)
%     plot3([0 R_B_B(ii, 1)], [0 R_B_B(ii, 2)], [0 R_B_B(ii, 3)], 'r--');
% end

R_B_B = R_B_B.*2*max(vecnorm(asteroidData.mesh.vertexList, 2, 2))/1e3;

colors = ['r', 'g', 'k', 'm'];

idxRising = find(diff(simOut.illuminated.Data) == -1);
idxFalling = find(diff(simOut.illuminated.Data) == 1);
if size(idxRising) ~= size(idxFalling)
    error("Size mismatch");
end
idxs = [1 idxRising(1);
    idxFalling(1) idxRising(2);
    idxFalling(2) length(simOut.illuminated.Data)];

figure; hold on; view(20,30);
axis equal; grid on;
xlabel("X [m]"); ylabel("Y [m]"); zlabel("Z [m]");
meshData = asteroidData.mesh;
meshData.vertexList = meshData.vertexList./1e3;
drawMesh(meshData);
plot3(simOut.SCState.position.Data(~simOut.illuminated.Data,1)/1e3, simOut.SCState.position.Data(~simOut.illuminated.Data,2)/1e3, simOut.SCState.position.Data(~simOut.illuminated.Data,3)/1e3, 'b', 'LineWidth', 1);

for ii = 1:min(length(idxRising),length(colors))
    plot3(simOut.SCState.position.Data(idxs(ii,1):idxs(ii,2),1)/1e3, simOut.SCState.position.Data(idxs(ii,1):idxs(ii,2),2)/1e3, simOut.SCState.position.Data(idxs(ii,1):idxs(ii,2),3)/1e3, '*', 'LineWidth', 1.5, 'Color', colors(ii));
    plot3([0 R_B_B(idxs(ii, 1), 1)], [0 R_B_B(idxs(ii, 1), 2)], [0 R_B_B(idxs(ii, 1), 3)], "LineWidth", 3, 'Color', colors(ii));
end



%%

T_tau = simOut.SRPTau.Time;
ill_interp = logical(interp1(simOut.illuminated.Time, double(simOut.illuminated.Data), T_tau, 'previous'));
tau = vecnorm(simOut.SRPTau.Data,2,2);
tau(~ill_interp) = nan;

figure; hold on; grid on;
% plot(simOut.gravAttraction.Time, vecnorm(simOut.gravAttraction.Data,2,2));
% plot(simOut.TBPAcc.Time, vecnorm(simOut.TBPAcc.Data,2,2));
% plot(simOut.SRPTau.Time(ill_interp), vecnorm(simOut.SRPTau.Data(ill_interp,:),2,2), 'LineWidth', 2);
plot(simOut.SRPTau.Time(), tau, 'LineWidth', 2);
plot(simOut.SRPTau.Time(), vecnorm(simOut.SRPTau.Data(),2,2));
% plot(simOut.SRPAcc.Time(simOut.illuminated.Data), vecnorm(simOut.SRPAcc.Data(simOut.illuminated.Data,:),2,2));

%%

T_new = linspace(0, simOut.time(end), 1e4);
r_S = interp1(simOut.SCState.position.Time, simOut.SCState.position.Data, T_new);
figure; hold on; view(20,30);
axis equal; grid on;
xlabel("X [m]"); ylabel("Y [m]"); zlabel("Z [m]");
meshData = asteroidData.mesh;
meshData.vertexList = meshData.vertexList./1e3;
drawMesh(meshData);
plot3(r_S(:,1)/1e3, r_S(:,2)/1e3, r_S(:,3)/1e3, 'LineWidth', 1);
end
%%

% warning("Most of the 'To Workspace' have been disabled to save space!");

% strcase = "q0_1000__w0_wb__kw_1__ka_2_illcheck";
% strcase = "bennu_testing_rw_desat";
% folder = "results\att_tuning\testing\" + strcase;
strcase = "q1000_w0_wb";
folder = "gfx/Bennu_zenith_point/" + strcase;
mkdir(folder);

T_short = simOut.time(1):simOut.time(end);
q_SB = interp1(simOut.SCState.q_SB.Time, simOut.SCState.q_SB.Data, T_short);
q_target = interp1(simOut.q_target.Time, simOut.q_target.Data, T_short);

toSave = struct();
toSave.T_short = T_short;
toSave.q_SB = q_SB;
toSave.q_target = q_target;

f = figure; 
tiledlayout(2,2);
nexttile
plot(simOut.SCState.q_SB.Time./86400, simOut.SCState.q_SB.Data(:, 1));
title("$q_w$", 'Interpreter','latex')
nexttile
plot(simOut.SCState.q_SB.Time./86400, simOut.SCState.q_SB.Data(:, 2));
title("$q_x$", 'Interpreter','latex')
nexttile
plot(simOut.SCState.q_SB.Time./86400, simOut.SCState.q_SB.Data(:, 3));
title("$q_y$", 'Interpreter','latex')
xlabel("Time $[days]$", 'Interpreter', 'latex');
nexttile
plot(simOut.SCState.q_SB.Time./86400, simOut.SCState.q_SB.Data(:, 4));
title("$q_z$", 'Interpreter','latex')
xlabel("Time $[days]$", 'Interpreter', 'latex');
% f = figureRefine(f, 0.48, 0);
% savefig(f, folder + filesep + "q_SB.fig");
% exportgraphics(f, folder + filesep + "q_SB.pdf", 'ContentType', 'vector');

figure; 
tiledlayout(2,2);
nexttile
plot(simOut.q_target.Time, simOut.q_target.Data(:, 1));
title("$q_{t,w}$", 'Interpreter','latex')
nexttile
plot(simOut.q_target.Time, simOut.q_target.Data(:, 2));
title("$q_{t,x}$", 'Interpreter','latex')
nexttile
plot(simOut.q_target.Time, simOut.q_target.Data(:, 3));
title("$q_{t,y}$", 'Interpreter','latex')
nexttile
plot(simOut.q_target.Time, simOut.q_target.Data(:, 4));
title("$q_{t,z}$", 'Interpreter','latex')
% savefig(folder + filesep + "q_target.fig");

figure; 
tiledlayout(2,2);
nexttile
plot(T_short, q_SB(:, 1) - q_target(:, 1));
title("$q_{diff,w}$", 'Interpreter','latex')
nexttile
plot(T_short, q_SB(:, 2) - q_target(:, 2));
title("$q_{diff,x}$", 'Interpreter','latex')
nexttile
plot(T_short, q_SB(:, 3) - q_target(:, 3));
title("$q_{diff,y}$", 'Interpreter','latex')
nexttile
plot(T_short, q_SB(:, 4) - q_target(:, 4));
title("$q_{diff,z}$", 'Interpreter','latex')
% savefig(folder + filesep + "q_diff.fig");

%%

euls = rad2deg(unwrap(quat2eul(simOut.SCState.q_SB.Data)));

figure; 
tiledlayout(3,1);
nexttile
plot(simOut.SCState.q_SB.Time, euls(:, 1));
title("Yaw", 'Interpreter','latex')
nexttile
plot(simOut.SCState.q_SB.Time, euls(:, 2));
title("Pitch", 'Interpreter','latex')
nexttile
plot(simOut.SCState.q_SB.Time, euls(:, 3));
title("Roll", 'Interpreter','latex')
% savefig(folder + filesep + "euls.fig");

%%

if ~exist("T_short", 'var')
    T_short = simOut.time(1):simOut.time(end);
    toSave.T_short = T_short;
end
controlTau = interp1(simOut.controlTau.Time, simOut.controlTau.Data, T_short);
toSave.controlTau = controlTau;

f = figure; 
tiledlayout(3,1);
nexttile
plot(simOut.controlTau.Time./86400, simOut.controlTau.Data(:,1));
ylabel("$\tau_x$ $[Nm]$", 'Interpreter', 'latex');
nexttile
plot(simOut.controlTau.Time./86400, simOut.controlTau.Data(:,2));
ylabel("$\tau_y$ $[Nm]$", 'Interpreter', 'latex');
nexttile
plot(simOut.controlTau.Time./86400, simOut.controlTau.Data(:,3));
ylabel("$\tau_z$ $[Nm]$", 'Interpreter', 'latex');
xlabel("Time $[days]$", 'Interpreter', 'latex');
% f = figureRefine(f, 0.7, 2);
% savefig(f, folder + filesep + "controlTau_SB.fig");
% exportgraphics(f, folder + filesep + "controlTau_SB.pdf", 'ContentType', 'vector');

%%

if ~exist("T_short", 'var')
    T_short = simOut.time(1):simOut.time(end);
    toSave.T_short = T_short;
end
angVel = interp1(simOut.SCState.ang_velocity.Time, simOut.SCState.ang_velocity.Data, T_short);
w_target = interp1(simOut.w_target.Time, simOut.w_target.Data, T_short);
toSave.angVel = angVel;
toSave.w_target = w_target;

f = figure; 
tiledlayout(3,1);
nexttile; hold on; grid on;
plot(simOut.SCState.ang_velocity.Time./86400, simOut.SCState.ang_velocity.Data(:, 1));
ylabel("$\omega_x$ $[rad/s]$", 'Interpreter','latex')
nexttile; hold on; grid on;
plot(simOut.SCState.ang_velocity.Time./86400, simOut.SCState.ang_velocity.Data(:, 2));
ylabel("$\omega_y$ $[rad/s]$", 'Interpreter','latex')
nexttile; hold on; grid on;
plot(simOut.SCState.ang_velocity.Time./86400, simOut.SCState.ang_velocity.Data(:, 3));
ylabel("$\omega_z$ $[rad/s]$", 'Interpreter','latex')
xlabel("Time $[days]$", 'Interpreter', 'latex');
% f = figureRefine(f, 0.48, 0);
% savefig(f, folder + filesep + "ws.fig");
% exportgraphics(f, folder + filesep + "ws.pdf", 'ContentType', 'vector');

figure; 
tiledlayout(3,1);
nexttile; hold on; grid on;
plot(simOut.w_target.Time, simOut.w_target.Data(:, 1));
title("$\omega_{t,x}$", 'Interpreter','latex')
nexttile; hold on; grid on;
plot(simOut.w_target.Time, simOut.w_target.Data(:, 2));
title("$\omega_{t,y}$", 'Interpreter','latex')
nexttile; hold on; grid on;
plot(simOut.w_target.Time, simOut.w_target.Data(:, 3));
title("$\omega_{t,z}$", 'Interpreter','latex')
% savefig(folder + filesep + "wTarget.fig");

figure; 
tiledlayout(3,1);
nexttile; hold on; grid on;
plot(T_short, (angVel(:, 1) - w_target(:, 1)));%./simOut.w_target.Data(:,1)*100);
% ylim([-200 200])
title("$\omega_{e,x}$", 'Interpreter','latex')
nexttile; hold on; grid on;
plot(T_short, (angVel(:, 2) - w_target(:, 2)));%./simOut.w_target.Data(:,2)*100);
% ylim([-200 200])
title("$\omega_{e,y}$", 'Interpreter','latex')
nexttile; hold on; grid on;
plot(T_short, (angVel(:, 3) - w_target(:, 3)));%./simOut.w_target.Data(:,3)*100);
% ylim([-200 200])
title("$\omega_{e,z}$", 'Interpreter','latex')
% savefig(folder + filesep + "we.fig");

%%

% save(folder + filesep + "data.mat", "toSave", "control", "init")
