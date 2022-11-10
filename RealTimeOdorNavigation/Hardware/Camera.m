classdef Camera
    properties
        Nose Coords
        LeftEar Coords
        RightEar Coords
        Neck Coords
        Body Coords
        Tailbase Coords
        Port Coords
    end
    methods
        function obj = Camera(camera_frame_data)
            import Coords
            if nargin > 0
                obj.Nose = Coords(camera_frame_data(2), camera_frame_data(3), camera_frame_data(4));
                obj.LeftEar = Coords(camera_frame_data(5), camera_frame_data(6), camera_frame_data(7));
                obj.RightEar = Coords(camera_frame_data(8), camera_frame_data(9), camera_frame_data(10));
                obj.Neck = Coords(camera_frame_data(11), camera_frame_data(12), camera_frame_data(13));
                obj.Body = Coords(camera_frame_data(14), camera_frame_data(15), camera_frame_data(16));
                obj.Tailbase = Coords(camera_frame_data(17), camera_frame_data(18), camera_frame_data(19));
                obj.Port = Coords(camera_frame_data(20), camera_frame_data(21), camera_frame_data(22));
            end
        end
        
        %% Integration Get Method
        function out1 = GetAllPoints(in1, inc_likelihood, inc_port)
            if inc_port
                x = zeros(0,7);
                y = zeros(0,7);
                [x(7), y(7)] = in1.GetPort();
            else
                x = zeros(0,6);
                y = zeros(0,6);
            end
            [x(1), y(1)] = in1.GetNose();
            [x(2), y(2)] = in1.GetLeftEar();
            [x(3), y(3)] = in1.GetRightEar();
            [x(4), y(4)] = in1.GetNeck();
            [x(5), y(5)] = in1.GetBody();
            [x(6), y(6)] = in1.GetTailbase();
            out1 = [x' y'];
            if inc_likelihood
                lh = in1.GetAllLikelihoods(inc_port);
                out1 = [x' y' lh'];
            end
        end
        
        function likelihoods = GetAllLikelihoods(in1, inc_port)            
            if inc_port
                likelihoods = zeros(0,7);
                likelihoods(7) = in1.Port.GetLikelihood();
            else
                likelihoods = zeros(0,6);
            end
            likelihoods(1) = in1.Nose.GetLikelihood();
            likelihoods(2) = in1.LeftEar.GetLikelihood();
            likelihoods(3) = in1.RightEar.GetLikelihood();
            likelihoods(4) = in1.Neck.GetLikelihood();
            likelihoods(5) = in1.Body.GetLikelihood();
            likelihoods(6) = in1.Tailbase.GetLikelihood();
        end
        
        %% Part Get Methods
        function [x, y, lh] = GetNose(in1)
            [x, y, lh] = in1.Nose.GetCoord();
        end
        
        function [x, y, lh] = GetLeftEar(in1)
            [x, y, lh] = in1.LeftEar.GetCoord();
        end
        
        function [x, y, lh] = GetRightEar(in1)
            [x, y, lh] = in1.RightEar.GetCoord();
        end
        
        function [x, y, lh] = GetNeck(in1)
            [x, y, lh] = in1.Neck.GetCoord();
        end
        
        function [x, y, lh] = GetBody(in1)
            [x, y, lh] = in1.Body.GetCoord();
        end
        
        function [x, y, lh] = GetTailbase(in1)
            [x, y, lh] = in1.Tailbase.GetCoord();
        end
        
        function [x, y, lh] = GetPort(in1)
            [x, y, lh] = in1.Port.GetCoord();
        end
    end
end