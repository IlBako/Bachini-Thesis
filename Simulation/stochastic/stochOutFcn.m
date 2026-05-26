function out = stochOutFcn(simulationOutput)

    baseDir = 'C:\Users\PierFrancescoBachini\Desktop\Bachini-Thesis\Simulation';
    folder = fullfile(baseDir, 'simulationResults');
    logFile = fullfile(baseDir, 'worker_memory_log.txt');

    if ~exist(folder, 'dir'), try mkdir(folder); catch; end; end

    m_start = memory;
    fid = fopen(logFile, 'a');
    fprintf(fid, '--- START POST-SIM | PID %d | RAM: %.2f GB ---\n', ...
            uint32(feature('getpid')), m_start.MemUsedMATLAB/1e9);
    fclose(fid);

    runID = simulationOutput.SimulationMetadata.UserString;
    if isempty(runID)
        runID = sprintf('PID%d_Time_%s', uint32(feature('getpid')), datetime('now', 'Format', 'HHMMSS'));
    end
    fName = fullfile(folder, sprintf('Result_%s.mat', runID));
    save(fName, 'simulationOutput', '-v7.3');

    % environment = load('configData.mat', 'environment').environment;
    wp_r = load("data\bennuWaypoints_orb1.mat").wp_r;
    % mu          = environment.asteroidMu;

    controlAcc = simulationOutput.controlAcc.Data;

    burnIdxs = find(vecnorm(controlAcc,2,2) ~= 0);
    burnIdxs = [burnIdxs(1); burnIdxs(find(diff(burnIdxs) ~= 1)+1)];
    posData = interp1(simulationOutput.SCState.position.Time, simulationOutput.SCState.position.Data, simulationOutput.controlAcc.Time);

    dvTot = trapz(simulationOutput.controlAcc.Time, vecnorm(reshape(controlAcc, [], 3),2,2));
    
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

    % posData = simulationOutput.SCState.position.Data;
    % velData = simulationOutput.SCState.velocity.Data;
    % 
    % r = vecnorm(posData, 2, 2);
    % v2 = sum(velData.^2, 2);
    % 
    % E = v2/2 - mu./r;
    % semiMajAxis = -mu ./ (2*E);
    % 
    % rdotv = sum(posData .* velData, 2);
    % e_vec = ((v2/mu) - 1./r) .* posData - (rdotv/mu) .* velData;
    % ecc = vecnorm(e_vec,2,2);
    % 
    % meanSMA = mean(semiMajAxis, 'omitnan');
    % meanEcc = mean(ecc,         'omitnan');

    %% ── BUILD MINIMAL SimulationOutput ───────────────────────────────────
    % Start from the ORIGINAL object so SimulationMetadata stays valid.
    % Overwrite logsout with a tiny Dataset containing only the two scalars.
    t0 = simulationOutput.SCState.position.Time(1); % use actual start time

    ds = Simulink.SimulationData.Dataset;

    % sigSMA          = Simulink.SimulationData.Signal;
    % sigSMA.Name     = 'meanSemiMajorAxis';
    % sigSMA.Values   = timeseries(meanSMA, t0, 'Name', 'meanSemiMajorAxis');
    % ds              = ds.addElement(sigSMA);
    % 
    % sigEcc          = Simulink.SimulationData.Signal;
    % sigEcc.Name     = 'meanEccentricity';
    % sigEcc.Values   = timeseries(meanEcc, t0, 'Name', 'meanEccentricity');
    % ds              = ds.addElement(sigEcc);

    sigDvTot          = Simulink.SimulationData.Signal;
    sigDvTot.Name     = 'totalDv';
    sigDvTot.Values   = timeseries(dvTot, t0, 'Name', 'dvTot');
    ds                = ds.addElement(sigDvTot);

    sigMeanEpsK       = Simulink.SimulationData.Signal;
    sigMeanEpsK.Name  = 'meanArrivalPositionError';
    sigMeanEpsK.Values= timeseries(mean(eps_k), t0, 'Name', 'meanEpsK');
    ds                = ds.addElement(sigMeanEpsK);

    % Replace logsout with the tiny dataset and drop everything else heavy
    keepFields = {'SimulationMetadata', 'ErrorMessage'};
    props  = who(simulationOutput);
    props = props(~ismember(props, keepFields));

    out= removeProperty(simulationOutput, props);

    % out = simulationOutput;
    out.logsout = ds;
    % out = out.setUserString(fName);

    clearvars -except out logFile

    java.lang.System.gc();

    m_end = memory;
    fid = fopen(logFile, 'a');
    fprintf(fid, '--- FINISHED & PURGED | PID %d | RAM: %.2f GB ---\n', ...
            uint32(feature('getpid')), m_end.MemUsedMATLAB/1e9);
    fclose(fid);
end