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
        function [index, timestamp, coords] = GetDataForFrame(input)
            index = input.GetFrameIndex();
            timestamp = input.GetFrameTimestamp();
            coords = input.GetCoordinatesForFrame(true);
        end
        
        function output = GetCoordinatesForFrame(input, inc_likelihood)
            output = input.CameraData.GetAllPoints(inc_likelihood, true);
        end
        
        function index = GetFrameIndex(input)
            index = input.Index;
        end
        
        function timestamp = GetFrameTimestamp(input)
            timestamp = input.Timestamp;
        end
        
    end
end