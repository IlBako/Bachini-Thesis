function laplacian = computeLaplacian(faceList, fieldPoint)

    laplacian = 0;
    for ii = 1:length(faceList)
        laplacian = laplacian + faceList{ii}.computeOmegaf(fieldPoint);
    end

end