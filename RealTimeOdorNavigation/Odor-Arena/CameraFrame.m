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
    end
end