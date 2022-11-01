classdef RealTimeOdorNavigation
    properties
        TrialData Trial
    end
    methods
        function obj = RealTimeOdorNavigation(data_files)
            import Trial
            if nargin == 1
                fprintf('Number of Trials Selected: %i\n', length(data_files)/2);
                
                for i = 1:length(data_files)/2
                    obj.TrialData(i) = Trial(data_files((i*2) - 1), data_files(i*2));
                end
            end
        end
    end
end