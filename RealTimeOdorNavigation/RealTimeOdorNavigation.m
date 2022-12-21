classdef RealTimeOdorNavigation < handle
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
                if iscell(file), [~, nFiles] = size(file); else, [nFiles, ~] = size(file); end
                if nFiles == 0
                    fprintf('[RTON] User cancelled file selection.');
                else
                    if nFiles == 1
                        files = strings(nFiles*2, 0);
                        [path,name,ext] = fileparts(fullfile(path, file));
                        if isequal(ext, '.mat')
                            obj = load(char(fullfile(path, strcat(name, ext))));
                            return;
                        elseif isequal(ext, '.csv')
                            files(1) = strcat(path, '\', name, '.avi.dat');
                            files(2) = strcat(path, '\', name, ext);
                            obj = RealTimeOdorNavigation(files);
                        end
                    else
                        files = strings(nFiles*2, 0);
                        for jj = 1:nFiles
                            [path,name,ext] = fileparts(char(fullfile(path, file(1,jj))));
                            files(jj*2) = strcat(path, '\', name, ext);
                            files((jj*2)-1) = strcat(path, '\', name, '.avi.dat');
                        end
                        obj = RealTimeOdorNavigation(files);
                    end
                end
                cd(prevFolder);
            end
        end
        
        %% Get & Find Methods
        function out1 = getDataForTrials(this, trial_index, options)
            arguments (Input)
                this RealTimeOdorNavigation
                trial_index
                options.OnlyValid logical = true
                options.EthOutput logical = true
                options.AccOutput logical = true
            end

            out1 = struct('Date', {}, 'SubjectID', {}, 'VideoPath', {}, 'PositionData', {}, 'ArenaData', {}, 'EthData', {}, 'AccData', {});
            for ii = 1:length(trial_index), out1(ii) = this.TrialDataset(trial_index(ii)).getDataStruct(OnlyValid=options.OnlyValid, EthOutput=options.EthOutput, AccOutput=options.AccOutput); end
        end
        
        function imgs = getImagesForFramesInTrial(this, trial_index, frames)
            arguments (Input)
                this RealTimeOdorNavigation
                trial_index
                frames
            end

            imgs = this.TrialDataset(trial_index).getImagesForFrames(frames);
        end
    end
    
    %% Save, Load
    methods (Static)
        function s = saveobj(obj)
            fprintf('[RTON] Saving Dataset..\n');
            s = struct;
            s.TrialDataset = obj.TrialDataset;
        end

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