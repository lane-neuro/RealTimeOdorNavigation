classdef RealTimeOdorNavigation < handle
    % RealTimeOdorNavigation    This class serves as the base for RealTimeOdorNavigation
    % 

    properties (Constant, Hidden = true)
        X = 9
        Y = 79
        WIDTH = 564
        HEIGHT = 256
    end % Crop Parameters

    properties (Hidden = true)
        IniFile IniConfig       % config file for RTON instance/project
        ProjectPath char        % project folder path on hard drive
    end

    properties
        TrialDataset Trial      % array of Trial objects
        BackgroundData double   % CMap of mean pixel representation of all Trial arenas
    end

    methods
        function obj = RealTimeOdorNavigation(in1, ~)
            % Creates and returns a RealTimeOdorNavigation object
            %
            %   USAGE
            %       obj = RealTimeOdorNavigation()
            %
            %   OUTPUT PARAMETERS
            %       obj                 -   RealTimeOdorNavigation object
            %
            %   DETAILS
            %       Do not pass input to RealTimeOdorNavigation(); Load a saved project
            %       by dragging the previously saved .mat file into the Workspace.

            import RealTimeOdorNavigation/deps/IniConfig.*
            if (nargin == 2)
                if isstruct(in1)
                    fprintf('[RTON] Loading Trials from Dataset File\n');
                    obj.IniFile = in1.IniFile;
                    obj.IniFile = obj.loadConfig();
                    obj.ProjectPath = in1.ProjectPath;
                    obj.TrialDataset = in1.TrialDataset;
                    obj.BackgroundData = in1.BackgroundData;
                end

            elseif (nargin == 1)
                in_size = length(in1);
                total = 1 : in_size;

                in1_str = in1(total(mod(total, 2) ~= 0));
                in1_str2 = in1(total(mod(total, 2) == 0));
                [path, ~, ~] = fileparts(in1_str{1});
                obj.ProjectPath = strcat(path, '\MATLAB_DATA');
                cd(obj.ProjectPath);
                obj.IniFile = obj.createConfig();

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

                    obj.IniFile = obj.createConfig();

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
            %   INPUT PARAMETERS
            %       this                    -   RealTimeOdorNavigation object
            %       iTrials                 -   array or range of trial indices
            %
            %       optional arguments:
            %           Valid_Type          -   frame types: "valid", "invalid", or "all"
            %               (default: "valid")
            %           DAQ_Output          -   include DAQ data output
            %               (default: true)
            %           Validity_Verbose    -   validity per frame output
            %               (default: false)
            %           Port                -   port coords per frame
            %               (default: false)
            %           Likelihood          -   likelihood per frame output
            %               (default: false)

            arguments (Input)
                this RealTimeOdorNavigation    
                iTrials                                 
                options.Valid_Type string {mustBeMember(options.Valid_Type, ...
                    ["valid","invalid","all"])} = "valid"
                options.DAQ_Output logical = true
                options.Validity_Verbose logical = false
                options.Port logical = false
                options.Likelihood logical = false
            end
            
            nTrials = length(iTrials);

            data_out = repmat(struct('TrialDate', {}, 'SubjectID', {}, ...
                'VideoPath', {}, 'Name', {}, 'PositionData', struct, 'ArenaData', [], ...
                'DaqData', struct), nTrials, 1);
            if (~options.DAQ_Output), data_out = rmfield(data_out,'DaqData'); end

            for ii = 1 : nTrials
                data_out(ii) = this.TrialDataset(iTrials(ii)).getDataStruct( ...
                    Valid_Type=options.Valid_Type, DAQ_Output=options.DAQ_Output, ...
                    Validity_Verbose=options.Validity_Verbose, Port=options.Port, ...
                    Likelihood=options.Likelihood);
            end
        end

        function vel_out = getSpeedForFramesInTrials(this, iTrials, iFrames)
            % GETSPEEDFORFRAMESINTRIALS   Returns velocity array for frame(s) in Trial(s)
            %
            %   USAGE
            %       vel_out = this.getSpeedForFramesInTrials(iTrials, iFrames)
            %
            %   INPUT PARAMETERS
            %       this                    -   RealTimeOdorNavigation object
            %       iTrials                 -   array or range of trial indices
            %       iFrames                 -   array or range of frame indices
            %

            arguments (Input)
                this RealTimeOdorNavigation
                iTrials
                iFrames
            end

            vel_out = this.TrialDataset(iTrials).calcFrameVelocity(iFrames);
        end
        
        function imgs = getImagesForFramesInTrial(this, iTrials, iFrames)
            % GETIMAGESFORFRAMESINTRIAL   Returns image struct for frame(s) in Trial(s)
            %
            %   USAGE
            %       imgs = this.getImagesForFramesInTrial(iTrials, iFrames)
            %
            %   INPUT PARAMETERS
            %       this                    -   RealTimeOdorNavigation object
            %       iTrials                 -   array or range of trial indices
            %       iFrames                 -   array or range of frame indices
            %

            arguments (Input)
                this RealTimeOdorNavigation
                iTrials
                iFrames
            end

            imgs = this.TrialDataset(iTrials).getImagesForFrames(iFrames);
        end

        function t_Out = filterTrialset(this, filter_type, data_in, options)
            % FILTERTRIALSET   Filters & returns n-sized matrix of Trial objects 
            %
            %   USAGE
            %       t_Out = this.filterTrialset(filter_type, data_in, options)
            %
            %   INPUT PARAMETERS
            %       this                -   RealTimeOdorNavigation object
            %       filter_type         -   filter types:   "byDate", "bySubjectNo"
            %       data_in             -   must be of type:
            %                                   uint16: subject id number
            %                                   datetime: datetime matrix [earliest last]
            %
            %       optional arguments:
            %           trials_in       -   pass existing matrix of trials as seed
            %               (default: all trials in dataset)

            arguments (Input)
                this RealTimeOdorNavigation
                filter_type string ...
                    {mustBeMember(filter_type, ...
                    ["byDate", ...
                    "bySubjectNo" ...
                    ])}
                data_in {mustBeA(data_in, ...           
                    ["double", ...
                    "datetime", ...
                    ])}
                options.trials_in(:,1) {mustBeA(options.trials_in, ["Trial"])} ...
                    = this.TrialDataset
            end

            t_set = options.trials_in;
            switch(filter_type)
                case "byDate"
                    tf = isbetween([t_set.TrialDate], data_in(1), data_in(2));
                case "bySubjectNo"
                    tf = [t_set.SubjectID] == data_in;
            end
            t_Out = t_set(tf);
        end

        function [ini_out] = loadConfig(this)
            % LOADCONFIG   Helper function to load an .ini file
            %
            %   USAGE
            %       ini_out = this.loadConfig()
            %
            %   INPUT PARAMETERS
            %       this                -   RealTimeOdorNavigation object

            f_name = strcat(Trial.ConfigPrefix, 'RTON.ini');
            key_names = {'PROJECT_PATH'};
            ini_out = IniConfig();

            bExists = ini_out.ReadFile(f_name);
            if (~bExists), ini_out = this.createConfig(); end
            sections = ini_out.GetSections();
            [this.ProjectPath, ~] = ini_out.GetValues(sections{1}, key_names{1});
            cd(this.ProjectPath);
        end

        function [ini_out] = createConfig(this)
            % CREATECONFIG   Helper function to create an .ini file
            %
            %   USAGE
            %       ini_out = this.createConfig()
            %
            %   INPUT PARAMETERS
            %       this                -   RealTimeOdorNavigation object

            prevFolder = pwd;
            cd(this.ProjectPath);

            f_name = strcat(Trial.ConfigPrefix, 'RTON.ini');

            ini_out = IniConfig();
            ini_out.AddSections('File-Naming & Organization');
            key_names = {'PROJECT_PATH'};
            key_values = {this.ProjectPath};
            ini_out.AddKeys('File-Naming & Organization', key_names, key_values);
            ini_out.WriteFile(f_name);
            cd(prevFolder);
        end

    end
    
    %% Save, Load
    methods (Static)
        function s = saveobj(obj)
            fprintf('[RTON] Saving Dataset..\n');
            s = struct;
            s.TrialDataset = obj.TrialDataset;
            s.IniFile = obj.IniFile;
            s.BackgroundData = obj.BackgroundData;
            s.ProjectPath = obj.ProjectPath;
        end

        function obj = loadobj(s)
            if isstruct(s)
                fprintf('[RTON] Loading Dataset..\n');
                struct_out = struct;
                struct_out.TrialDataset = s.TrialDataset;
                struct_out.IniFile = s.IniFile;
                struct_out.BackgroundData = s.BackgroundData;
                struct_out.ProjectPath = s.ProjectPath;
                cd(struct_out.ProjectPath);
                obj = RealTimeOdorNavigation(struct_out, 0);
                obj.loadConfig();
            else
                obj = s;
            end
        end
    end
end