% Main script to run the ARIES simulator
% (ARIES: Asteroid-centered Relative Inertial and Environmental Simulator)

clc; clearvars; close all;
addpath(genpath("..\Utils"))
addpath("configs\");
addpath("Subsystems\");

%% Load data

load("..\GravityData\Kleopatra\Kleopatra_100_radial_snap_update.mat");

if ~isfield(asteroidData, 'BVH') || isempty(asteroidData.BVH)
    asteroidData.BVH = buildBVH(asteroidData.mesh, 8);
end

%% Load configs

simulationConfig;
Bus_objects();

%% Run simulation

gravAtt = Simulink.Parameter(gravStruct.gravAtt);
gravAtt.CoderInfo.StorageClass = 'Auto';
gravAtt.CoderInfo.CustomStorageClass = "Default";

gravLaplace = Simulink.Parameter(gravStruct.gravLaplace);
gravLaplace.CoderInfo.StorageClass = 'Auto';
gravLaplace.CoderInfo.CustomStorageClass = "Default";

params.R_A = asteroidData.De/2;
params.mu_sun = 1.32712440017987E+20;

modelName = "ARIES";
if ~bdIsLoaded(modelName)
    load_system(modelName);
end

createBVHObjects(modelName, asteroidData.BVH);
%%

tic
simOut = sim(modelName, 'SimulationMode', 'rapid-accelerator');
toc
% tic
% simOut = sim(modelName,'SimulationMode','normal');
% toc
return
% if simOut.time(end) < configs.sim.Tf
%     disp("Simulation finished early!");
% end
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

%% Plot results
if false
figure; hold on; view(20,30);
axis equal; grid on;
xlabel("X [m]"); ylabel("Y [m]"); zlabel("Z [m]");
meshData = asteroidData.mesh;
meshData.vertexList = meshData.vertexList./1e3;
drawMesh(meshData);
plot3(simOut.SCState.position.Data(:,1)/1e3, simOut.SCState.position.Data(:,2)/1e3, simOut.SCState.position.Data(:,3)/1e3, 'LineWidth', 1);
% scatter3(simOut.SCState.position.Data(end,1)/1e3, simOut.SCState.position.Data(end,2)/1e3, simOut.SCState.position.Data(end,3)/1e3, 50, 'r', 'filled');
end
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

return

%%
figure; hold on; grid on;
% plot(simOut.gravAttraction.Time, vecnorm(simOut.gravAttraction.Data,2,2));
plot(simOut.TBPAcc.Time, vecnorm(simOut.TBPAcc.Data,2,2));
plot(simOut.SRPTau.Time(simOut.illuminated.Data), vecnorm(simOut.SRPTau.Data(simOut.illuminated.Data,:),2,2));
% plot(simOut.SRPAcc.Time, vecnorm(simOut.SRPAcc.Data,2,2));

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
