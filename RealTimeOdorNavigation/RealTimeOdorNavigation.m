classdef RealTimeOdorNavigation < handle
    % RealTimeOdorNavigation    This class serves as the base for RealTimeOdorNavigation
    % 

    properties (Constant, Hidden = true)
        X = 9
        Y = 79
        WIDTH = 564
        HEIGHT = 256
    end % Crop Parameters

    properties
        TrialDataset Trial      % array of Trial objects
        BackgroundData double   % CMap of mean pixel representation of all Trial arenas
        ProjectPath char        % depicts project folder location on hard drive
    end

    methods
        function obj = RealTimeOdorNavigation(in1, ~)
            % Creates and returns a RealTimeOdorNavigation object
            %
            %   USAGE
            %       obj = RealTimeOdorNavigation()
            %
            %   INPUT PARAMETERS
            %       in1                 -   (ignore) struct loaded from MAT-file
            %       ~                   -   (ignore)
            %
            %   OUTPUT PARAMETERS
            %       obj                 -   RealTimeOdorNavigation object
            %
            %   DETAILS
            %       Do not pass input to RealTimeOdorNavigation(); Load a saved project
            %       by dragging the previously saved .mat file into the Workspace.

            if (nargin == 2)
                if isstruct(in1)
                    fprintf('[RTON] Loading Trials from Dataset File\n');
                    obj.TrialDataset = in1.TrialDataset;
                    obj.BackgroundData = in1.BackgroundData;
                    obj.ProjectPath = in1.ProjectPath;
                end

            elseif (nargin == 1)
                in_size = length(in1);
                total = 1 : in_size;

                in1_str = in1(total(mod(total, 2) ~= 0));
                in1_str2 = in1(total(mod(total, 2) == 0));
                [path, ~, ~] = fileparts(in1_str{1});
                obj.ProjectPath = strcat(path, '\MATLAB_DATA');
                cd(obj.ProjectPath);

                fprintf('[RTON] Number of Trials Being Processed: %i\n', in_size / 2);
                d_set(in_size / 2) = Trial();

                parfor ii = 1 : (in_size / 2)
                    d_set(ii) = Trial(in1_str(1,ii), in1_str2(1,ii));
                    fprintf('[RTON] ----- Trial Iteration [ %i ] Processed -----\n', ii);
                end
                obj.TrialDataset = d_set;
                
                obj.BackgroundData = zeros(256, 564);
                nTrials = numel(obj.TrialDataset);
                for jj = 1 : nTrials
                    obj.BackgroundData = obj.BackgroundData + ...
                        obj.TrialDataset(jj).BackgroundData;
                end
                obj.BackgroundData = obj.BackgroundData / nTrials;

            else
                fprintf('[RTON] Novel Dataset Analysis..\n');

                [file, path] = uigetfile('*.csv;*.mat', 'MultiSelect', 'on');
                if iscell(file), [~, nFiles] = size(file); 
                else, [nFiles, ~] = size(file); end

                if (nFiles > 0)
                    obj.ProjectPath = strcat(path(1:end),'\MATLAB_DATA');
                    mkdir(obj.ProjectPath);
                    cd(obj.ProjectPath);

                    if (nFiles == 1)
                        files = strings(nFiles * 2, 0);
                        [path, name, ext] = fileparts(fullfile(path, file));

                        if (isequal(ext, '.mat'))
                            obj = load(char(fullfile(path, strcat(name, ext))));
                            return;

                        elseif (isequal(ext, '.csv'))
                            files(1) = strcat(path, '\', ...
                                extractBefore(name,'_reencoded'), '.avi.dat');
                            files(2) = strcat(path, '\', name, ext);
                            obj = RealTimeOdorNavigation(files);
                        end

                    else
                        files = strings(nFiles * 2, 0);
                        for jj = 1 : nFiles
                            [path, name, ext] = fileparts(char(fullfile(path, ...
                                file(1, jj))));
                            files(jj * 2) = strcat(path, '\', name, ext);
                            files((jj * 2) - 1) = strcat(path, '\', ...
                                extractBefore(name,'_reencoded'), '.avi.dat');
                        end

                        obj = RealTimeOdorNavigation(files);
                    end

                else
                    fprintf('[RTON] User cancelled file selection.');
                end
            end
        end
        
        %% Get & Find Methods
        function data_out = getDataForTrials(this, iTrials, options)
            % GETDATAFORTRIALS   Returns readable struct of Trial data
            %
            %   USAGE
            %       data_out = this.getDataForTrials(iTrials, options)
            %

            arguments (Input)
                this RealTimeOdorNavigation             % RealTimeOdorNavigation object
                iTrials                                 % array or range of Trial indices
                options.OnlyValid logical = true        % only return valid frames
                options.OnlyInvalid logical = false     % only return invalid frames
                options.EthOutput logical = true        % include EthSensor data
                options.AccOutput logical = true        % include Accelerometer data
            end
            
            nTrials = length(iTrials);
            data_out = repmat(struct('Date', {}, 'SubjectID', {}, 'VideoPath', {}, ...
                'Name', {}, 'PositionData', struct, 'ArenaData', [], ...
                'EthData', struct, 'AccData', struct), nTrials, 1);
            if (~options.EthOutput), data_out = rmfield(data_out,'EthData'); end
            if (~options.AccOutput), data_out = rmfield(data_out,'AccData'); end

            for ii = 1 : nTrials
                data_out(ii) = this.TrialDataset(iTrials(ii)).getDataStruct( ...
                    OnlyValid = options.OnlyValid, OnlyInvalid = options.OnlyInvalid, ...
                    EthOutput = options.EthOutput, AccOutput = options.AccOutput);
            end
        end
        
        function imgs = getImagesForFramesInTrial(this, iTrials, iFrames)
            % GETIMAGESFORFRAMESINTRIAL   Returns image struct for frame(s) in Trial(s)
            %
            %   USAGE
            %       imgs = this.getImagesForFramesInTrial(iTrials, iFrames)
            %

            arguments (Input)
                this RealTimeOdorNavigation             % RealTimeOdorNavigation object
                iTrials                                 % array or range of Trial indices
                iFrames                                 % array or range of frame indices
            end

            imgs = this.TrialDataset(iTrials).getImagesForFrames(iFrames);
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