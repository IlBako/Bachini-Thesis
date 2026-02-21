function BVH = buildBVH(mesh, maxLeafSize)
    
    faceList = mesh.faceList;
    vertexList = mesh.vertexList;
    Nf = numel(faceList);

    % Pre-compute face bounding boxes
    faceMin = zeros(Nf, 3);
    faceMax = zeros(Nf, 3);

    for ii = 1:Nf
        pts = faceList{ii}.vertices;
        faceMin(ii, :) = min(pts, [], 2);
        faceMax(ii, :) = max(pts, [], 2);
    end

    % Pre-allocate arrays
    MAXNODES = 2*Nf;
    bboxMin = zeros(MAXNODES, 3);
    bboxMax = zeros(MAXNODES,3);
    left  = -ones(MAXNODES,1,'int32');
    right = -ones(MAXNODES,1,'int32');
    fStart = zeros(MAXNODES,1,'int32');
    fCount = zeros(MAXNODES,1,'int32');

    % Faces ordered for easier cache traversal
    orderedFaces = zeros(Nf, 3, 'int32');
    orderedNormals = zeros(Nf, 3);

    % Current number of nodes created
    nodeCount = 1;

    % Current position in orderedFaces array
    faceCursor = 1;

    % LIFO stack for node building
    stack = struct('node', 1, 'faces', 1:Nf);

    while ~isempty(stack)
        
        currentJob = stack(end);
        stack(end) = [];

        node = currentJob.node;
        faceIdxs = currentJob.faces;

        % Compute AABB for current node
        bmin = min(faceMin(faceIdxs, :), [], 1);
        bmax = max(faceMax(faceIdxs, :), [], 1);
        bboxMin(node, :) = bmin;
        bboxMax(node, :) = bmax;

        % If number of faces in current node is less than maxLeafSize the
        % current node is treated as a leaf
        if numel(faceIdxs) <= maxLeafSize
            % Assign contiguous faces to leaf node
            % Index in faces array where this leaf's faces begin
            fStart(node) = int32(faceCursor);
            % Number of faces in this leaf
            fCount(node) = int32(numel(faceIdxs));
            for ii = 1:numel(faceIdxs)
                orderedFaces(faceCursor+ii-1,:) = int32(faceList{faceIdxs(ii)}.idxVerts);
                orderedNormals(faceCursor+ii-1,:) = int32(faceList{faceIdxs(ii)}.normal(:)');
            end
            faceCursor = faceCursor + numel(faceIdxs);
            continue
        end

        % If not a leaf, split the bounding box along the longest axis and
        % create two new nodes
        extension = bmax - bmin;
        [~, splitAx] = max(extension);

        % Divide face list along the splitAx axis
        center = (faceMin(faceIdxs,splitAx)+faceMax(faceIdxs,splitAx))/2;
        [~, ord] = sort(center);
        mid = floor(numel(faceIdxs)/2);

        leftFaces = faceIdxs(ord(1:mid));
        rightFaces = faceIdxs(ord(mid+1:end));

        nodeCount = nodeCount + 1;
        L = nodeCount;
        left(node) = int32(L);

        nodeCount = nodeCount + 1;
        R = nodeCount;
        right(node) = int32(R);

        stack(end+1) = struct('node', L, 'faces', leftFaces);
        stack(end+1) = struct('node', R, 'faces', rightFaces);
    end

    BVH.bboxMin     = bboxMin(1:nodeCount, :);
    BVH.bboxMax     = bboxMax(1:nodeCount, :);
    BVH.left        = left(1:nodeCount, :);
    BVH.right       = right(1:nodeCount, :);
    BVH.fStart      = fStart(1:nodeCount);
    BVH.fCount      = fCount(1:nodeCount);
    BVH.faces       = orderedFaces;
    BVH.vertexList  = vertexList;
    BVH.normals     = orderedNormals;

end