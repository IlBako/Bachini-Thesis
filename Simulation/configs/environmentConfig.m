function environment = environmentConfig(gravDataPath)

%% Gravitational model
environment.gravLaplaceTol                  = 1e-6; % Tollerance of the error on laplacian calculation

%% Sun parameter
environment.mu_sun = 1.32712440017987E+20;

%% Asteroid
environment.asteroidAngularVelocity = [0;0;4.0684e-4]; % BENNU
% environment.asteroidAngularVelocity = [0;0;3.3118e-4]; % KLEOPATRA

gravData = load(gravDataPath);

if ~isfield(gravData.asteroidData, 'BVH') || isempty(gravData.asteroidData.BVH)
    gravData.asteroidData.BVH = buildBVH(gravData.asteroidData.mesh, 8);
end

environment.asteroidData = gravData.asteroidData;
environment.asteroidMu = 6.67430*1e-11*gravData.asteroidData.mass;
environment.asteroidCoords = gravData.coords;
environment.gravStruct = rmfield(gravData.gravStruct, {'gravGrad', 'gravPot', 'gravAttNorm'});
% environment.gravInterpDict = gravData.gravInterpDict;

if ~isfield(environment.asteroidCoords, 'radius')
    environment.asteroidCoords.radius = environment.asteroidCoords.R;
    environment.asteroidCoords.polar = environment.asteroidCoords.theta;
    environment.asteroidCoords.azimuth = environment.asteroidCoords.phi;
end

end