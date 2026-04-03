clc
%%
burnIdxs = find(vecnorm(simOut.controlAcc.Data,2,2) ~= 0);
burnIdxs = [burnIdxs(1); burnIdxs(find(diff(burnIdxs) ~= 1)+1)];

% For each burn, the ARRIVAL error is measured at the NEXT burn
% (i.e. burn k+1 fires when spacecraft is near waypoint k+1,
%  so the position at burn k+1 start is the arrival from burn k)
n_burns = length(burnIdxs);
eps_k   = nan(n_burns - 1, 1);

for ii = 1:n_burns - 1
    % State at start of burn ii+1 = arrival from burn ii
    arr_idx  = burnIdxs(ii + 1);

    % Waypoint the spacecraft is arriving AT
    % (current_k at arrival is the waypoint being approached,
    %  which is the next waypoint after the one that triggered burn ii)
    curr_wp  = simOut.currentWaypointIdx.Data(arr_idx);

    % Position error at arrival
    r_actual = simOut.SCState.position.Data(arr_idx, :);
    r_ref    = wpData.wp_r(curr_wp, :);
    eps_k(ii) = norm(r_actual - r_ref);
end

fprintf('Mean arrival position error: %.2f m\n', mean(eps_k));
fprintf('Max  arrival position error: %.2f m\n', max(eps_k));
fprintf('Min  arrival position error: %.2f m\n', min(eps_k));

figure;
plot(eps_k, 'b-o');
xlabel('Burn index'); ylabel('Arrival position error [m]');
title('STM linearization error per arc');
grid on;

%%

% Total delta-v per orbit
dv_per_burn = vecnorm(simOut.controlAcc.Data(burnIdxs,:) * 5.0, 2, 2);  % [m/s]
fprintf('Delta-v per burn: mean=%.4f m/s, max=%.4f m/s\n', ...
    mean(dv_per_burn), max(dv_per_burn));
% fprintf('Total delta-v per orbit (~%d burns): %.4f m/s\n', ...
%     wpData.NWaypoints, sum(dv_per_burn(1:wpData.NWaypoints)));

%%

fprintf('Result of trapz over the entire time of %d seconds\n%.4f m/s\n', simOut.controlAcc.Time(end), ...
trapz(simOut.controlAcc.Time, vecnorm(simOut.controlAcc.Data,2,2)));

%%

burnIdxs = find(vecnorm(simOut.controlAcc.Data,2,2) ~= 0);
burnIdxs = [burnIdxs(1); burnIdxs(find(diff(burnIdxs) ~= 1)+1)];

t_sim    = simOut.SCState.position.Time;
dt_arc   = wpData.TRef / wpData.NWaypoints;
n_burns  = length(burnIdxs);
eps_k    = nan(n_burns - 1, 1);

for ii = 1:n_burns - 1
    % Time when burn ii fired
    t_burn_ii = t_sim(burnIdxs(ii));

    % Nominal arrival time = burn time + arc duration
    t_arrival = t_burn_ii + dt_arc;

    % Interpolate actual spacecraft position at nominal arrival time
    r_actual = interp1(t_sim, simOut.SCState.position.Data, t_arrival, 'linear');

    % Next waypoint index
    k_fired   = simOut.currentWaypointIdx.Data(burnIdxs(ii));
    k_next    = mod(k_fired - 1, wpData.NWaypoints) + 1;
    k_next    = mod(k_next, wpData.NWaypoints) + 1;

    % Reference position at next waypoint
    r_ref    = wpData.wp_r(k_next, :);
    eps_k(ii) = norm(r_actual - r_ref);
end

fprintf('Mean STM linearization error: %.2f m\n', mean(eps_k, 'omitnan'));
fprintf('Max  STM linearization error: %.2f m\n', max(eps_k,  [], 'omitnan'));
fprintf('Min  STM linearization error: %.2f m\n', min(eps_k,  [], 'omitnan'));

%%

% Check number of burns detected vs expected
fprintf('Burns detected: %d\n', length(burnIdxs));
fprintf('Expected per orbit (~%d wp): %d\n', wpData.NWaypoints, wpData.NWaypoints);

% Check inter-burn intervals
t_sim    = simOut.controlAcc.Time;
t_burns  = t_sim(burnIdxs);
dt_burns = diff(t_burns);
fprintf('Inter-burn intervals: mean=%.1f s, min=%.1f s, max=%.1f s\n', ...
    mean(dt_burns), min(dt_burns), max(dt_burns));

% Check if any interval is shorter than one arc duration
dt_arc = wpData.TRef / wpData.NWaypoints;
n_short = sum(dt_burns < dt_arc * 0.5);
fprintf('Burns with suspiciously short intervals (<%.0f s): %d\n', ...
    dt_arc*0.5, n_short);

%%

% check dt values at each burn
for ii = 1:length(burnIdxs)
    t_fire_ii  = simOut.controlAcc.Time(burnIdxs(ii));
    k_ii       = simOut.currentWaypointIdx.Data(burnIdxs(ii));
    dt_raw_ii  = mod(t_fire_ii, wpData.TRef) - wpData.wp_t(k_ii);
    dt_ii      = dt_raw_ii;
    if dt_ii > 0.5*wpData.dt_arc
        dt_ii = 0.5*wpData.dt_arc;
    elseif dt_ii < -0.5*wpData.dt_arc
        dt_ii = -0.5*wpData.dt_arc;
    end
    fprintf('Burn %2d | k=%2d | t_fire=%.1f | dt=%.1f s\n', ...
        ii, k_ii, t_fire_ii, dt_ii);
end