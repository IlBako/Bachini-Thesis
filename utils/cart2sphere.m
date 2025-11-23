function varargout = cart2sphere(x, y, z)

    R = sqrt(x.^2 + y.^2 + z.^2);
    theta = acos(z/R);
    phi = atan2(y, x);
    phi(phi < 0) = phi(phi < 0) + 2*pi;


    if nargout < 1
        varargout{1} = [R theta phi];
    elseif nargout == 3
        varargout{1} = R;
        varargout{2} = theta;
        varargout{3} = phi;
    else
        error("")
    end

end