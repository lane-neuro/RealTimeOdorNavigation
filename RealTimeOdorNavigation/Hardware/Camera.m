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
        function out1 = getAllPoints(this, inc_likelihood, inc_port)
            if inc_port
                x = zeros(0,7);
                y = zeros(0,7);
                [x(7), y(7)] = this.getPort();
            else
                x = zeros(0,6);
                y = zeros(0,6);
            end
            [x(1), y(1)] = this.getNose();
            [x(2), y(2)] = this.getLeftEar();
            [x(3), y(3)] = this.getRightEar();
            [x(4), y(4)] = this.getNeck();
            [x(5), y(5)] = this.getBody();
            [x(6), y(6)] = this.getTailbase();
            out1 = [x' y'];
            if inc_likelihood
                lh = this.getAllLikelihoods(inc_port);
                out1 = [x' y' lh'];
            end
        end
        
        function likelihoods = getAllLikelihoods(this, inc_port)            
            if inc_port
                likelihoods = zeros(0,7);
                likelihoods(7) = this.Port.getLikelihood();
            else, likelihoods = zeros(0,6); end
            likelihoods(1) = this.Nose.getLikelihood();
            likelihoods(2) = this.LeftEar.getLikelihood();
            likelihoods(3) = this.RightEar.getLikelihood();
            likelihoods(4) = this.Neck.getLikelihood();
            likelihoods(5) = this.Body.getLikelihood();
            likelihoods(6) = this.Tailbase.getLikelihood();
        end
        
        %% Part Get Methods
        function [x, y, lh] = getNose(this), [x, y, lh] = this.Nose.getCoord(); end
        function [x, y, lh] = getLeftEar(this), [x, y, lh] = this.LeftEar.getCoord(); end        
        function [x, y, lh] = getRightEar(this), [x, y, lh] = this.RightEar.getCoord(); end
        function [x, y, lh] = getNeck(this), [x, y, lh] = this.Neck.getCoord(); end
        function [x, y, lh] = getBody(this), [x, y, lh] = this.Body.getCoord(); end        
        function [x, y, lh] = getTailbase(this), [x, y, lh] = this.Tailbase.getCoord(); end
        function [x, y, lh] = getPort(this), [x, y, lh] = this.Port.getCoord(); end
    end
end