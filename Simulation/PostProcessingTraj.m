clc; close all

N_short = 2e4;
wp_r = load("data\bennuWaypoints_orb1.mat").wp_r;
posData = nan(N_short, 3, stochastic.simulationNumber);
dvData = nan(stochastic.simulationNumber, 1);
epsK = nan(stochastic.simulationNumber, 1);

dvMean = nan(stochastic.simulationNumber,1);
dvStd = nan(stochastic.simulationNumber, 1);
epsKMean = nan(stochastic.simulationNumber, 1);
epsKStd = nan(stochastic.simulationNumber, 1);

f = figure; hold on; view(33,11);
axis equal; grid on;
xlabel("X [m]"); ylabel("Y [m]"); zlabel("Z [m]");
meshData = environment.asteroidData.mesh;
drawMesh(meshData);

for ii = 1:stochastic.simulationNumber
    outData = load("simulationResults\Result_Run_" + sprintf("%04d", ii) + ".mat").simulationOutput;

    if outData.tout(end) == 0
        continue
    end

    % T_short = linspace(outData.tout(1), outData.tout(end)/16, N_short);
    % 
    % posData(:, :, ii) = interp1(outData.SCState.position.Time, outData.SCState.position.Data, T_short);

    idx = sum(outData.SCState.position.Time <= str2num(simulation.simulationTime)/20);
    posData(1:idx,:,ii) = outData.SCState.position.Data(1:idx, :);
    dvData(ii) = trapz(outData.controlAcc.Time, vecnorm(outData.controlAcc.Data,2,2));
    epsK(ii) = computeMeanEpsK(outData, wp_r);

    dvMean(ii) = mean(dvData(1:ii));
    dvStd(ii) = std(dvData(1:ii));
    epsKMean(ii) = mean(epsK(1:ii));
    epsKStd(ii) = std(epsK(1:ii));

    plot3(posData(:,1, ii), posData(:,2,ii), posData(:,3,ii), 'LineWidth', 1, 'DisplayName', 'Trajectory');
end

%%

figure; hold on; grid on;
subplot(2,1,1)
plot(1:stochastic.simulationNumber, dvMean)
subplot(2,1,2)
plot(1:stochastic.simulationNumber, dvStd)

figure; hold on; grid on;
subplot(2,1,1)
plot(1:stochastic.simulationNumber, epsKMean)
subplot(2,1,2)
plot(1:stochastic.simulationNumber, epsKStd)

%%

function [meanEpsK, eps_k] = computeMeanEpsK(simulationOutput, wp_r)

    controlAcc = simulationOutput.controlAcc.Data;

    burnIdxs = find(vecnorm(controlAcc,2,2) ~= 0);
    burnIdxs = [burnIdxs(1); burnIdxs(find(diff(burnIdxs) ~= 1)+1)];
    posData = interp1(simulationOutput.SCState.position.Time, simulationOutput.SCState.position.Data, simulationOutput.controlAcc.Time);
    
    nBurns = length(burnIdxs);
    eps_k   = nan(nBurns - 1, 1);

    for ii = 1:nBurns - 1
        % State at start of burn ii+1 = arrival from burn ii
        arrivalIdx  = burnIdxs(ii + 1);

        % Waypoint the spacecraft is arriving AT
        % (current_k at arrival is the waypoint being approached,
        %  which is the next waypoint after the one that triggered burn ii)
        currWp  = simulationOutput.currentWaypointIdx.Data(arrivalIdx);

        % Position error at arrival
        rActual = posData(arrivalIdx, :);
        rWp     = wp_r(currWp, :);
        eps_k(ii) = norm(rActual - rWp);
    end

    meanEpsK = mean(eps_k);
end