classdef Edge
    % Edge - Represents an instance of a mesh edge
    %
    % The class contains all the properties and methods associated with the
    % edges of a mesh.
    % 
    % Face Properties:
    %   vertices    -   (3x2) matrix of edge vertices (each column is a (3x1) vertex)
    %   length      -   Edge length
    %   Ee          -   Edge dyad built from the unit normals of the two faces sharing the edge 
    %   id          -   uint64 hash of the edge 
    %   faces       -   (1x2) faces sharing the edge
    %   normals     -   (3x2) normals of the edge wrt the faces sharing the edges (each column is a (3x1) normal)
    %
    % Face Methods:
    %   Edge            -   Class constructor
    %   computeRe       -   Returns the distance of the edge from a field point
    %   computeLe       -   Returns the logarithmic edge factor given a field point

    properties
        % vertices - (3x2) matrix of edege vertices
        % Each vertex corresponds to a (3x1) column of the matrix
        vertices    (3,2)   double

        length      (1,1)   double  % Edge length
        Ee          (3,3)   double  % Edge dyad built from the unit normals of the two faces sharing the edge
        id          (1,1)   uint64  % Hash of the Edge

        faces       (1,2)   Face    % Array of faces sharing the edge
        normals     (3,2)   double  % Matrix of normals edge wrt the faces sharing the edges (each column is a (3x1) normal)
    end

    methods % Constructor
        function obj = Edge(verts)
            % Edge - Class constructor
            %
            % Creates a new Edge object given its vertices and computes the
            % length and the id.
            %
            % obj = Edge(verts)
            %
            % Inputs:
            %   verts:  (3x2) matrix of vertices (each (3x1) column is a
            %   vertex)
            %
            % Outputs:
            %   obj:    New instance of the Edge

            arguments
                verts  (3,2)   double = zeros(3,2);
            end
            
            obj.vertices = verts;
            obj.length = norm(verts(:,2) - verts(:,1));
            obj.id = obj.generateId(verts);
        end
    end

    methods
        function re = computeRe(obj, point)
            % computeRe - Returns the distance of the Edge from a field point
            % 
            % As any point on the edge can be choosen, the first vertex is
            % choosen to simplify computations
            %
            % re = computeRe(obj, point)
            %
            % Inputs:
            %   obj:    Current edge instance
            %   point:  (3x1) coordinates of the field point
            %
            % Outputs:
            %   rf:     (3x1) Distance

            re = obj.vertices(:,1) - point;
        end 

        function Le = computeLe(obj, point)
            % computeLe - Returns the logarithmic edge factor given a field point
            %
            % The logarithmic edge factor is a dimensionless scalar 
            % coupling the field-point distances to the two edge endpoints 
            % and the edge length.
            %
            % Le = computeLe(obj, point)
            %
            % Inputs:
            %   obj:    Current edge instance
            %   point:  (3x1) coordinates of the field point
            %
            % Outputs:
            %   Le:     Logarithmic edge factor

            verts = vecnorm(obj.vertices - point);
            Le = log((verts(1) + verts(2) + obj.length)/(verts(1) + verts(2) - obj.length));
        end

        function [obj, err] = addNormal(obj, normal, face)
            % addNormal - Updates the edge instance with the face and normal given
            %
            % This functions updates the face array containing the faces
            % sharing the edge and saves the corresponding edge normal
            % computed with respect to that face.
            % Returns err = true if more than 2 faces are set for the same
            % Edge instance as it would violate the manifold hypothesis of
            % the mesh
            %
            % [obj, err] = addNormal(obj, normal, face)
            %
            % Inputs:
            %   obj:        Current edge instance
            %   normal:     (3x1) normal of the edge wrt to the face
            %   face:       Face instance
            %
            % Outputs:
            %   obj:        Edge instance with normals and faces updated
            %   err:        True if more than two faces are set for the same edge


            if isempty(obj.faces(1))
                obj.normals(:,1) = normal;
                obj.faces(1) = face;
                err = false;
            elseif isempty(obj.faces(2))
                obj.normals(:,2) = normal;
                obj.faces(2) = face;

                obj.Ee = obj.updateEe();
                err = false;
            else
                err = true;
            end
        end
    end

    % Private functions
    methods (Access = private, Hidden = true)

        function Ee = updateEe(obj)
            % updateEe - Computes the edge dyad 
            %
            % Edege dyad Ee is computed as sum of the outer products of the unit
            % normals of the two faces sharing edge and the respective edge
            % normals.
            % Ee = nf1 * ne1' + nf2 * ne2'
            %
            % Ee = updateEe(obj)
            %
            % Inputs:
            %   obj:    Current edge instance
            %
            % Outputs:
            %   Ee:     Edge dyad

            if all(obj.normals(:,1) == zeros(3,1)) || ...
                    all(obj.normals(:,2) == zeros(3,1))
                error("Normals not set when computing Ee");
            end

            Ee = obj.faces(1).normal * obj.normals(:,1)' + ...
                obj.faces(2).normal * obj.normals(:,2)';
        end

        function id = generateId(~, verts)
            % generateId - Function to compute the edge id
            % 
            % The id depends on the vertices matrix, sorted using the
            % sortrows function such that vertex order doesn't impact the
            % hash computation
            %
            % id = generateId(obj, verts)
            %
            % Inputs:
            %   obj:    Current edge instance
            %   verts:  Matrix of the edge vertices
            %
            % Outputs:
            %   id:     uint64 Edge id

            verts = sortrows(verts');
            id = keyHash(verts);
        end
    end
end