rr = simOut.rrLog.Data;

dt_mult = 0.5;

f = figure; hold on; view(0,90);
axis equal; grid on;
xlabel("X [m]"); ylabel("Y [m]"); zlabel("Z [m]");
xlim([-500 500]); ylim([-500 500]); zlim([-300 450]);
meshData = environment.asteroidData.mesh;
drawMesh(meshData);
plot3(simOut.SCState.position.Data(:,1), simOut.SCState.position.Data(:,2), simOut.SCState.position.Data(:,3), 'LineWidth', 1, 'DisplayName', 'Trajectory');

% agArrow = squeeze(ag(:,4,:,:)); % 75x3xN if ag is 75x4x3xN
% accScale = 2; % adjust this factor to make acceleration arrows visible

[sp.X, sp.Y, sp.Z] = sphere;

wpData = load(waypointsPath);
dt_arc = wpData.dt_arc;
for ii = 1:wpData.NWaypoints
    if ii == 1
        s = scatter3(wpData.wp_r(ii,1), wpData.wp_r(ii, 2), wpData.wp_r(ii,3), 50, 'm', 'filled', 'DisplayName', 'Waypoints');
    else
        s = scatter3(wpData.wp_r(ii,1), wpData.wp_r(ii, 2), wpData.wp_r(ii,3), 50, 'm', 'filled', 'HandleVisibility', 'off');
    end
    dtRow = dataTipTextRow("idx",ii);
    s.DataTipTemplate.DataTipRows(end+1) = dtRow;
    mesh(sp.X*control.waypoints.proxRadius+wpData.wp_r(ii, 1), sp.Y*control.waypoints.proxRadius+wpData.wp_r(ii, 2), sp.Z*control.waypoints.proxRadius+wpData.wp_r(ii, 3), 'EdgeColor', 'none', 'FaceColor', 'cyan', 'FaceAlpha', 0.25, 'HandleVisibility', 'off');
end
burnIdxs = find(vecnorm(simOut.controlAcc.Data,2,2) ~= 0);
burnIdxs = [burnIdxs(1); burnIdxs(find(diff(burnIdxs) ~= 1)+1)];
trajTime = simOut.SCState.position.Time;
posData = simOut.SCState.position.Data;
for ii = 1:length(burnIdxs)
    startIdx = burnIdxs(ii);
    if ii < length(burnIdxs)
        nextStartIdx = burnIdxs(ii+1);
    else
        nextStartIdx = size(posData,1);
    end

    t0 = trajTime(startIdx);
    if isdatetime(t0) || isduration(t0)
        tTarget = t0 + seconds(dt_mult*dt_arc);
    else
        tTarget = t0 + dt_mult*dt_arc;
    end

    legIdx = startIdx:nextStartIdx;
    idxHighlightEnd = find(trajTime(legIdx) <= tTarget, 1, 'last');
    if isempty(idxHighlightEnd)
        idxHighlightEnd = 1;
    end
    highlightIdx = legIdx(1:idxHighlightEnd);

    if ii == 1
        s = scatter3(posData(startIdx,1), posData(startIdx,2), posData(startIdx,3), 'k', 'filled', 'DisplayName', 'Maneuvers');
    else
        s = scatter3(posData(startIdx,1), posData(startIdx,2), posData(startIdx,3), 'k', 'filled', 'HandleVisibility','off');
    end
    dtRow = dataTipTextRow("currentWaypointIdx",simOut.currentWaypointIdx.Data(burnIdxs(ii)));
    s.DataTipTemplate.DataTipRows(end+1) = dtRow;

    if ii == 1
        % plot3(posData(highlightIdx,1), posData(highlightIdx,2), posData(highlightIdx,3), 'r-', 'LineWidth', 2.5, 'DisplayName', 'Half-arc subtrajectory');
        plot3(rr(:,1, burnIdxs(ii)), rr(:,2, burnIdxs(ii)), rr(:,3, burnIdxs(ii)), 'm--', 'LineWidth', 2, 'DisplayName', 'Propagated trajectory');
    else
        % plot3(posData(highlightIdx,1), posData(highlightIdx,2), posData(highlightIdx,3), 'r-', 'LineWidth', 2.5, 'HandleVisibility','off');
        plot3(rr(:,1, burnIdxs(ii)), rr(:,2, burnIdxs(ii)), rr(:,3, burnIdxs(ii)), 'm--', 'LineWidth', 2, 'HandleVisibility', 'off');
    end
    % quiver3(rr(:,1,burnIdxs(ii)), rr(:,2,burnIdxs(ii)), rr(:,3,burnIdxs(ii)), ...
    %     agArrow(:,1,burnIdxs(ii)), agArrow(:,2,burnIdxs(ii)), agArrow(:,3,burnIdxs(ii)), ...
    %     'AutoScale','on','AutoScaleFactor',accScale, ...
    %     'Color', [0 0.5 0], 'LineWidth', 1.5, 'MaxHeadSize', 0.8, 'HandleVisibility', 'off');
