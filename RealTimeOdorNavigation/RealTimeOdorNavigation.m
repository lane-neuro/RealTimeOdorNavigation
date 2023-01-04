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
        BackgroundData double
        ProjectPath char
    end
    methods
        function obj = RealTimeOdorNavigation(in1, ~)
            if nargin == 2
                if isstruct(in1)
                    fprintf('[RTON] Loading Trials from Dataset File\n');
                    obj.TrialDataset = in1.TrialDataset;
                    obj.BackgroundData = in1.BackgroundData;
                    obj.ProjectPath = in1.ProjectPath;
                end
            elseif nargin == 1
                in_size = length(in1);
                total = 1:in_size;
                in1_str = in1(total(mod(total,2)~=0));
                in1_str2 = in1(total(mod(total,2)==0));
                [path,~,~] = fileparts(in1_str{1});
                obj.ProjectPath = strcat(path,'\MATLAB_DATA');
                cd(obj.ProjectPath);

                fprintf('[RTON] Number of Trials Being Processed: %i\n', in_size/2);
                d_set(in_size/2) = Trial();

                parfor ii = 1:in_size/2
                    d_set(ii) = Trial(in1_str(ii), in1_str2(ii));
                    fprintf('[RTON] ----- Trial Iteration [ %i ] Processed -----\n', ii);
                end
                obj.TrialDataset = d_set;
                
                obj.BackgroundData = zeros(256, 564);
                for jj = 1:numel(obj.TrialDataset)
                    obj.BackgroundData = obj.BackgroundData + obj.TrialDataset(jj).BackgroundData;
                end
                obj.BackgroundData = obj.BackgroundData/numel(obj.TrialDataset);

            else
                fprintf('[RTON] Novel Dataset Analysis..\n');
                [file, path] = uigetfile('*.csv;*.mat', 'MultiSelect', 'on');
                if iscell(file), [~, nFiles] = size(file); else, [nFiles, ~] = size(file); end
                if nFiles == 0
                    fprintf('[RTON] User cancelled file selection.');
                else
                    obj.ProjectPath = strcat(path{1},'\MATLAB_DATA');
                    cd(obj.ProjectPath);
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
            end
        end
        
        %% Get & Find Methods
        function out1 = getDataForTrials(this, trial_index, options)
            arguments (Input)
                this RealTimeOdorNavigation
                trial_index
                options.OnlyValid logical = true
                options.OnlyInvalid logical = false
                options.EthOutput logical = true
                options.AccOutput logical = true
            end
            
            out1 = repmat(struct('Date', {}, 'SubjectID', {}, 'VideoPath', {}, 'Name', {}, 'PositionData', struct, 'ArenaData', [], 'EthData', struct, 'AccData', struct), length(trial_index), 1);
            if ~options.EthOutput, out1 = rmfield(out1,'EthData'); end
            if ~options.AccOutput, out1 = rmfield(out1,'AccData'); end

            for ii = 1:length(trial_index)
                out1(ii) = this.TrialDataset(trial_index(ii)).getDataStruct(OnlyValid=options.OnlyValid, OnlyInvalid = options.OnlyInvalid, EthOutput=options.EthOutput, AccOutput=options.AccOutput);
            end
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
            s.BackgroundData = obj.BackgroundData;
            s.ProjectPath = obj.ProjectPath;
        end

        function obj = loadobj(s)
            if isstruct(s)
                fprintf('[RTON] Loading Dataset..\n');
                struct_out = struct;
                struct_out.TrialDataset = s.TrialDataset;
                struct_out.BackgroundData = s.BackgroundData;
                struct_out.ProjectPath = s.ProjectPath;
                cd(struct_out.ProjectPath);
                obj = RealTimeOdorNavigation(struct_out, 0);
            else
                obj = s;
            end
        end
    end
end