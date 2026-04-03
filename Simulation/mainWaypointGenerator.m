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

%% General parameters
tolPos = 1;
tolVel = 1e-3;
NWaypoints = 25;

% Reference orbit
kepEls.a = 350;
kepEls.e = 0;
kepEls.i = deg2rad(90);
kepEls.OM = deg2rad(0);
kepEls.om = deg2rad(0);
kepEls.theta = 0;

saveFile = "data/bennuWaypoints.mat";

%% Data loading

% gravDataPath = "..\GravityData\Kleopatra\Kleopatra_100_radial_snap_update.mat";
gravDataPath = "..\GravityData\Bennu\Bennu_100.mat";
% gravDataPath = "..\GravityData\Itokawa\Itokawa_100.mat";
environment = environmentConfig(gravDataPath, true);
[init,TSim] = initConditionWaypointsConfig(kepEls, environment.asteroidMu, environment.asteroidAngularVelocity);

modelName = 'STM_Propagator';
load_system(modelName);
set_param(modelName, ... ...
    'FixedStep', '1e-1', ...
    'SolverType', 'fixed-step', ...
    'Solver', 'ode4', ...
    'SimulationMode', 'accelerator', ...
    'FastRestart', 'on');
model = Simulink.SimulationInput(modelName);
model = model.setVariable('environment', environment);
model = model.setVariable('init', init);
model = model.setVariable('TSim', TSim);
createBVHObjects(modelName, environment.asteroidData.BVH);

gravAtt = Simulink.Parameter(environment.gravStruct.gravAtt);
gravAtt.CoderInfo.StorageClass = 'Auto';
gravAtt.CoderInfo.CustomStorageClass = "Default";

gravLaplace = Simulink.Parameter(environment.gravStruct.gravLaplace);
gravLaplace.CoderInfo.StorageClass = 'Auto';
gravLaplace.CoderInfo.CustomStorageClass = "Default";

gravGrad = zeroTraceNormalization(environment.gravStruct.gravGrad);
gravGrad = Simulink.Parameter(gravGrad);
gravGrad.CoderInfo.StorageClass = 'Auto';
gravGrad.CoderInfo.CustomStorageClass = "Default";

%% Run once for result analysis
tic
simOut = sim(model); 
toc

x_F = simOut.SCStateFinal(1:6)';
Phi_F = reshape(simOut.SCStateFinal(7:42), [6 6]);
f_F = simOut.dYFinal(:);
traj.time = simOut.SCState.position.Time;
traj.position = simOut.SCState.position.Data;

% Periodicity residual
x0Init = [init.scPosition init.scVelocity];
x0Err = reshape(x_F, [1 6]) - x0Init;

x0posErr = norm(x0Err(1:3));
x0velErr = norm(x0Err(4:6));

% STM correctness
detPhi = det(Phi_F);
condPhi = cond(Phi_F);

% Print results
fprintf('    Initial position residual : %.4e m\n',   x0posErr);
fprintf('    Initial velocity residual : %.4e m/s\n', x0velErr);
fprintf('    det(Phi_T)                : %.6f  (ideal: 1.0)\n', detPhi);
fprintf('    cond(Phi_T)               : %.4e\n\n',   condPhi);

% Plot trajectory
figure('Name', sprintf('Initial guess trajectory'));
plot3(traj.position(:,1), traj.position(:,2), traj.position(:,3), 'b-', 'LineWidth', 1.5);
hold on;
plot3(x0Init(1), x0Init(2), x0Init(3), ...
      'go', 'MarkerSize', 10, 'DisplayName', 'Start');
plot3(x_F(1), x_F(2), x_F(3), ...
      'rs', 'MarkerSize', 10, 'DisplayName', 'End (after T_{guess})');
drawMesh(environment.asteroidData.mesh);
axis equal; grid on;
xlabel('x [m]'); ylabel('y [m]'); zlabel('z [m]');
title(sprintf('Initial guess trajectory (body-fixed frame)'));
legend('Trajectory', 'Start', 'End');
drawnow;