end

% scatter3(simOut.SCState.position.Data(end,1), simOut.SCState.position.Data(end,2), simOut.SCState.position.Data(end,3), 25, 'r', 'filled', 'DisplayName', "End position");
% scatter3(simOut.SCState.position.Data(1,1), simOut.SCState.position.Data(1,2), simOut.SCState.position.Data(1,3), 25, 'g', 'filled', 'DisplayName', "Start position");

legend('Interpreter', 'latex', 'Location', 'northeast');

%% Compare with rerun

rr2 = simOut.rr2Log.Data;
allBurnIdxs = find(vecnorm(simOut.controlAcc.Data,2,2) ~= 0);
burnEndIdxs = [allBurnIdxs(diff(allBurnIdxs) ~= 1)+1; allBurnIdxs(end)];

params.mesh = environment.asteroidData.mesh;
params.density = environment.asteroidData.density;
params.angVel = [0;0;4.0684e-4]; % BENNU
odeOpts = odeset('RelTol', 1e-6, 'AbsTol', 1e-9);

for ii = 1:length(burnEndIdxs)
    rTraj2 = rr2(all(rr2(:,:, burnEndIdxs(ii)) ~= 0, 2), :, burnEndIdxs(ii));

    % Y0 = [posData(burnEndIdxs(ii), :)'; simOut.SCState.velocity.Data(burnEndIdxs(ii), :)'];
    % % Y0 = [posData(burnIdxs(1), :)'; simOut.SCState.velocity.Data(burnIdxs(1), :)'+ reshape(squeeze(simOut.dvCmdLog.Data(:,:,burnIdxs(1))),3,[])];
    % tspan = linspace(trajTime(burnEndIdxs(ii)), trajTime(burnEndIdxs(ii))+dt_arc, 200);
    % 
    % [T, Y] = ode45(@(t, y) odeFcn(t, y, params), tspan, Y0(:), odeOpts);
    % 
    % err = squeeze(rr2(:, :, burnEndIdxs(1))) - Y(:, 1:3);
    
    if ii == 1
        % p = plot3(Y(:,1), Y(:,2), Y(:,3), 'k--', 'LineWidth', 2, 'DisplayName', 'rerun');
        p2 = plot3(rTraj2(:,1), rTraj2(:,2), rTraj2(:,3), 'g', 'LineWidth', 4, 'DisplayName', '2nd Propagated trajectory');
    else
        % p = plot3(Y(:,1), Y(:,2), Y(:,3), 'k--', 'LineWidth', 2, 'HandleVisibility', 'off');
        p2 = plot3(rTraj2(:,1), rTraj2(:,2), rTraj2(:,3), 'g', 'LineWidth', 4, 'HandleVisibility', 'off');
    end
end

function dY = odeFcn(~, Y, params)
    r = Y(1:3);
    v = Y(4:6);

    [~, gravAcc] = gravitationalModel(params.mesh, r, params.density);

    dY = zeros(6, 1);
    dY(1:3) = v;
    dY(4:6) = gravAcc - 2*cross(params.angVel, v) - cross(params.angVel, cross(params.angVel, r));
end

