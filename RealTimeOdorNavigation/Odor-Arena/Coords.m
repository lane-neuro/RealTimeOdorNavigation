classdef Coords
    % This class holds coordinate data for RealTimeOdorNavigation
    %

    properties
        X double                        % x-axis value
        Y double                        % y-axis value
        Likelihood double               % DeepLabCut certainty evaluation
        isStatic logical
    end
    methods
        function obj = Coords(X_in, Y_in, Likelihood_in)
            % Creates and returns a Coords object
            %
            %   USAGE
            %       obj = Coords(X_in, Y_in, Likelihood_in)
            %
            %   OUTPUT PARAMETERS
            %       obj                 -   Coords object
            %

            arguments (Input)
                X_in double = 0             % x-axis value
                Y_in double = 0             % y-axis value
                Likelihood_in double = 0    % DeepLabCut certainty evaluation
            end

            obj.X = X_in;
            obj.Y = Y_in;

            if (nargin == 2)
                obj.isStatic = true;

            elseif (nargin == 3)
                obj.isStatic = false;
                obj.Likelihood = Likelihood_in;
            end

        end
        
        function x = getX(this), x = this.X; end
        function y = getY(this), y = this.Y; end
        
        function likelihood = getLikelihood(this)
            if this.isStatic, likelihood = 0; else, likelihood = this.Likelihood; end
        end
        
        function [x, y, likelihood] = getCoord(this)
            % Returns [x, y, likelihood] for Coord obj
            %
            %   USAGE
            %       [x, y, likelihood] = this.getCoord()
            %       [x, y, likelihood] = getCoord(this)
            %
            %   INPUT PARAMETERS
            %       this                 -   Coords object
            %
            %   OUTPUT PARAMETERS
            %       x                    
            %       y                    
            %       likelihood           -   DeepLabCut certainty evaluation
            %

            x = this.getX();
            y = this.getY();
            likelihood = this.getLikelihood();
        end
    end
    
    %% Save, Load
    methods (Static)
        function s = saveobj(obj)
            s = struct;
            s.X = obj.X;
            s.Y = obj.Y;
            s.Likelihood = obj.Likelihood;
            s.isStatic = obj.isStatic;
        end

        function obj = loadobj(s)
            if isstruct(s)
                newobj = Coords();
                newobj.X = s.X;
                newobj.Y = s.Y;
                newobj.Likelihood = s.Likelihood;
                newobj.isStatic = s.isStatic;
                obj = newobj;
            else
                obj = s;
            end
        end
    end
end