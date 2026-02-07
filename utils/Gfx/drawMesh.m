function drawMesh(meshData, center, drawFaces, drawFacesNormal, drawCenter, drawEdges, drawEdgesNormal)
    % drawMesh - Function to draw a mesh 
    %
    % drawMesh(meshData, drawFaces, drawFacesNormal, drawCenter, drawEdges, drawEdgesNormal)
    %
    % Inputs:
    %   meshData        -  struct containing the mesh faceList and edgeList
    %   center          -  center of the mesh (default: [0; 0; 0])
    %   drawFaces       -  (default: true)
    %   drawFacesNormal -  (default: false)
    %   drawCenter      -  (default: false)
    %   drawEdges       -  (default: false)
    %   drawEdgesNormal -  (default: false)


    arguments
        meshData                    struct
        center              (3,1)   double = [0; 0; 0]
        drawFaces                   logical = true
        drawFacesNormal             logical = false
        drawCenter                  logical = false
        drawEdges                   logical = false
        drawEdgesNormal             logical = false
    end

    if drawFaces

        faceList = meshData.faceList;
        numFaces = length(faceList);
        T = zeros(numFaces, 3);

        for ii = 1:numFaces
            T(ii, :) = faceList{ii}.idxVerts;
        end

        h = trimesh(T, meshData.vertexList(:,1), meshData.vertexList(:,2), meshData.vertexList(:,3), ...
            "FaceColor", "cyan", "FaceAlpha", '0.25', "EdgeColor", "black", 'HandleVisibility', 'off');
        h.CData = [];

        if drawFacesNormal
            for ii = 1:numFaces
                vec = [faceList{ii}.center ...
                    faceList{ii}.center + faceList{ii}.normal];
                line(vec(1,:), vec(2,:), vec(3,:), 'Color', 'g', 'LineWidth', 1);
            end
        end
    end

    if drawCenter
        scatter3(center(1), center(2), center(3), 50, 'black', 'filled')
    end

    if drawEdges
        for ii = 1:length(meshData.edgeList)

            verts = [meshData.edgeList{ii}.vertices(:,1) meshData.edgeList{ii}.vertices(:,2)];
            plot3(verts(1,:), verts(2,:), verts(3,:), 'k', 'LineWidth', 1.5, 'HandleVisibility', 'off');

            if drawEdgesNormal
                vec1 = [mean(verts, 2) mean(verts,2)+meshData.edgeList{ii}.normals(:,1)];
                vec2 = [mean(verts, 2) mean(verts,2)+meshData.edgeList{ii}.normals(:,2)];

                line(vec1(1,:), vec1(2,:), vec1(3,:), 'Color', 'b', 'LineWidth', 1);
                line(vec2(1,:), vec2(2,:), vec2(3,:), 'Color', 'r', 'LineWidth', 1);
            end
        end
    end

end