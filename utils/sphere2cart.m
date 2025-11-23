function [varargout] = sphere2cart(R, inclination, azimuth)

    arguments
        R               (:,1) double
        inclination     (:,1) double = []
        azimuth         (:,1) double = []
    end

    if nargin == 1 && length(R) == 3
        inclination = R(2);
        azimuth = R(3);
        R = R(1);
    end

    NR = length(R);
    NIn = length(inclination);
    NAz = length(azimuth);

    X = nan(NR,NIn,NAz);
    Y = nan(NR,NIn,NAz);
    Z = nan(NR,NIn,NAz);

    for ii = 1:NR
        for jj = 1:NIn
            for kk = 1:NAz
                X(ii, jj, kk) = R(ii)*sin(inclination(jj))*cos(azimuth(kk));
                Y(ii, jj, kk) = R(ii)*sin(inclination(jj))*sin(azimuth(kk));
            end
            Z(ii, jj, :) = repmat(R(ii)*cos(inclination(jj)), [1 1 NAz]);
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