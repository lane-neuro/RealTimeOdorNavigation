classdef RealTimeOdorNavigation
    properties
        TrialDataset Trial
    end
    methods
        function obj = RealTimeOdorNavigation(data_files)
            import Trial
            if nargin == 1
                fprintf('Number of Trials Selected: %i\n', length(data_files)/2);
                
                for i = 1:length(data_files)/2
                    obj.TrialDataset(i) = Trial(data_files((i*2) - 1), data_files(i*2));
                end
            end
        end
        
        function out1 = GetDataStructForTrials(this, trial_num)
            for i = 1:length(trial_num)
                out1(i) = this.TrialDataset(trial_num(i)).GetDataStruct(false);
            end
        end
        
        function out1 = GetValidFramesForTrials(this, trial_num)
            for i = 1:length(trial_num)
                out1(i) = this.TrialDataset(trial_num(i)).GetDataStruct(true);
            end
        end
    end
end