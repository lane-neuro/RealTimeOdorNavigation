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
                for ii = 1:length(in1)/2
                    obj.TrialDataset(ii) = Trial(in1((ii*2) - 1), in1(ii*2));
                end
            else
                fprintf('[RTON] Novel Dataset Analysis..\n');
                prevFolder = pwd;
                cd('C:\Users\girelab\2022.12.06_Tariq-Lane\2022_RTON-Data');
                [file, path] = uigetfile('*.csv;*.mat', 'MultiSelect', 'on');
                [nFiles, ~] = size(file);
                if nFiles == 0
                    fprintf('[RTON] User cancelled file selection.');
                else
                    if nFiles == 1
                        files = strings(nFiles*2, 0);
                        [path,name,ext] = fileparts(fullfile(path, file));
                        if isequal(ext, '.mat')
                            obj = load(fullfile(path, strcat(name, ext)));
                            return;
                        elseif isequal(ext, '.csv')
                            files(1) = strcat(path, '\', name, '.avi.dat');
                            files(2) = strcat(path, '\', name, ext);
                            obj = RealTimeOdorNavigation(files);
                        end
                    else
                        files = strings(nFiles*2, 0);
                        for jj = 1:nFiles
                            [path,name,ext] = fileparts(fullfile(path(jj), file(jj)));
                            files(jj*2) = strcat(path, '\', name, ext);
                            files((jj*2)-1) = strcat(path, '\', name, '.avi.dat');
                        end
                        obj = RealTimeOdorNavigation(files);
                    end
                end
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