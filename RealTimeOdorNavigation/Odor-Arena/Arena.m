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
            if ~isstruct(arena_data)
                obj.TopLeft = Coords(arena_data(1), arena_data(2));
                obj.TopRight = Coords(arena_data(3), arena_data(4));
                obj.BottomLeft = Coords(arena_data(5), arena_data(6));
                obj.BottomRight = Coords(arena_data(7), arena_data(8));
                obj.Port = Coords(arena_data(9), arena_data(10));
            else
                obj.TopLeft = arena_data.TopLeft;
                obj.TopRight = arena_data.TopRight;
                obj.BottomLeft = arena_data.BottomLeft;
                obj.BottomRight = arena_data.BottomRight;
                obj.Port = arena_data.Port;
            end
        end
        
        function out1 = getArenaCoordinates(this)
            x = zeros(0,5);
            y = zeros(0,5);
            
            [x(1), y(1)] = this.TopLeft.getCoord();
            [x(2), y(2)] = this.TopRight.getCoord();
            [x(3), y(3)] = this.BottomLeft.getCoord();
            [x(4), y(4)] = this.BottomRight.getCoord();
            [x(5), y(5)] = this.Port.getCoord();
            out1 = [x' y'];
        end
        
        function s = saveobj(obj)
            s = struct;
            s.TopLeft = obj.TopLeft;
            s.TopRight = obj.TopRight;
            s.BottomLeft = obj.BottomLeft;
            s.BottomRight = obj.BottomRight;
            s.Port = obj.Port;
        end
    end
    
    %%
    methods (Static)
        function obj = loadobj(s)
            if isstruct(s)
                obj = Arena(s);
            else
                obj = s;
            end
        end
    end
end