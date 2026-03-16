function parameters = createParameter(name, distrType, A, B, n, parameters)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%            FUNCTION FOR DISTRIBUTION PARAMETER COMPUTATION              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

arguments
    name         
    distrType   {mustBeInRange(distrType, 1, 8)}
    A           {mustBeReal}
    B           {mustBeReal}
    n           {mustBeInteger, mustBePositive}
    parameters  struct      = []
end

% distrType,   int: input format and distribution type
%                 - 1: uniform, A [min]; B [max]
%                               val > A; val < B
% 
%                 - 2: uniform, A [% min]; B [% max]
%                               val > A*v0 ; val < B*v0  (v0: nominal value)  
% 
%                 - 3: uniform, A [delta Min]; B [delta Max]
%                               val > v0 + A; val < v0 + B
% 
%                 - 4: uniform, A [delta% min]; B [delta% max]
%                               val > (1 + A)*v0; val < (1 + B)*v0
% 
%                 - 5: gaussian, A [average]; B [standard deviation]
%                                mu = A; STD = B;  
%                                val = randn 
% 
%                 - 6: gaussian, A [delta% avg]; B [standard deviation]
%                                mu = A; STD = B;
%                                val = (1 + randn)*v0
% 
%                 - 7: gaussian, A [delta avg]; B [standard deviation]
%                                mu = A; STD = B;
%                                val = v0 + randn

idx = length(parameters);
param = struct( ...
               'name', name, ...
               'distribution', distrType, ...
               'a', A, ...
               'b', B, ...
               'id', [], ...
               'value', [], ...
               'modFactor', []);

%% Compute modfactor
if (distrType >= 1) && (distrType <= 4)
    param.modFactor = A.*ones(n, 1) + (B - A)*rand(n, 1);
elseif (distrType >= 5) && (distrType <= 7)
    param.modFactor = A.*ones(n, 1) + B.*randn(n, 1);
end

%% Saving parameter
if idx == 0
    parameters = param; 
    return;
end

if any(strcmp([parameters.name], name))
    error('Parameter "%s" has alerady been added', name)
end

parameters(idx + 1) = param;

end