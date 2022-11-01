classdef CameraFrame
    properties
        Index uint32
        Timestamp uint32
        CameraData Camera
    end
    methods
        function obj = CameraFrame(index, cameradata)
            if nargin == 2
                import Camera
                obj.Index = index;
                obj.CameraData = Camera(cameradata);
            end
        end
        
        %% Get Methods
        function [output] = GetDataForFrame(input)
            output(1) = input.GetFrameIndex();
            output(2) = input.GetFrameTimestamp();
            output(3) = input.GetCoordinatesForFrame(true);
        end
        
        function [output] = GetCoordinatesForFrame(input, inc_likelihood)
            output = Camera.GetAllPoints(input.CameraData, inc_likelihood, true);
        end
        
        function index = GetFrameIndex(input)
            index = input.Index;
        end
        
        function timestamp = GetFrameTimestamp(input)
            timestamp = input.Timestamp;
        end
        
    end
end