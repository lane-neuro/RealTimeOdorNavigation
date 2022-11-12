classdef RealTimeOdorNavigation
    properties
        TrialDataset Trial
    end
    methods
        function obj = RealTimeOdorNavigation(data_files)
            import Trial
            if nargin == 1
                fprintf('Number of Trials Selected: %i\n', length(data_files)/2);
                for i = 1:length(data_files)/2, obj.TrialDataset(i) = Trial(data_files((i*2) - 1), data_files(i*2)); end
            end
        end
        
        function out1 = getDataStructForTrials(this, trials_in)
            for i = 1:length(trials_in), out1(i) = this.TrialDataset(trials_in(i)).getDataStruct(false); end
        end
        
        function out1 = findValidFramesForTrials(this, trials_in)
            for i = 1:length(trials_in), out1(i) = this.TrialDataset(trials_in(i)).getDataStruct(true); end
        end
    end
end