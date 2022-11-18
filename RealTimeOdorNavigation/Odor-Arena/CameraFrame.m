classdef CameraFrame
    properties (Constant)
        TOLERANCE = 0.95
    end
    properties
        Cam_Index uint32
        Cam_Timestamp uint32 = 0
        CameraData Camera
        isValid logical = true
    end
    methods
        function obj = CameraFrame(index, cameradata)
            obj.Cam_Index = index;
            if ~isstruct(cameradata)
                import Camera
                obj.CameraData = Camera(cameradata);
                likelihoods = obj.CameraData.getAllLikelihoods(false);
                for z = 1:length(likelihoods)
                    if(likelihoods(z) < CameraFrame.TOLERANCE), obj.isValid = false; break; end
                end
            else
                obj.Cam_Timestamp = cameradata.Cam_Timestamp;
                obj.CameraData = cameradata.CameraData;
                obj.isValid = cameradata.isValid;
            end
        end
        
        %% Get Methods
        function out1 = getFrameData(this)
            out1.Index = this.getFrameIndex();
            out1.Time = this.getFrameTimestamp();
            out1.Coordinates = this.getFrameCoordinates(true, true);
            out1.Valid = this.isValid;
        end
        
        function out1 = getFrameCoordinates(this, inc_likelihood, inc_port)
            out1 = this.CameraData.getAllPoints(inc_likelihood, inc_port);
        end
        
        function [neckNose, bodyNeck, tailbaseBody] = getFrameAngles(this)
            neckNose = this.CameraData.getNeckToNoseAngle();
            bodyNeck = this.CameraData.getBodyToNeckAngle();
            tailbaseBody = this.CameraData.getTailbaseToBodyAngle();
        end
        
        function out1 = getFrameIndex(this), out1 = this.Cam_Index; end
        function out1 = getFrameTimestamp(this), out1 = this.Cam_Timestamp; end
        function out1 = getValidity(this), out1 = this.isValid; end
        
    end
    methods (Static)
        function obj = loadobj(s)
            if isstruct(s)
                index = s.Cam_Index;
                cameradata.CameraData = s.CameraData;
                cameradata.Cam_Timestamp = s.Cam_Timestamp;
                cameradata.isValid = s.isValid;
                obj = CameraFrame(index, cameradata);
            else
                obj = s;
            end
        end
    end
end