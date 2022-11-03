classdef CameraFrame
    properties
        Cam_Index uint32
        Cam_Timestamp uint32 = 0
        CameraData Camera
    end
    methods
        function obj = CameraFrame(in1, cameradata)
            if nargin == 2
                import Camera
                obj.Cam_Index = in1;
                obj.CameraData = Camera(cameradata);
            end
        end
        
        %% Get Methods
        function out1 = GetDataForFrame(in1)
            out1.index = in1.GetFrameIndex();
            out1.time = in1.GetFrameTimestamp();
            out1.coords = in1.GetCoordinates(true, true);
        end
        
        function out1 = GetCoordinates(in1, inc_likelihood, inc_port)
            out1 = in1.CameraData.GetAllPoints(inc_likelihood, inc_port);
        end
        
        function out1 = GetFrameIndex(in1)
            out1 = in1.Cam_Index;
        end
        
        function out1 = GetFrameTimestamp(in1)
            out1 = in1.Cam_Timestamp;
        end
        
    end
end