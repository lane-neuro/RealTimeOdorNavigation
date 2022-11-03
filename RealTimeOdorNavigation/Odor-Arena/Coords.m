classdef Coords
    properties
        X double
        Y double
        Likelihood double
        isStatic logical
    end
    methods
        function obj = Coords(X_in, Y_in, Likelihood_in)
            if nargin == 2
                obj.isStatic = true;
                obj.X = X_in;
                obj.Y = Y_in;
            end
            if nargin == 3
                obj.isStatic = false;
                obj.X = X_in;
                obj.Y = Y_in;
                obj.Likelihood = Likelihood_in;
            end
        end
        
        function x = GetX(input)
            x = input.X;
        end
        
        function y = GetY(input)
            y = input.Y;
        end
        
        function likelihood = GetLikelihood(input)
            if input.isStatic
                likelihood = 0;
            else
                likelihood = input.Likelihood;
            end
        end
        
        function [x, y, likelihood] = GetCoord(input)
            x = input.GetX();
            y = input.GetY();
            likelihood = input.GetLikelihood();
        end
    end
end