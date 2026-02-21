
pointMats = [X(:) Y(:) Z(:)];
G = 6.67430*1e-11;
gravAttNorm = gravStruct.gravAttNorm(:);

tic
parfor ii = 1:size(pointMats, 1)
    if isnan(gravAttNorm(ii))
        sphereGravNorm{ii} = nan;
    else
        sphereGravNorm{ii} = G*5.972168e24/(norm(pointMats(ii, :)))^2;
    end
end

sphereGravNorm = cell2mat(sphereGravNorm)';
gravErr = sphereGravNorm - gravAttNorm;
gravPercErr = gravErr ./ sphereGravNorm*100;

toc