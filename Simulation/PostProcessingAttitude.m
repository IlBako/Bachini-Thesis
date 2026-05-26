%% Post - processing

N_short = 1e4;
semiMajAxis = nan(N_short, stochastic.simulationNumber);
ecc = nan(N_short, stochastic.simulationNumber);
posData = nan(N_short, 3, stochastic.simulationNumber);
velData = nan(N_short, 3, stochastic.simulationNumber);
mu = environment.asteroidMu;

for ii = 1:stochastic.simulationNumber
    outData = load("simulationResults\Result_Run_" + sprintf("%04d", ii) + ".mat").simulationOutput;

    if outData.tout(end) == 0
        continue
    end

    T_short = linspace(outData.tout(1), outData.tout(end), N_short);

    posData(:, :, ii) = interp1(outData.SCState.position.Time, outData.SCState.position.Data, T_short); 
    velData(:, :, ii) = interp1(outData.SCState.velocity.Time, outData.SCState.velocity.Data, T_short);

    r = vecnorm(posData(:,:,ii), 2, 2);
    v2 = sum(velData(:,:,ii).^2, 2);

    E = v2/2 - mu./r;
    semiMajAxis(:, ii) = -mu ./ (2*E);

    rdotv = sum(posData(:,:,ii) .* velData(:,:,ii), 2);
    e_vec = ((v2/mu) - 1./r) .* posData(:,:,ii) - (rdotv/mu) .* velData(:,:,ii);
    ecc(:, ii) = vecnorm(e_vec,2,2);
end

%%
plot(T_short, squeeze(ecc));

%%

N_short = 6480;
q_SB_Data = nan(N_short, 4, stochastic.simulationNumber);
controlTau = nan(N_short, 3, stochastic.simulationNumber);

for ii = 1:stochastic.simulationNumber
    outData = load("simulationResults\Result_Run_" + sprintf("%04d", ii) + ".mat").simulationOutput;

    if outData.tout(end) == 0
        continue
    end

    T_short = linspace(outData.tout(1), outData.tout(end), N_short);

    q_SB_Data(:, :, ii) = interp1(outData.SCState.q_SB.Time, outData.SCState.q_SB.Data, T_short);
    controlTau(:,:,ii) = interp1(outData.controlTau.Time, outData.controlTau.Data, T_short);

    if q_SB_Data(end, 1, ii) < 0
        q_SB_Data(:,:,ii) = -q_SB_Data(:,:,ii);
    end
end

%%

% plot(T_short, squeeze(vecnorm(controlTau,2,2)));
plot(T_short, squeeze(q_SB_Data(:, 1, :)));