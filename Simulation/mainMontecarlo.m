%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             SCRIPT FOR MONTECARLO AND SENSITIVITY ANALYSIS              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; close all; clearvars -except isProjectLoaded
options.reloadProject = false;

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
simulation = simulationConfig();

%% Montecarlo configuration

stochastic = stochasticConfiguration();
model = stochasticInitializer(stochastic, environment, actuators, control, spacecraft, init, simulation);

%% Simulation
tic
simulationOutput = parsim(model, ...
    'ShowSimulationManager', 'on', ...
    'ShowProgress','off', ...
    'UseFastRestart','on', ...
    SetupFcn=@parallelSetUpFcn);
simTime = toc; 

