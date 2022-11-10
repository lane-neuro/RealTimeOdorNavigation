classdef Arena
    properties
        TopLeft Coords
        TopRight Coords
        BottomLeft Coords
        BottomRight Coords
        Port Coords
    end
    methods
        function obj = Arena(arena_data)
            import Coords
            if nargin == 1
                obj.TopLeft = Coords(arena_data(1), arena_data(2));
                obj.TopRight = Coords(arena_data(3), arena_data(4));
                obj.BottomLeft = Coords(arena_data(5), arena_data(6));
                obj.BottomRight = Coords(arena_data(7), arena_data(8));
                obj.Port = Coords(arena_data(9), arena_data(10));
            end
        end
        
        function out1 = GetArenaCoordinates(in1)
            x = zeros(0,5);
            y = zeros(0,5);
            
            [x(1), y(1)] = in1.TopLeft.GetCoord();
            [x(2), y(2)] = in1.TopRight.GetCoord();
            [x(3), y(3)] = in1.BottomLeft.GetCoord();
            [x(4), y(4)] = in1.BottomRight.GetCoord();
            [x(5), y(5)] = in1.Port.GetCoord();
            out1 = [x' y'];
        end
    end
end