classdef RealTimeOdorNavigation
    properties (Constant, Hidden = true)
        X = 9
        Y = 79
        WIDTH = 564
        HEIGHT = 256
    end
    properties
        TrialDataset Trial
    end
    methods
        function obj = RealTimeOdorNavigation(data_files)
            import Trial
            if nargin == 1
                fprintf('Number of Trials Selected: %i\n', length(data_files)/2);
                for ii = 1:length(data_files)/2, obj.TrialDataset(ii) = Trial(data_files((ii*2) - 1), data_files(ii*2)); end
            end
        end
        
        %% Get & Find Methods
        function out1 = getDataStructForTrials(this, trials_in)
            out1 = Trial.empty(length(trials_in),0);
            for ii = 1:length(trials_in), out1(ii) = this.TrialDataset(trials_in(ii)).getDataStruct(false); end
        end
        
        function out1 = findValidFramesForTrials(this, trials_in)
            out1 = Trial.empty(length(trials_in),0);
            for i = 1:length(trials_in), out1(i) = this.TrialDataset(trials_in(i)).getDataStruct(true); end
        end
        
        function imgs = getImagesForFramesInTrial(this, trial_in, iframes)
            imgs = this.TrialDataset(trial_in).getImagesForFrames(iframes);
        end
    end
end