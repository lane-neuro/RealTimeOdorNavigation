classdef RealTimeOdorNavigation
    properties (Constant, Hidden = true)
        % Crop Parameters
        X = 9
        Y = 79
        WIDTH = 564
        HEIGHT = 256
    end
    properties
        TrialDataset Trial
    end
    methods
        function obj = RealTimeOdorNavigation(in1, ~)
            if nargin == 2
                if isstruct(in1)
                    fprintf('[RTON] Loading Trials from Dataset File\n');
                    obj.TrialDataset = in1.TrialDataset;
                end
            elseif nargin == 1
                fprintf('[RTON] Number of Trials Being Processed: %i\n', length(in1)/2);
                for ii = 1:length(in1)/2, obj.TrialDataset(ii) = Trial(in1((ii*2) - 1), in1(ii*2)); end
            else
                fprintf('[RTON] Empty RTON Constructor\n');
                prevFolder = pwd;
                cd('C:\Users\girelab\2022TrialData')
                [file, ~] = uigetfile('*.csv;*.dat;*.mat', 'MultiSelect', 'on');
                for ii = 1:numel(file), files(ii) = dir(char(file(ii))); end
                obj = RealTimeOdorNavigation(files);
                cd(prevFolder);
            end
        end
        
        function s = saveobj(obj)
            fprintf('[RTON] Saving Dataset..\n');
            s = struct;
            s.TrialDataset = obj.TrialDataset;
        end
        
        %% Get & Find Methods
        function out1 = getDataStructForTrials(this, trials_in)
            out1 = struct('Date', {}, 'SubjectID', {}, 'VideoPath', {}, 'PositionData', {}, 'ArenaData', {}, 'EthData', {}, 'AccData', {});
            for ii = 1:length(trials_in), out1(ii) = this.TrialDataset(trials_in(ii)).getDataStruct(false); end
        end
        
        function out1 = findValidFramesForTrials(this, trials_in)
            out1 = struct('Date', {}, 'SubjectID', {}, 'VideoPath', {}, 'PositionData', {}, 'ArenaData', {}, 'EthData', {}, 'AccData', {});
            for ii = 1:length(trials_in), out1(ii) = this.TrialDataset(trials_in(ii)).getDataStruct(true); end
        end
        
        function imgs = getImagesForFramesInTrial(this, trial_in, iframes)
            imgs = this.TrialDataset(trial_in).getImagesForFrames(iframes);
        end
    end
    
    %% 
    methods (Static)
        function obj = loadobj(s)
            if isstruct(s)
                fprintf('[RTON] Loading Dataset..\n');
                struct_out = struct('TrialDataset', s.TrialDataset);
                obj = RealTimeOdorNavigation(struct_out, 0);
            else
                obj = s;
            end
        end
    end
end