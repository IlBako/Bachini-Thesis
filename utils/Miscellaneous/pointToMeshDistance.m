function dist = pointToMeshDistance(position, BVH_bboxMin, BVH_bboxMax, BVH_left, ...
        BVH_right, BVH_fStart, BVH_fCount, BVH_faces, BVH_vertexList)

    % position: [3x1] satellite's position

    %#codegen

    % persistent lastLeafDist lastOccTri
    % 
    % if isempty(lastLeafDist) || isempty(lastOccTri)
    %     lastLeafDist = int32(1);    % Last leaf for which minimum distance was found
    % end

    % Initialize minimum distance found and shadow check
    dmin2 = Inf;

    %% BVH Traversal

    MAX_STACK = int32(256);
    stack = zeros(MAX_STACK, 1, 'int32');
    stackPointer = int32(1);

    % Set stack root
    stack(stackPointer) = int32(1);

    % bestLeaf = lastLeafDist;

    while stackPointer > 0
        currentNode = stack(stackPointer);
        stackPointer = stackPointer - 1;

        dBox2 = distPointAABBoxSquared(position, BVH_bboxMin(currentNode, :), BVH_bboxMax(currentNode, :));

        if (dBox2 >= dmin2)
            continue
        end

        % Check if we have a leaf or if there are children nodes
        if BVH_left(currentNode) == -1
            % Index in faces array where this leaf's faces begin
            fStartIdx = BVH_fStart(currentNode);
            % Number of faces in this leaf
            faceNum = BVH_fCount(currentNode);
            
            for ii = int32(0):faceNum-1
                faceIdx = BVH_faces(fStartIdx+ii, :);
                vertA = BVH_vertexList(faceIdx(1), :);
                vertB = BVH_vertexList(faceIdx(2), :);
                vertC = BVH_vertexList(faceIdx(3), :);
                
                % Distance from face
                dFace2 = distPointTriangleSquared(position, vertA, vertB, vertC);
                if dFace2 < dmin2
                    dmin2 = dFace2;
                    % bestLeaf = currentNode;
                end

            end
        else
            
            % Distance-ordered traversal
            leftNode = BVH_left(currentNode);
            rightNode = BVH_right(currentNode);

            dLeft2 = distPointAABBoxSquared(position, BVH_bboxMin(leftNode, :), BVH_bboxMax(leftNode, :));
            dRight2 = distPointAABBoxSquared(position, BVH_bboxMin(rightNode, :), BVH_bboxMax(rightNode, :));

            % Stack is LIFO so last node inserted is the first one to be
            % processed
            if dLeft2 < dRight2
                stackPointer = stackPointer + 1;
                stack(stackPointer) = rightNode;
                stackPointer = stackPointer + 1;
                stack(stackPointer) = leftNode;
            else
                stackPointer = stackPointer + 1;
                stack(stackPointer) = leftNode;
                stackPointer = stackPointer + 1;
                stack(stackPointer) = rightNode;
            end


        end
    end

    % lastLeafDist = bestLeaf;
    dist = sqrt(dmin2);
    illuminated = ~inShadow;
    
end

function distSq = distPointAABBoxSquared(position, bboxMin, bboxMax)
    % Implemented from 
    % Christer Ericson, “Real-Time Collision Detection” (pp. 132)

    %#codegen
    distSq = 0;
    for ii = 1:3
        if position(ii) < bboxMin(ii)
            t = bboxMin(ii) - position(ii);
        elseif position(ii) > bboxMax(ii)
            t = position(ii) - bboxMax(ii);
        else
            t = 0;
        end
        distSq = distSq + t*t;
    end
end

function dist = distPointTriangle(position, vertA, vertB, vertC)
    % Implemented from 
    % Christer Ericson, “Real-Time Collision Detection” (pp. 136-142)
    % Reference pseudo-code at pp. 141-142

    %#codegen
    AB = vertB - vertA;
    AC = vertC - vertA;
    AP = position - vertA;
    
    % Check if P is in the vertex region outside A
    d1 = dot(AB, AP); % Projection of AP on AB
    d2 = dot(AC, AP);

    % If the projection of AP on both AB and AC is negative it means that
    % A is closest vertex to P, so the distance from the face is AP
    % In terms of barycentric coordinates: (1,0,0)
    if d1 <= 0 && d2 <= 0
        dist = norm(AP);
        return
    end

    % Check if P is in the vertex region outside B
    BP = position - vertB;
    d3 = dot(AB, BP);
    d4 = dot(AC, BP); 

    % If the point P is beyond B and not closer to BC or the face, then
    % B is closest vertex to P, so the distance from the face is BP
    % In terms of barycentric coordinates: (0,1,0)
    if d3 >= 0 && d4 <= d3
        dist = norm(BP);
        return
    end

    % Check if P is in the vertex region outside B
    CP = position - vertC;
    d5 = dot(AB, CP);
    d6 = dot(AC, CP);

    % If the point P is beyond C and not closer to BC or the face, then
    % C is closest vertex to P, so the distance from the face is CP
    % In terms of barycentric coordinates: (0,0,1)
    if d6 >= 0 && d5 <= d6
        dist = norm(CP);
        return
    end

    % Check if P is in the edge region of AB, if so distance is computed
    % between P and its projection onto AB
    vc = d1*d4 - d3*d2;

    if vc <= 0 && d1 >= 0 && d3 <= 0
        v = d1/(d1 - d3);
        proj = vertA + v * AB; % Barycentric coordinates (1-v,v,0)
        dist = norm(position - proj);
        return
    end

    % Check if P is in the edge region of AC, if so distance is computed
    % between P and its projection onto AC
    vb = d5*d2 - d1*d6;

    if vb <= 0 && d2 >= 0 && d6 <= 0
        w = d2 / (d2 - d6);
        proj = vertA + w * AC; % Barycentric coordinates (1-w,0,w)
        dist = norm(position - proj);
        return 
    end

    % Check if P is in the edge region of BC, if so distance is computed
    % between P and its projection onto BC
    va = d3*d6 - d5*d4;
    if va <= 0 && (d4 - d3) >= 0 && (d5 - d6) >= 0
        w = (d4 - d3)/((d4 - d3) + (d5 - d6));
        proj = vertB + w * (vertC - vertB); % Barycentric coordinates (0,1-w,w)
        dist = norm(position - proj);
        return
    end

    % If all previous checks failed it means P is inside the face region.
    % Compute the face normal and the distance of P from a vertex of the
    % triangle along such normal
    % Note: This is different from the pseudo-code at pp.141-142 of 
    % Christer Ericson, “Real-Time Collision Detection” as the barycentric
    % coordinates are not needed, thus the projection is computed
    % "implicitely"
    normal = cross(AB, AC); normal = normal/norm(normal);
    dist = abs(dot(position-vertA, normal));

end

function dist2 = distPointTriangleSquared(position, vertA, vertB, vertC)
    %#codegen
    dist = distPointTriangle(position, vertA, vertB, vertC);
    dist2 = dist*dist;
end