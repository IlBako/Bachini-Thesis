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

    environment = load('configData.mat', 'environment').environment;
    mu          = environment.asteroidMu;

    posData = simulationOutput.SCState.position.Data; 
    velData = simulationOutput.SCState.velocity.Data; 

    r = vecnorm(posData, 2, 2);
    v2 = sum(velData.^2, 2);

    E = v2/2 - mu./r;
    semiMajAxis = -mu ./ (2*E);

    rdotv = sum(posData .* velData, 2);
    e_vec = ((v2/mu) - 1./r) .* posData - (rdotv/mu) .* velData;
    ecc = vecnorm(e_vec,2,2);

    meanSMA = mean(semiMajAxis, 'omitnan');
    meanEcc = mean(ecc,         'omitnan');

    %% ── BUILD MINIMAL SimulationOutput ───────────────────────────────────
    % Start from the ORIGINAL object so SimulationMetadata stays valid.
    % Overwrite logsout with a tiny Dataset containing only the two scalars.
    t0 = simulationOutput.SCState.position.Time(1); % use actual start time

    ds = Simulink.SimulationData.Dataset;

    sigSMA          = Simulink.SimulationData.Signal;
    sigSMA.Name     = 'meanSemiMajorAxis';
    sigSMA.Values   = timeseries(meanSMA, t0, 'Name', 'meanSemiMajorAxis');
    ds              = ds.addElement(sigSMA);

    sigEcc          = Simulink.SimulationData.Signal;
    sigEcc.Name     = 'meanEccentricity';
    sigEcc.Values   = timeseries(meanEcc, t0, 'Name', 'meanEccentricity');
    ds              = ds.addElement(sigEcc);

    % Replace logsout with the tiny dataset and drop everything else heavy
    % keepFields = {'SCState','SimulationMetadata', 'ErrorMessage'};
    % props  = who(simulationOutput);
    % props = props(~ismember(props, keepFields));

    % out= removeProperty(simulationOutput, props);

    out = simulationOutput;
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