%% Run differential correction

[x0Dc, TSimDc, DcConverged, DcResidualHistory] = differentialCorrection(init, TSim, model, tolPos, tolVel, 50);

if size(DcResidualHistory, 1) > 1
    figure('Name', sprintf('DC convergence'));
    semilogy(DcResidualHistory(:,1), 'b-o', 'DisplayName', 'Position error [m]');
    hold on;
    semilogy(DcResidualHistory(:,2), 'r-o', 'DisplayName', 'Velocity error [m/s]');
    yline(tolPos, 'b--', 'DisplayName', 'Pos tolerance');
    yline(tolVel, 'r--', 'DisplayName', 'Vel tolerance');
    xlabel('Iteration'); ylabel('Residual');
    title(sprintf('Differential correction convergence'));
    legend; grid on;
    drawnow;
end

%% Select reference orbit

if DcConverged
    fprintf('    Differential correction CONVERGED.\n');
    fprintf('    Using corrected periodic orbit as reference.\n');
    fprintf('    x0_ref = [%.4f, %.4f, %.4f] m\n',   x0Dc(1:3));
    fprintf('    v0_ref = [%.6f, %.6f, %.6f] m/s\n', x0Dc(4:6));
    fprintf('    T_ref  = %.4f s (%.4f h)\n\n', TSimDc, TSimDc/3600);

    x0Ref  = x0Dc;
    TRef   = TSimDc;
    ref_type = 'differential_correction';
else
    fprintf('    Differential correction DID NOT converge.\n');
    fprintf('    Falling back to Keplerian reference.\n');
    fprintf('    x0_ref = [%.4f, %.4f, %.4f] m\n',   x0Init(1:3));
    fprintf('    v0_ref = [%.6f, %.6f, %.6f] m/s\n', x0Init(4:6));
    fprintf('    T_ref  = %.4f s (%.4f h)\n\n', TSim, TSim/3600);

    x0Ref  = x0Init;
    TRef   = TSim;
    ref_type = 'keplerian_fallback';
end

%% Sample waypoints

thetaVec = linspace(0, 2*pi, NWaypoints + 1);
thetaVec = thetaVec(1:end-1);

wp_r = zeros(NWaypoints, 3);
wp_v = zeros(NWaypoints, 3);

if DcConverged
    % Propagate corrected orbit and interpolate at equal time intervals
    init.scPosition = x0Ref(1:3);
    init.scVelocity = x0Ref(4:6);
    model = model.setVariable('init', init);
    model = model.setVariable('TSim',  TRef);
    simOutRef = sim(model);

    trajRef.time = simOutRef.SCState.position.Time;
    trajRef.position = simOutRef.SCState.position.Data;
    dt_arc = TRef / NWaypoints;
    t_wp   = (0:NWaypoints-1)' * dt_arc;

    for ii = 1:NWaypoints
        state_k    = interp1(trajRef.time, trajRef.position, t_wp(ii), 'linear');
        wp_r(ii,:)  = state_k(1:3);
        wp_v(ii,:)  = state_k(4:6);
    end
else
    % Sample Keplerian orbit directly at equal true anomaly spacing
    for ii = 1:NWaypoints
        [r_BF, v_BF] = kep2car(kepEls.a, kepEls.e, kepEls.i, ...
                                     kepEls.OM, kepEls.om, thetaVec(ii), environment.asteroidMu);
        v_BF = v_BF - cross(environment.asteroidAngularVelocity, r_BF);
        wp_r(ii,:) = r_BF';
        wp_v(ii,:) = v_BF';
    end
end

%% Validate waypoints
% Propagate STM over the arcs and check its drift

dt_arc   = TRef/NWaypoints;
A_arcs = zeros(6,6,NWaypoints);
Phi_arcs = zeros(6, 6, NWaypoints);
drift_pos = zeros(NWaypoints, 1);
drift_vel = zeros(NWaypoints, 1);
cond_Phi_rv = zeros(NWaypoints, 1);

