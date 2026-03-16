function vSim = applyModFactor(p, k)
% applyModFactor - modifies the value of the parameter saved in "param"
%                  according with the given modifying factor
% 
% INPUTS:
%     param,            struct: parameter to modify in the simulation
%     modFactor, double [1, 1]: modifying factor
% 
% OUTPUTS:
%     vSim:     double [k-dim]: contains the value of the parameter modified
%                               according with the given modifying factor
% 
% VERSIONS:
% - 0     04/03/2023,     Release     Riccardo Cadamuro
% 
% Copyright © 2023, Skyward Experimental Rocketry, AFD department
% All rights reserved
% 
% SPDX-License-Identifier: GPL-3.0-or-later 
     
v0 = p.value;
pSize = size(v0);
nEl = numel(v0);

v0 = reshape(v0, [1, nEl]);

% apply same uncertanty to each element of the given parameter
% with the correct rule
switch p.distribution
    case {1, 5}
        vSim = p.modFactor(k, :).*ones([1, nEl]);
    case 2
        vSim = p.modFactor(k, :).*v0;
    case {3, 7}
        vSim = v0 + p.modFactor(k, :).*ones([1, nEl]);
    case {4, 6}
        vSim = v0.*(1 + p.modFactor(k, :)) ;
end

% final reshape to get the correct dimensions
vSim = reshape(vSim, pSize);
end

