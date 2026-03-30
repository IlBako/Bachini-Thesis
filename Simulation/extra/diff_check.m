clc; close all

SC_pos = simOut.SCState.position.Data;
SC_acc = simOut.Accelerations.SC_lin.Data;
time = simOut.Accelerations.SC_lin.Time;
gravAttNorm = gravInterpDict("attraction norm");
gravAttNorm.ExtrapolationMethod = "nearest";

att_norm = nan(size(SC_pos,1),1);
att_diff = nan(size(SC_pos,1),1);

for ii = 1:size(SC_pos, 1)
    [radius, polar, azimuth] = cart2Sphere(SC_pos(ii, :));
    att_norm(ii) = squeeze(gravAttNorm(radius, polar, azimuth));
    att_diff(ii) = norm(SC_acc(ii, :)) - att_norm(ii);
end

figure; hold on; grid on;
plot(time, vecnorm(SC_acc,2,2), 'LineWidth', 1);
plot(time, att_norm, 'LineWidth', 1);
% yyaxis right
% plot(time, att_diff)
