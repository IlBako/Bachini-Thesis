function [varargout] = sphere2Cart(radius, polar, azimuth)
    % sphere2Cart - Converts spherical coordinates to Cartesian coordinates
    % 
    % Converts spherical polar coordinates (radius, polar, azimuth) to
    % Cartesian coordinates (X, Y, Z).
    % Radius is the distance from the origin, polar is the angle from
    % the positive Z-axis, and azimuth is the angle from the positive X-axis
    % in the X-Y plane.
    %
    % [XYZ] = sphere2Cart(radius, polar, azimuth)
    % [X, Y, Z] = sphere2Cart(radius, polar, azimuth)
    % [XYZ] = sphere2Cart([radius, polar, azimuth])
    % [X, Y, Z] = sphere2Cart([radius, polar, azimuth])
    %
    % Inputs:
    %   radius:     [N x 1] Radius  
    %   polar:      [N x 1] Polar angle (in radians)
    %   azimuth:    [N x 1] Azimuth angle (in radians)
    %
    % Outputs:
    %   X:         [N x 1] X coordinates in Cartesian frame
    %   Y:         [N x 1] Y coordinates in Cartesian frame
    %   Z:         [N x 1] Z coordinates in Cartesian frame
    %   XYZ:       [N x 3] Combined Cartesian coordinates

    arguments
        radius          (:,:) double
        polar           (:,1) double = []
        azimuth         (:,1) double = []
    end

    % Handle case where input is a single Nx3 array
    if nargin == 1 && size(radius, 2) == 3
        polar = radius(:, 2);
        azimuth = radius(:, 3);
        radius = radius(:, 1);
    end

    % Ensure azimuth in [0, 2pi)
    azimuth = mod(azimuth, 2*pi);

    NumRad = length(radius);
    NumIn = length(polar);
    NumAz = length(azimuth);

    X = nan(NumRad,NumIn,NumAz);
    Y = nan(NumRad,NumIn,NumAz);
    Z = nan(NumRad,NumIn,NumAz);

    for ii = 1:NumRad
        for jj = 1:NumIn
            for kk = 1:NumAz
                X(ii, jj, kk) = radius(ii)*sin(polar(jj))*cos(azimuth(kk));
                Y(ii, jj, kk) = radius(ii)*sin(polar(jj))*sin(azimuth(kk));
            end
            Z(ii, jj, :) = repmat(radius(ii)*cos(polar(jj)), [1 1 NumAz]);
        end
    end

    if nargout <= 1
        if isscalar(X)
            varargout{1} = [X Y Z];
        else
            varargout{1} = cat(ndims(X)+1, X, Y, Z);
        end
    elseif nargout == 3
        varargout{1} = X;
        varargout{2} = Y;
        varargout{3} = Z;
    else
        error("The function can only have either 1 or 3 outputs");
    end

end