function [varargout] = cart2Sphere(x, y, z)
    % cart2Sphere - Convert cartesian coordinates to spherical coordinates
    % 
    % Converts Cartesian coordinates (X, Y, Z) to spherical polar coordinates
    % (radius, polar, azimuth).
    % Radius is the distance from the origin, polar is the angle from
    % the positive Z-axis, and azimuth is the angle from the positive X-axis
    % in the X-Y plane.
    %
    % [rpa] = cart2Sphere(x, y, z)
    % [radius, polar, azimuth] = cart2Sphere(x, y, z)
    % [rpa] = cart2Sphere([x, y, z])
    % [radius, polar, azimuth] = cart2Sphere([x, y, z])
    %
    % Inputs:
    %   X:         [N x 1] X coordinates in Cartesian frame
    %   Y:         [N x 1] Y coordinates in Cartesian frame
    %   Z:         [N x 1] Z coordinates in Cartesian frame
    % 
    % Outputs:
    %   radius:     [N x 1] Radius  
    %   polar:      [N x 1] Polar angle (in radians)
    %   azimuth:    [N x 1] Azimuth angle (in radians)

    arguments
        x               (:,1) double
        y               (:,1) double = []
        z               (:,1) double = []
    end

    % Handle case where input is a single Nx3 array
    if nargin == 1 && length(x) == 3
        y = x(2);
        z = x(3);
        x = x(1);
    end

    Numx = length(x);
    Numy = length(y);
    Numz = length(z);
    
    radius = nan(Numx, Numy, Numz);
    polar = nan(Numx, Numy, Numz);
    azimuth = nan(Numx, Numy, Numz);

    for ii = 1:Numx
        for jj = 1:Numy
            for kk = 1:Numz
                radius(ii, jj, kk) = sqrt(x(ii)^2 + y(jj)^2 + z(kk)^2);
                
                % Check if point is at origin, in that case set angles to 0
                % as they are undefined
                if radius(ii, jj, kk) <= 1e-12
                    polar(ii, jj, kk) = 0;
                    azimuth(ii, jj, kk) = 0;
                else
                    polar(ii, jj, kk) = acos(z(kk)/radius(ii, jj, kk));
                    az = atan2(y(jj), x(ii));
                    if az < 0
                        az = az + 2*pi;
                    end
                    azimuth(ii, jj, kk) = az;
                end
            end
        end
    end


    if nargout <= 1
        if isscalar(radius)
            varargout{1} = [radius polar azimuth];
        else
            varargout{1} = cat(ndims(radius)+1, radius, polar, azimuth);
        end
    elseif nargout == 3
        varargout{1} = radius;
        varargout{2} = polar;
        varargout{3} = azimuth;
    else
        error("")
    end

end