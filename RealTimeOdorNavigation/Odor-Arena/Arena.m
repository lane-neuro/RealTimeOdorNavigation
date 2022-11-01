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
    end
end