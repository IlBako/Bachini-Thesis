function mesh = readStl(fname)
    % readStl - Function to read a .stl ASCII file and return the meshData
    %
    % mesh = readStl(fname)
    %
    % Inputs:
    %   fname:  Name of the stl file
    %
    % Outputs:
    %   mesh:   Struct containing the list of all the vertices, faces and
    %   edges

    arguments
        fname {mustBeFile} % Filepath of the .stl file
    end

    % Utility variables
    vertices = zeros(3,3);  % Current face vertices
    vertsIdx = nan(1,3);    % Current vertices index in the vertexList array
    idx = 1;                % Current face vertex idx (from 1 to 3)

    %% Parse stl to get mesh faces

    % Pre-allocated face list to avoid dynamic reallocation
    faceList = createArray(1e5,1,'Face');

    % Vertices are saved in a dictionary to speed up the check on whether
    % they have already being saved or not
    vertexDict = configureDictionary('uint64', 'cell');

    idxFace = 1;    % Face index in the faceList array
    idxVertex = 1;  % Vertex index in the vertexList array

    % Open stl file
    [fid] = fopen(fname);
    if fid < 0
        error("Error opening file %s", fname);
    end

    % Parse stl file
    while true

        fline = fgetl(fid);
        if ~ischar(fline)
            % EOF reached
            break
        end

        if contains(fline, 'solid')
            % solid and endsolid are the header and footer of the stl file 
            continue
        end

        ln = sscanf(fline, '%s', 1);

        switch ln
            case 'facet' % facet normal
                normal = sscanf(fline(14:end), '%f %f %f');

            case {'outer', 'endloop'} % outer loop
                continue

            case 'vertex' % Vertex data
                currVertex = sscanf(fline(10:end), '%f %f %f');

                vertices(:, idx) = currVertex;

                hash = keyHash(currVertex);
                isPresent = isKey(vertexDict, hash);
                if ~isPresent
                    vertexDict(hash) = {[idxVertex, currVertex']};
                    vertsIdx(idx) = idxVertex;
                    idxVertex = idxVertex + 1;
                else
                    vertsIdx(idx) = vertexDict{hash}(1);
                end

                idx = idx+1;

            case 'endfacet' % End of the current face description
                currFace = Face(vertices(:,1), vertices(:,2), vertices(:,3));
                currFace.normal = normal/norm(normal);
                currFace.idxVerts = vertsIdx;
                vertices = zeros(3,3);
                vertsIdx = nan(1,3);
                idx = 1;

                faceList(idxFace) = currFace;
                idxFace = idxFace + 1;
        end
    end

    % Trim face list and convert it to cell array
    idxFace = idxFace - 1;
    if idxFace < length(faceList)
        faceList = faceList(1:idxFace);
    end
    mesh.faceList = num2cell(faceList);

    % Retrieve vertex informations from the dictionary
    vertexList = cell2mat(values(vertexDict));
    mesh.vertexList = vertexList(:, 2:4);

    % Compute mesh center
    mesh.center = mean(vertexList(:, 2:4)).*0;

    %% Edges and volume computation

    % Vertices combinations for edge definition
    edgeComb = {[1 2], [2 3], [3 1]};

    % Edges are saved in a dictionary to speed up the check on whether
    % they have already being saved or not
    edgeDict = configureDictionary("uint64", "Edge");

    % Initialize the mesh volume
    volume = 0;

    for ii = 1:length(faceList)
        for jj = 1:length(edgeComb)
            currEdge = Edge(faceList(ii).vertices(:, edgeComb{jj}));

            normal = cross(currEdge.vertices(:, 2) - currEdge.vertices(:,1), faceList(ii).normal);
            normal = normal/norm(normal);

            isPresent = isKey(edgeDict, currEdge.id);

            if isPresent
                [currEdge, err] = addNormal(edgeDict(currEdge.id), normal, faceList(ii));
            else
                [currEdge, err] = addNormal(currEdge, normal, faceList(ii));
            end
            if err
                error("More than two faces share the same edge");
            end
            edgeDict(currEdge.id) = currEdge;
        end

        % Volume is computed as sum of pyramids having as base each face
        % and as apex the center of the mesh
        volume = volume + faceList(ii).computeVolume(mesh.center);

    end

    % Retrieve edgeList as cell array
    mesh.edgeList = num2cell(values(edgeDict));
    
    % Save computed volume
    mesh.volume = volume;

end