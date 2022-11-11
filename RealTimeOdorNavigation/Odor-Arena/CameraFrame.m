classdef CameraFrame
    properties (Constant)
        Tolerance = 0.999
    end
    properties
        Cam_Index uint32
        Cam_Timestamp uint32 = 0
        CameraData Camera
        isValid logical
    end
    methods
        function obj = CameraFrame(in1, cameradata)
            if nargin == 2
                import Camera
                obj.Cam_Index = in1;
                obj.CameraData = Camera(cameradata);
                obj.isValid = true;
                likelihoods = obj.CameraData.GetAllLikelihoods(false);
                for z = 1:length(likelihoods)
                    if(likelihoods(z) < CameraFrame.Tolerance)
                        obj.isValid = false;
                        break;
                    end
                end
            end
        end
        
        %% Get Methods
        function out1 = GetFrameData(in1)
            out1.Index = in1.GetFrameIndex();
            out1.Time = in1.GetFrameTimestamp();
            out1.Coordinates = in1.GetFrameCoordinates(true, true);
            out1.Valid = in1.isValid;
        end
        
        function out1 = GetFrameCoordinates(in1, inc_likelihood, inc_port)
            out1 = in1.CameraData.GetAllPoints(inc_likelihood, inc_port);
        end
        
        function out1 = GetFrameIndex(in1)
            out1 = in1.Cam_Index;
        end
        
        function out1 = GetFrameTimestamp(in1)
            out1 = in1.Cam_Timestamp;
        end
        
        function out1 = GetValidity(in1)
            out1 = in1.isValid;
        end
        
    end
end