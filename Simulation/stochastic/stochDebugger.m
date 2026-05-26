%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             SCRIPT FOR MONTECARLO AND SENSITIVITY DEBUGGING             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; close all; clearvars -except isProjectLoaded
clear parallelSetUpFcn
delete(gcp('nocreate'));
Simulink.sdi.clear;
options.reloadProject = false;
rng("default");

%% Initialization
if ~exist("isProjectLoaded", 'var'), isProjectLoaded = false; end

if ~isProjectLoaded || options.reloadProject
    repoRoot = fileparts(mfilename('fullpath'));
    addpath(genpath("..\Utils"))
    proj = openProject("ARIES.prj");
    isProjectLoaded = true;
end

%% Data loading

% gravDataPath = "..\GravityData\Kleopatra\Kleopatra_100_radial_snap_update.mat";
gravDataPath = "..\GravityData\Bennu\Bennu_100.mat";
% gravDataPath = "..\GravityData\Itokawa\Itokawa_100.mat";
environment = environmentConfig(gravDataPath);
actuators = actuatorsConfig();
[control, spacecraft] = controlConfig(environment.asteroidMu);
init = initConditionConfig(control);
simulation = simulationConfig(control);

%% Montecarlo configuration

stochastic = stochasticConfiguration();
model = stochasticInitializer(stochastic, environment, actuators, control, spacecraft, init, simulation);

%% Debugging Sequence
clearvars -except model isProjectLoaded
set_param('ARIES', 'FastRestart', 'off');

% Workers SetUp Function
parallelSetUpFcn();

% Simulation Initialization Function
simHandle              = stochInitFcn(model(1, 1));

% Simulation Run
model(1,1).PostSimFcn  = [];
model(1,1).PreSimFcn   = [];
simOut                 = sim(model(1,1));

% Simulation Output Function
stochOutFcn(simOut);