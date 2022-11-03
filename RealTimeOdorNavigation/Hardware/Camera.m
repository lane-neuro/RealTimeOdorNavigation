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
        function output = GetAllPoints(input, inc_likelihood, inc_port)
            if inc_port
                x = zeros(0,7);
                y = zeros(0,7);
                [x(7), y(7)] = input.GetPort();
            else
                x = zeros(0,6);
                y = zeros(0,6);
            end
            [x(1), y(1)] = input.GetNose();
            [x(2), y(2)] = input.GetLeftEar();
            [x(3), y(3)] = input.GetRightEar();
            [x(4), y(4)] = input.GetNeck();
            [x(5), y(5)] = input.GetBody();
            [x(6), y(6)] = input.GetTailbase();
            output = [x' y'];
            if inc_likelihood
                lh = input.GetAllLikelihoods(inc_port);
                output = [x' y' lh'];
            end
        end
        
        function likelihoods = GetAllLikelihoods(input, inc_port)            
            if inc_port
                likelihoods = zeros(0,7);
                likelihoods(7) = input.Port.GetLikelihood();
            else
                likelihoods = zeros(0,6);
            end
            likelihoods(1) = input.Nose.GetLikelihood();
            likelihoods(2) = input.LeftEar.GetLikelihood();
            likelihoods(3) = input.RightEar.GetLikelihood();
            likelihoods(4) = input.Neck.GetLikelihood();
            likelihoods(5) = input.Body.GetLikelihood();
            likelihoods(6) = input.Tailbase.GetLikelihood();
        end
        
        %% Part Get Methods
        function [x, y, lh] = GetNose(input)
            [x, y, lh] = input.Nose.GetCoord();
        end
        
        function [x, y, lh] = GetLeftEar(input)
            [x, y, lh] = input.LeftEar.GetCoord();
        end
        
        function [x, y, lh] = GetRightEar(input)
            [x, y, lh] = input.RightEar.GetCoord();
        end
        
        function [x, y, lh] = GetNeck(input)
            [x, y, lh] = input.Neck.GetCoord();
        end
        
        function [x, y, lh] = GetBody(input)
            [x, y, lh] = input.Body.GetCoord();
        end
        
        function [x, y, lh] = GetTailbase(input)
            [x, y, lh] = input.Tailbase.GetCoord();
        end
        
        function [x, y, lh] = GetPort(input)
            [x, y, lh] = input.Port.GetCoord();
        end
    end
end