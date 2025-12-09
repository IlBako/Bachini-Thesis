function varargout = cart2sphere(x, y, z)

    arguments
        x               (:,1) double
        y               (:,1) double = []
        z               (:,1) double = []
    end

    if nargin == 1 && length(x) == 3
        y = x(2);
        z = x(3);
        x = x(1);
    end

    Nx = length(x);
    Ny = length(y);
    Nz = length(z);
    
    R = nan(Nx, Ny, Nz);
    theta = nan(Nx, Ny, Nz);
    phi = nan(Nx, Ny, Nz);

    for ii = 1:Nx
        for jj = 1:Ny
            for kk = 1:Nz
                R(ii, jj, kk) = sqrt(x(ii)^2 + y(jj)^2 + z(kk)^2);
                
                % Check if point is at origin, in that case set angles to 0
                % as they are undefined
                if R(ii, jj, kk) <= 1e-12
                    theta(ii, jj, kk) = 0;
                    phi(ii, jj, kk) = 0;
                else
                    theta(ii, jj, kk) = acos(z(kk)/R(ii, jj, kk));
                    az = atan2(y(jj), x(ii));
                    if az < 0
                        az = az + 2*pi;
                    end
                    phi(ii, jj, kk) = az;
                end
            end
        end
    end


    if nargout <= 1
        if isscalar(R)
            varargout{1} = [R theta phi];
        else
            varargout{1} = cat(ndims(R)+1, R, theta, phi);
        end
    elseif nargout == 3
        varargout{1} = R;
        varargout{2} = theta;
        varargout{3} = phi;
    else
        error("")
    end

end