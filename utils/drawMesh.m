function drawMesh(meshData, drawFaces, drawFacesNormal, drawCenter, drawEdges, drawEdgesNormal)
    % drawMesh - Function to draw a mesh 
    %
    % drawMesh(meshData, drawFaces, drawFacesNormal, drawCenter, drawEdges, drawEdgesNormal)
    %
    % Inputs:
    %   meshData        -  struct containing the mesh faceList and edgeList
    %   drawFaces       -  (default: true)
    %   drawFacesNormal -  (default: false)
    %   drawCenter      -  (default: true)
    %   drawEdges       -  (default: false)
    %   drawEdgesNormal -  (default: false)


    arguments
        meshData            struct
        drawFaces           logical = true
        drawFacesNormal     logical = false
        drawCenter          logical = true
        drawEdges           logical = false
        drawEdgesNormal     logical = false
    end

    if drawFaces
        for ii = 1:length(meshData.faceList)
            fill3(meshData.faceList{ii}.vertices(1,:), ...
                meshData.faceList{ii}.vertices(2,:), ...
                meshData.faceList{ii}.vertices(3,:), 'cyan', 'FaceAlpha', 0.5, 'HandleVisibility', 'off');

            if drawFacesNormal
                vec = [meshData.faceList{ii}.center ...
                    meshData.faceList{ii}.center + meshData.faceList{ii}.normal];
                line(vec(1,:), vec(2,:), vec(3,:), 'Color', 'g', 'LineWidth', 1);
            end
        end
    end

    if drawCenter
        scatter3(meshData.center(1), meshData.center(2), meshData.center(3), 50, 'black', 'filled')
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