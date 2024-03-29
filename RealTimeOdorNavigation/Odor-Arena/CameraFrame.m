classdef CameraFrame
    properties (Constant, Hidden = true)
        TOLERANCE = 0.95
        LEFT_INSET = 30             % pixels - originally 30
        RIGHT_INSET = 30            % pixels
        WIDTH = 564                 % pixels
        HEIGHT = 264                % pixels
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
            if ~isstruct(cameradata) % new data
                obj.CameraData = Camera(cameradata);
                likelihoods = obj.CameraData.getAllLikelihoods(Port=false);
                for z = 1:length(likelihoods)
                    if(likelihoods(z) < CameraFrame.TOLERANCE)
                        obj.isValid = false; 
                        break;
                    end
                end
            else % loaded from matfile
                obj.Cam_Timestamp = cameradata.Cam_Timestamp;
                obj.CameraData = cameradata.CameraData;
                obj.isValid = cameradata.isValid;
            end
        end
        
        %% Get Methods
        function out1 = getSingleFrameData(this, options)
            arguments (Input)
                this CameraFrame
                options.Likelihood logical = false
                options.Port logical = false
            end
            out1 = struct;
            out1.Index = this.getFrameIndex();
            out1.Time = this.getFrameTimestamp();
            out1.Coordinates = this.getFrameCoordinates(Likelihood=options.Likelihood, ...
                Port=options.Port);
            [out1.Valid, out1.Reasoning] = this.getValidity();
        end
        
        function out1 = getFrameCoordinates(this, options)
            arguments (Input)
                this CameraFrame
                options.Likelihood logical = false
                options.Port logical = false
            end

            out1 = this.CameraData.getAllPoints(Likelihood=options.Likelihood, Port=options.Port);
        end
        
        function out1 = getFrameAngle(this, p1_name, p2_name)
            arguments (Input)
                this CameraFrame
                p1_name string {mustBeMember(p1_name,["Nose","LeftEar","RightEar", ...
                    "Neck","Body","Tailbase","Port","CenterofHead"])}
                p2_name string {mustBeMember(p2_name,["Nose","LeftEar","RightEar", ...
                    "Neck","Body","Tailbase","Port","CenterofHead"])}
            end

            out1 = this.CameraData.calcAngleBetweenCoords(p1_name, p2_name);
        end

        function [x_out, y_out] = getHeadMidpoint(this)
            arguments (Input)
                this CameraFrame
            end
            arguments (Output)
                x_out double
                y_out double
            end

            p1 = this.CameraData.getHeadCenter();
            x_out = p1(1);
            y_out = p1(2);
        end

        function dist_out = getBodyDistance(this)
            arguments (Input)
                this CameraFrame
            end
            arguments (Output)
                dist_out double
            end
            
            p1 = this.CameraData.getHeadCenter();
            [p2(1), p2(2), ~] = this.CameraData.getBody();
            dist_out = this.CameraData.calcBehaviorDistance(p1,p2);
        end

        function dist_out = getPointDistance(this, p1_name, p2_name)
            arguments (Input)
                this CameraFrame
                p1_name string {mustBeMember(p1_name,["Nose","LeftEar","RightEar", ...
                    "Neck","Body","Tailbase","Port","CenterofHead"])}
                p2_name string {mustBeMember(p2_name,["Nose","LeftEar","RightEar", ...
                    "Neck","Body","Tailbase","Port","CenterofHead"])}
            end
            arguments (Output)
                dist_out double
            end
            
            if (p1_name == "CenterofHead")
                p1 = this.CameraData.getHeadCenter();
            else
                p1(1) = this.CameraData.(p1_name).getX();
                p1(2) = this.CameraData.(p1_name).getY();
            end

            if (p2_name == "CenterofHead")
                p2 = this.CameraData.getHeadCenter();
            else
                p2(1) = this.CameraData.(p2_name).getX();
                p2(2) = this.CameraData.(p2_name).getY();
            end

            dist_out = this.CameraData.calcBehaviorDistance(p1,p2);
        end
        
        function out1 = getFrameIndex(this), out1 = this.Cam_Index; end

        function out1 = getFrameTimestamp(this), out1 = this.Cam_Timestamp; end

        function [validity, reason] = getValidity(this)
            validity = this.isValid;
            reason = 'valid';
            if(~this.isValid)
                reason='likelihood';
            else
%                [x1, x2] = this.CameraData.getBoxSize();
                [x1, ~, ~] = this.CameraData.getBody();
                if(x1 <= CameraFrame.LEFT_INSET ...
                        || x1 >= (CameraFrame.WIDTH - CameraFrame.RIGHT_INSET))
                    validity = false;
                    reason='region';
                end
            end
        end
    end
    
    %% Save, Load
    methods (Static)
        function s = saveobj(obj)
            s = struct;
            s.Cam_Index = obj.Cam_Index;
            s.Cam_Timestamp = obj.Cam_Timestamp;
            s.CameraData = obj.CameraData;
            s.isValid = obj.isValid;
        end

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