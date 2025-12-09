classdef Face
    % Face - Represents an instance of a triangular face of a mesh
    %
    % The class contains all the properties and methods associated with the
    % faces of a mesh.
    % 
    % Face Properties:
    %   vertices    -   (3x3) matrix of face vertices (each column is a (3x1) vertex)
    %   normal      -   Face normal
    %   idxVerts    -   Vertices indexes in the vertexList
    %   Ff          -   Face dyad formed from the tensor product of the normal
    %   center      -   Center of the face
    %
    % Face Methods:
    %   Face            -   Class constructor
    %   computeRf       -   Returns the distance of the face center from a field point
    %   computeOmegaf   -   Returns the signed solid angle subtended by the face at a field point
    %   computeVolume   -   Computes the signed volume of the pyramid having the face as base
    %   isempty         -   Returns true if the instance is the default one
    
    properties 
        % vertices - (3x3) matrix of face vertices
        % Each vertex corresponds to a (3x1) column of the matrix
        % The vertices order is counterclockwise
        vertices    (3,3) double

        normal      (3,1) double    % Outward face normal
        idxVerts    (3,1) double    % Vertices index in the vertexList array
        Ff          (3,3) double    % Face dyad formed from the tensor product of the normal (nf*nf')
        center      (3,1) double    % Center of the face
    end

    methods % Constructor
        function obj = Face(v1, v2, v3)
            % Face - Class constructor
            %
            % Creates a new Face object given its vertices and computes the
            % center point of the face.
            %
            % obj = Face(v1, v2, v3)
            %
            % Inputs:
            %   v1:     (3x1) vertex
            %   v2:     (3x1) vertex
            %   v3:     (3x1) vertex
            %
            % Outputs:
            %   obj:    New instance of the Face

            arguments
                v1  (3,1)   double  = zeros(3,1)
                v2  (3,1)   double  = zeros(3,1)
                v3  (3,1)   double  = zeros(3,1)
            end

            obj.vertices = [v1 v2 v3];
            obj = obj.computeCenter();
        end
    end

    methods % Setters
        function obj = set.normal(obj, val)
            % set.normal - Setter function for the face normal
            %
            % Overrides the default setter for the face normal to also
            % update the face dyad Ff
            %
            % obj = set.normal(obj, val)
            %
            % Inputs:
            %   obj:    Current Face instance
            %   val:    (3x1) face normal
            %
            % Outputs:
            %   obj:    Updates Face instance

            arguments
                obj 
                val (3,1)   double
            end

            obj.normal = val;
            obj = obj.updateFf();
        end
    end

    methods % Getters
        function rf = computeRf(obj, point)
            % computeRf - Returns the distance of the face center from a field point
            %
            % rf = computeRf(obj, point)
            %
            % Inputs:
            %   obj:    Current face instance
            %   point:  (3x1) coordinates of the field point
            %
            % Outputs:
            %   rf:     (3x1) Distance

            rf = obj.center - point;
        end

        function omf = computeOmegaf(obj, point)
            % computeOmegaf - Returns the signed solid angle subtended by the face at a field point
            %
            % omf = computeOmegaf(obj, point)
            %
            % Inputs:
            %   obj:    Current face instance
            %   point:  (3x1) coordinates of the field point
            %
            % Outputs:
            %   omf:     Signed solid angle computed via triple product
            
            pos = obj.vertices - point;
            r1 = pos(:,1);
            r2 = pos(:,2);
            r3 = pos(:,3);

            num = dot(r1, cross(r2, r3));
            den = norm(r1)*norm(r2)*norm(r3) + norm(r1)*dot(r2,r3) + norm(r2)*dot(r3,r1) + norm(r3)*dot(r1,r2);

            omf = 2*atan2(num, den);
        end

        function V = computeVolume(obj, apex)
            % computeVolume - Computes the signed volume of the pyramid having the face as base 
            %
            % V = computeVolume(obj, apex)
            %
            % Inputs:
            %   obj:    Current face instance
            %   apex:  (3x1) coordinates of the pyramid's apex
            %
            % Outputs:
            %   V:     Signed volume of the pyramid
            
            % Area of the face
            A = 0.5*norm(cross(obj.vertices(:,2) - obj.vertices(:,1), obj.vertices(:,3) - obj.vertices(:,2)));

            rf = obj.center - apex';
            V = 1/3 * A * dot(obj.normal, rf);
        end
    end

    methods % Overrides
        function res = isempty(obj)
            % isempty - Overrides the defaut isempty function
            %
            % Returns true if the instance is the default one (all vertices
            % are zero), false otherwise
            %
            % res = isempty(obj)
            %
            % Inputs:
            %   obj:    Current face instance
            %
            % Outputs:
            %   res:    True if the instance is the default one, false otherwise
            
            if all(obj.vertices == zeros(3))
                res = true;
            else
                res = false;
            end
        end
    end

    % Private functions
    methods (Access = private, Hidden = true)
        
        function obj = computeCenter(obj)
            % computeCenter - Computes the face center 
            %
            % Face center is computed as the mean of the vertices
            % coordinates
            %
            % obj = computeCenter(obj)
            %
            % Inputs:
            %   obj:    Current face instance
            %
            % Outputs:
            %   obj:     Face instance with center updated

            obj.center(1) = mean(obj.vertices(1,:));
            obj.center(2) = mean(obj.vertices(2,:));
            obj.center(3) = mean(obj.vertices(3,:));
        end

        function obj = updateFf(obj)
            % updateFf - Computes the face dyad 
            %
            % Face dyad Ff is computed as outer product of the face normal
            % Ff = nf * nf'
            %
            % obj = updateFf(obj)
            %
            % Inputs:
            %   obj:    Current face instance
            %
            % Outputs:
            %   obj:     Face instance with face dyad updated

            obj.Ff = obj.normal * obj.normal';
        end
    end

end