wp_t = (0 : NWaypoints-1)' * dt_arc;

for k = 1:NWaypoints
    init.scPosition = wp_r(k,:); 
    init.scVelocity = wp_v(k,:)';
    k_next  = mod(k, NWaypoints) + 1;

    % Propagate arc under true EOM
    [x_end, Phi_k, ~, A_k] = STMPropagationRunner(model, init, dt_arc);
    Phi_arcs(:,:,k)   = Phi_k;
    cond_Phi_rv(k)    = cond(Phi_k(1:3, 4:6));
    A_arcs(:,:,k)     = A_k;

    % Natural drift to next reference waypoint
    x_next_ref  = [wp_r(k_next,:)'; wp_v(k_next,:)'];
    drift_pos(k) = norm(x_end(1:3) - x_next_ref(1:3));
    drift_vel(k) = norm(x_end(4:6) - x_next_ref(4:6));

    fprintf('    Arc %2d/%2d | cond(Phi_rv)=%8.2e | drift: pos=%7.2f m, vel=%.4f m/s\n', ...
        k, NWaypoints, cond_Phi_rv(k), drift_pos(k), drift_vel(k));
end

fprintf('\n    Max position drift : %.2f m\n',   max(drift_pos));
fprintf('    Max velocity drift : %.4f m/s\n',   max(drift_vel));
fprintf('    Max cond(Phi_rv)   : %.2e\n\n',     max(cond_Phi_rv));

%% Plot final waypoints

figure('Name', sprintf('Final waypoints'));
hold on; grid on; view(20,30); axis equal;
drawMesh(environment.asteroidData.mesh);
plot3(wp_r(:,1), wp_r(:,2), wp_r(:,3), 'bo', ...
      'LineWidth', 1.5, 'MarkerSize', 8, 'MarkerFaceColor', 'b');
plot3(wp_r(1,1), wp_r(1,2), wp_r(1,3), ...
      'go', 'MarkerSize', 12, 'MarkerFaceColor', 'g', 'DisplayName', 'WP 1');
% Close the orbit visually
wp_r_closed = [wp_r; wp_r(1,:)];
plot3(wp_r_closed(:,1), wp_r_closed(:,2), wp_r_closed(:,3), 'b-');
xlabel('x [m]'); ylabel('y [m]'); zlabel('z [m]');
title(sprintf('Reference waypoints (%s)', strrep(ref_type,'_',' ')));
legend("Waypoints", 'Starting position');
drawnow;

%% Save waypoints

fprintf('Saving to %s...\n', saveFile);

save(saveFile, ...
    'wp_r',        ...   % Nx3  waypoint positions [m]
    'wp_v',        ...   % Nx3  waypoint velocities [m/s]
    'wp_t',        ...   % Nx1  waypoint time [s]
    'Phi_arcs',    ...   % 6x6xN arc STMs
    'A_arcs',      ...   % A mat at start of each arc
    'TRef',        ...   % reference orbit period [s]
    'dt_arc',      ...   % arc duration [s]
    'x0Ref',       ...   % 6x1 reference initial state
    'drift_pos',   ...   % Nx1 natural position drift per arc [m]
    'drift_vel',   ...   % Nx1 natural velocity drift per arc [m/s]
    'cond_Phi_rv', ...   % Nx1 condition number of Phi_rv per arc
    'ref_type',    ...   % string: 'differential_correction' or 'keplerian_fallback'
    'NWaypoints', ...
    'kepEls');

fprintf('    Saved. Reference type: %s\n\n', strrep(ref_type,'_',' '));

%% Helper fcns

function gravGrad = zeroTraceNormalization(gravGrad)
    for i = 1:size(gravGrad,1)
        for j = 1:size(gravGrad,2)
            for k = 1:size(gravGrad,3)
                % Force Symmetry
                M = squeeze(gravGrad(i,j,k,:,:));
                M = 0.5 * (M + M');

                gravGrad(i,j,k,:,:) = M;
            end
        end
    end
end
