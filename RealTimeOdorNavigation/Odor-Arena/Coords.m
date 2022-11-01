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
        
        function x = GetX(input, lh)
            if lh && ~input.isStatic
                x = [input.X, input.GetLikelihood()];
            else
                x = input.X;
            end
        end
        
        function y = GetY(input, lh)
            if lh && ~input.isStatic
                y = [input.Y, input.GetLikelihood()];
            else
                y = input.Y;
            end
        end
        
        function likelihood = GetLikelihood(input)
            if input.isStatic
                likelihood = 0;
            else
                likelihood = input.Likelihood;
            end
        end
        
        function [output] = GetCoord(input, lh)
            output(1) = input.GetX();
            output(2) = input.GetY();
            if lh
                output(3) = input.GetLikelihood();
            end
        end
    end
end