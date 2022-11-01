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
        function [animal] = GetAllPoints(input, inc_likelihood, inc_port)
            animal(1) = input.GetNose(inc_likelihood);
            animal(2) = input.GetLeftEar(inc_likelihood);
            animal(3) = input.GetRightEar(inc_likelihood);
            animal(4) = input.GetNeck(inc_likelihood);
            animal(5) = input.GetBody(inc_likelihood);
            animal(6) = input.GetTailbase(inc_likelihood);
            if inc_port
                animal(7) = input.GetPort(inc_likelihood);
            end
        end
        
        function [likelihoods] = GetAllLikelihoods(input, inc_port)
            likelihoods(1) = input.Nose.GetLikelihood();
            likelihoods(2) = input.LeftEar.GetLikelihood();
            likelihoods(3) = input.RightEar.GetLikelihood();
            likelihoods(4) = input.Neck.GetLikelihood();
            likelihoods(5) = input.Body.GetLikelihood();
            likelihoods(6) = input.Tailbase.GetLikelihood();
            if inc_port
                likelihoods(7) = input.Port.GetLikelihood();
            end
        end
        
        %% Part Get Methods
        function nose = GetNose(input, lh)
            nose = input.Nose.GetCoord(lh);
        end
        
        function l_ear = GetLeftEar(input, lh)
            l_ear = input.LeftEar.GetCoord(lh);
        end
        
        function r_ear = GetRightEar(input, lh)
            r_ear = input.RightEar.GetCoord(lh);
        end
        
        function neck = GetNeck(input, lh)
            neck = input.Neck.GetCoord(lh);
        end
        
        function body = GetBody(input, lh)
            body = input.Body.GetCoord(lh);
        end
        
        function tailbase = GetTailbase(input, lh)
            tailbase = input.Tailbase.GetCoord(lh);
        end
        
        function port = GetPort(input, lh)
            port = input.Port.GetCoord(lh);
        end
    end
end