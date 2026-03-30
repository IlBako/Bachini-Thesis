clc; clearvars; close all;


A = [-1 0 0 0 0 0;
     0 -1 0 0 0 0;
     0 0 -1 0 0 0];
b = [0 0 0];
lb = [110e3 -0.1 -0.1 -100 -100 -100];
ub = [130e3 50e3 50e3 100 100 100];

opts = optimoptions("ga", "Display","iter", "PopulationSize",5, "MaxStallGenerations", 10);

[x,fval,exitflag,output,population,scores] = ga(@fun,6,A,b,[],[],lb,ub,[],opts);

function J = fun(x)
    persistent gravStruct coords
    if isempty(gravStruct)
        load("..\GravityData\Kleopatra\Kleopatra_100_radial_snap_update.mat", "gravStruct", "coords");
    end

    simulationConfig;
    Bus_objects();

    gravAtt = Simulink.Parameter(gravStruct.gravAtt);
    gravAtt.CoderInfo.StorageClass = 'Auto';
    gravAtt.CoderInfo.CustomStorageClass = "Default";

    gravLaplace = Simulink.Parameter(gravStruct.gravLaplace);
    gravLaplace.CoderInfo.StorageClass = 'Auto';
    gravLaplace.CoderInfo.CustomStorageClass = "Default";

    params.mu_sun = 1.32712440017987E+20;
    
    configs.sim.rS0 = x(1:3);
    configs.sim.vS0 = x(4:6);

    simOut = sim("ARIES.slx", 'SimulationMode', 'rapid-accelerator', 'SrcWorkspace', 'current');

    if abs(simOut.time(end) - configs.sim.Tf) > 10
        J = Inf;
        return
    end 
    if simOut.dMin < 1e2
        J = Inf;
        return
    end
    J = abs(simOut.time(end) - configs.sim.Tf)/configs.sim.Tf + norm(x(1:3))/max(abs(x(1:3))) + norm(x(4:6))/max(abs(x(4:6)));
end