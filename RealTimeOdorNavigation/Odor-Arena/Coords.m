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
    end
end