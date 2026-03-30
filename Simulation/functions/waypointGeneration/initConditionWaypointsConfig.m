function [init,TSim] = initConditionWaypointsConfig(kepEls, asteroidMu, asteroidAngularVelocity)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                CONFIGURATION FILE FOR INITIAL CONDITIONS                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Target orbit definition
% Target keplerian elements
a_target = kepEls.a;
e_target = kepEls.e;
i_target = kepEls.i;
OM_target = kepEls.OM;
om_target = kepEls.om;
theta_start = kepEls.theta;

% Target orbit parameters (angular momentum and eccentricity)
control.h_target = sqrt(asteroidMu*a_target*(1-e_target^2))*...
                    [sin(i_target)*sin(OM_target); -sin(i_target)*cos(OM_target); cos(i_target)];
control.ecc_target = e_target*[cos(OM_target)*cos(om_target) - sin(OM_target)*sin(om_target)*cos(i_target);
                                     sin(OM_target)*cos(om_target) + cos(OM_target)*sin(om_target)*cos(i_target);
                                     sin(om_target)*sin(i_target)];

% Initial condition from keplerian orbit

[rr0, vv0] = kep2car(a_target, e_target, i_target, OM_target, om_target, theta_start, asteroidMu);

%% States configuration
init.scPosition = rr0;
init.scVelocity = vv0 - cross(asteroidAngularVelocity, rr0);
init.STM0 = eye(6);
TSim = 2*pi*sqrt(a_target^3/asteroidMu);

end