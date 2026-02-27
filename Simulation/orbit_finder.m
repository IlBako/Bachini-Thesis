%%% Orbit finder

clc; clearvars; close all;
addpath(genpath("..\Utils"))
addpath("configs\");
addpath("Subsystems\");

%% Load configs

gravDataPath = "..\GravityData\Bennu\Bennu_100.mat";
environment = environmentConfig(gravDataPath);
[control, spacecraft] = controlConfig(environment.asteroidMu);
init = initConditionConfig(control);
simulation = simulationConfig();

%% Minimization
if false
% fmincon constraints for simple shooting
A = [0 0 -1];
b = [0];
Aeq = [];
beq = [];
lb = [-0 -0 50];
ub = [0 0 500];
nonlcon = [];

% fmincon options - Algorithm switched to active-set to speed up minimization, 
% tollerances set to 1e-9 as lower values lead to problems with numerical approximations
options = optimoptions("fmincon", "Display","iter-detailed", "Algorithm", "active-set", "MaxIterations", 250, "MaxFunctionEvaluations", 5000, ...
    "ConstraintTolerance", 1e-9, "FunctionTolerance", 1e-9);

tic
[x_sol,fval_sol] = fmincon(@(X) minPeriodError(X, configs, gravInterpDict), [configs.sim.vS0'], A, b, Aeq, beq, lb, ub, nonlcon, options);
time_fmincon = toc;
end
%% Plot found orbit

warning("Rimuovere override di x_sol!");
x_sol = init.asteroidVelocity';
Y0 = [init.asteroidPosition'; x_sol];
opts = odeset('reltol', 1e-12, 'abstol', 1e-12, 'Events', @(t,y) multiEvent(t, y, environment.gravInterpDict("laplacian")));
[T, Y] = ode113(@(t,y) odeFcn(t, y, environment, environment.gravInterpDict("attraction")), [0 str2double(simulation.simulationTime)], Y0, opts);

figure; hold on; grid on; axis equal; view(20,30);
meshData = environment.asteroidData.mesh;
meshData.vertexList = meshData.vertexList./1e3;
drawMesh(meshData);
plot3(Y(:,1)/1e3, Y(:,2)/1e3, Y(:,3)/1e3, 'LineWidth', 1.5);
scatter3(Y(end,1)/1e3, Y(end,2)/1e3, Y(end,3)/1e3, 50, 'r', 'filled')
xlabel("X [m]"); ylabel("Y [m]"); zlabel("Z [m]");

%% Fmincon fcns

function J = minPeriodError(v0, configs, gravInterpDict)
    
    Y0 = [configs.sim.rS0(:); v0(:)];
    R_scale = 1e5;
    v_scale = 1e2;
    R_weight = 1;
    v_weight = 1e3;

    opts = odeset('reltol', 1e-12, 'abstol', 1e-12, 'Events', @(t,y) multiEvent(t, y, gravInterpDict("laplacian")));
    [T, Y, te, ye, ie] = ode113(@(t,y) odeFcn(t, y, configs, gravInterpDict("attraction")), [0 configs.sim.Tf], Y0, opts);
    if any(ismember(ie,2)) % || norm(Y(end,1:3)) - norm(Y0(1:3)) > 20e3  % event 2 = asteroid collision
        penalty = 1e6;       % large finite cost
    else
        penalty = 0;
    end
    err(1:3) = (Y(end, 1:3)' - Y0(1:3))./R_scale;
    err(4:6) = (Y(end, 4:6)' - Y0(4:6))./v_scale;
    J = norm(err)+penalty;
end

%% ODE FCN

function dY = odeFcn(~, Y, environment, gravInterp)
    r = Y(1:3);
    v = Y(4:6);

    wb = environment.asteroidAngularVelocity(:);

    % Accelerations
    [R, polar, azimuth] = cart2Sphere(r);
    acc_g = squeeze(gravInterp(R, polar, azimuth));
    coriolis = -2*cross(wb, v);
    centrifugal = -cross(wb, cross(wb, r));

    
    dY = zeros(6,1);
    dY(1:3) = v;
    dY(4:6) = acc_g + coriolis + centrifugal;

end

% Event function

function [value, isterminal, direction] = multiEvent(~, xx, laplaceInterp)
    % --- Plane crossing (y=0, vy>0) ---
    value(1) = xx(3);               % y-coordinate
    direction(1) = -1;               % only positive slope crossings
    isterminal(1) = (xx(6) < 0);    % stop integration if vy>0 (for shooting)

    % --- Asteroid intersection using binary Laplacian ---
    [R, polar, azimuth] = cart2Sphere(xx(1:3));
    value(2) = abs(laplaceInterp(R, polar, azimuth)-4*pi) > 1e-3;   % zero crossing occurs when lapVal = 4*pi (inside)
    direction(2) = 0;                                               % detect any crossing
    isterminal(2) = 1;                                              % stop integration on collision
end