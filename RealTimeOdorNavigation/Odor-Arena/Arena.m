classdef Arena < handle
    % Arena    This class stores the Coordinates of the Trial's arena.
    % 

    properties
        TopLeft Coords          % Top Left Coordinate
        TopRight Coords         % Top Right Coordinate
        BottomLeft Coords       % Bottom Left Coordinate
        BottomRight Coords      % Bottom Right Coordinate
        Port Coords             % Port Coordinate
    end
    methods
        function obj = Arena(in1)
            % ARENA  Constructor
            %
            %   USAGE
            %       obj = Arena(in1)
            %
            %   INPUT PARAMETERS
            %       in1     -   double matrix (size: 10) OR struct from MAT-file
            %
            %   OUTPUT PARAMETERS
            %       obj     -   returns Arena obj

            if isstruct(in1)
                obj.TopLeft = in1.TopLeft;
                obj.TopRight = in1.TopRight;
                obj.BottomLeft = in1.BottomLeft;
                obj.BottomRight = in1.BottomRight;
                obj.Port = in1.Port;
            else
                obj.TopLeft = Coords(in1(1), in1(2));
                obj.TopRight = Coords(in1(3), in1(4));
                obj.BottomLeft = Coords(in1(5), in1(6));
                obj.BottomRight = Coords(in1(7), in1(8));
                obj.Port = Coords(in1(9), in1(10));
            end
        end
        
        function coords = getArenaCoordinates(this)
            % GETARENACOORDINATES  This function returns all Arena coordinates as a matrix
            %
            %   USAGE
            %       coords = getArenaCoordinates(this)
            %
            %   INPUT PARAMETERS
            %       this     -   Arena object
            %
            %   OUTPUT PARAMETERS
            %       coords     -   returns Arena coordinates as [x y]

            x = zeros(0,5);
            y = zeros(0,5);
            
            [x(1), y(1)] = this.TopLeft.getCoord();
            [x(2), y(2)] = this.TopRight.getCoord();
            [x(3), y(3)] = this.BottomLeft.getCoord();
            [x(4), y(4)] = this.BottomRight.getCoord();
            [x(5), y(5)] = this.Port.getCoord();
            coords = [x' y'];
        end
    end
    
    %% Save, Load
    methods (Static)
        function s = saveobj(obj)
            s = struct;
            s.TopLeft = obj.TopLeft;
            s.TopRight = obj.TopRight;
            s.BottomLeft = obj.BottomLeft;
            s.BottomRight = obj.BottomRight;
            s.Port = obj.Port;
        end

        function obj = loadobj(s)
            if isstruct(s)
                obj = Arena(s);
            else
                obj = s;
            end
        end
    end
end