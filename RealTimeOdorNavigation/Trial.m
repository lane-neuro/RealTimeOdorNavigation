classdef Trial < handle
    properties (Constant, Hidden = true)
        ConfigPrefix = 'config_'
        PositionPrefix = 'pos_'
        ArenaPrefix = 'arena_'
        EthPrefix = 'eth_'
        AccPrefix = 'acc_'
    end

    properties (Hidden = true)
        DATE_FORMAT = 'M-d-u-h-m a'
        BIN_FILE_EXT = '.avi.dat'
        POS_FILE_EXT = '.csv'
        IMAGE_EXT = '.png'
        VIDEO_FILE_SUFFIX = ...
            '_reencodedDLC_resnet50_odor-arenaOct3shuffle1_200000_labeled.mp4' % _filtered
        PositionFile
        ArenaFile
        EthFile
        AccFile
        IniFile
    end
    properties
        TrialDate datetime
        TrialNum uint16
        SubjectID uint16
        Name char
        VideoPath char
        BackgroundData double
    end
    methods
        %% Trial Constructor
        function obj = Trial(in1, in2)
            if nargin == 1
                if isstruct(in1)
                    obj.PositionFile = in1.PositionFile;
                    obj.ArenaFile = in1.ArenaFile;
                    obj.EthFile = in1.EthFile;
                    obj.AccFile = in1.AccFile;
                    obj.IniFile = in1.IniFile;

                    obj.TrialDate = in1.TrialDate;
                    obj.TrialNum = in1.TrialNum;
                    obj.SubjectID = in1.SubjectID;
                    obj.Name = in1.Name;
                    obj.VideoPath = in1.VideoPath;
                    obj.BackgroundData = in1.BackgroundData;
                    obj.loadConfig();
                end
            elseif nargin == 2
                [~, tempName1, ~] = fileparts(in1);
                [~, tempName2, ~] = fileparts(in2);
                %tempName1 = lower(tempName1);
                %tempName2 = lower(tempName2);
                tempName1{1} = tempName1{1}(1:end-4);
                %tempName1 = extractBefore(tempName1, '_reencoded');
                obj.Name = tempName1; % extractBefore(tempName1, '.avi');;;; _reencoded
                obj.VideoPath = strcat(obj.Name, obj.VIDEO_FILE_SUFFIX);
                obj.TrialDate = datetime(char(extractBefore(tempName2, '-M')), ...
                    'InputFormat', Trial.DATE_FORMAT);
                subStr = extractBetween(tempName2, "CB", "_");
                obj.SubjectID = str2num(char(extractBefore(subStr, '-')));
                obj.TrialNum = str2num(char(extractAfter(subStr, '-')));

                bCheckDataDirectory(obj, obj.Name);
                
                fprintf("[RTON] Parsing Positional Data...\n");
                [obj.PositionFile, obj.ArenaFile] = parsePositionData(obj, ...
                    obj.Name, obj.Name, strcat(tempName2, Trial.POS_FILE_EXT));
                
                % if strfind("eth") && file exist
                fprintf("[RTON] Parsing Ethanol & Accelerometer Data...\n");
                [obj.EthFile, obj.AccFile] = parseEthAccData(obj, ...
                    obj.Name, obj.Name, strcat(tempName1, Trial.ETH_ACC_EXT));
                % else eth/acc data = null

                fprintf("[RTON] Processing Field & Data Boundaries...\n");
                obj.BackgroundData = calcFieldBounds(obj);

                fprintf("[RTON] Trial Loaded: %s\n", obj.Name);
            end
        end
        
        %% Data Storage Methods
        function out1 = bCheckDataDirectory(this, name_in)
            out1 = true;
            if ~isfolder(name_in) 
                mkdir(name_in);
                mkdir(name_in, 'images');
                mkdir(name_in, 'saved_data');

                this.IniFile = this.loadConfig();

                prevFolder = pwd;
                cd ..\
                copyfile(this.VideoPath, ...
                    strcat('MATLAB_DATA\\', name_in, '\\', this.VideoPath));
                fprintf('[RTON] Created Directory: %s\n', name_in);
                out1 = false;
                cd(prevFolder);
            end
        end
        
        function [ini_out] = loadConfig(this)
            % LOADCONFIG   Helper function to load an .ini file
            %
            %   USAGE
            %       ini_out = this.loadConfig()
            %
            %   INPUT PARAMETERS
            %       this                -   RealTimeOdorNavigation object

            cd(this.Name);
            f_name = strcat(Trial.ConfigPrefix, this.Name, '.ini');
            key_names = {'DATE_FORMAT', 'BIN_FILE_EXT', 'POS_FILE_EXT', 'IMAGE_EXT'};
            ini_out = IniConfig();

            bExists = ini_out.ReadFile(f_name);
            if (~bExists), ini_out = this.createConfig(); end
            sections = ini_out.GetSections();
            [this.DATE_FORMAT, ~] = ini_out.GetValues(sections{1}, key_names{1});
            [this.BIN_FILE_EXT, ~] = ini_out.GetValues(sections{1}, key_names{2});
            [this.POS_FILE_EXT, ~] = ini_out.GetValues(sections{1}, key_names{3});
            [this.IMAGE_EXT, ~] = ini_out.GetValues(sections{1}, key_names{4});
            cd ..\
        end

        function [ini_out] = createConfig(this)
            % CREATECONFIG   Helper function to create an .ini file
            %
            %   USAGE
            %       ini_out = this.createConfig()
            %
            %   INPUT PARAMETERS
            %       this                -   RealTimeOdorNavigation object

            f_name = strcat(Trial.ConfigPrefix, this.Name, '.ini');

            ini_out = IniConfig();
            ini_out.AddSections('File-Naming & Organization');
            key_names = {'DATE_FORMAT', 'BIN_FILE_EXT', 'POS_FILE_EXT', 'IMAGE_EXT'};
            key_values = {this.DATE_FORMAT, this.BIN_FILE_EXT, this.POS_FILE_EXT, ...
                this.IMAGE_EXT};
            ini_out.AddKeys('File-Naming & Organization', key_names, key_values);
            ini_out.WriteFile(f_name);
        end

        function [dataout, successout] = loadDataFile(~, dir_in, filename_in)
            prevFolder = pwd;
            cd(dir_in);
            filename_in = strcat(filename_in, '.mat');
            successout = true;
            if ~isfile(filename_in)
                save(filename_in, 'dir_in', '-v7.3');
                fprintf('[RTON] Created Data File: %s\n', filename_in);
                successout = false;
            end
            dataout = matfile(filename_in);
            dataout.Properties.Writable = true;
            cd(prevFolder);
        end
        
        function [posout, arenaout] = parsePositionData(this, dir_in, ...
                filename_in, camfile_name)
            [posout, existed] = loadDataFile(this, dir_in, ...
                strcat(Trial.PositionPrefix, filename_in));
            [arenaout, ~] = loadDataFile(this, dir_in, ...
                strcat(Trial.ArenaPrefix, filename_in));
            if ~existed
                cameraData = csvread(strcat('..\\', camfile_name), 3, 0);
                tempData = CameraFrame.empty(length(cameraData),0);
                for z = 1:length(cameraData)
                    tempData(z) = CameraFrame(cameraData(z, 1)+1, cameraData(z, :));
                end % camera data per frame

                posout.positionData = tempData;
                points = 1:500;
                arena(1) = Arena([median(cameraData(points, 23)) ...
                    median(cameraData(points,24)) median(cameraData(points,26)) ...
                    median(cameraData(points,27)) median(cameraData(points,29)) ...
                    median(cameraData(points,30)) median(cameraData(points,32)) ...
                    median(cameraData(points,33)) median(cameraData(points,20)) ...
                    median(cameraData(points,21))]);
                arenaout.arenaData = arena;
                clear cameraData
            end
        end
        
        function [ethout, accout] = parseEthAccData(this, dir_in, ...
                filename_in, ethaccdata_name)
            [ethout, existed] = loadDataFile(this, dir_in, ...
                strcat(Trial.EthPrefix, filename_in));
            [accout, ~] = loadDataFile(this, dir_in, ...
                strcat(Trial.AccPrefix, filename_in));
            if ~existed
                ethaccData = fread(fopen(strcat('..\\', ethaccdata_name)), ...
                    'float64','ieee-be');
                n_ten = find(ethaccData==-500);
                n_ten = n_ten(14:end);
                frame_stamp = uint32(ethaccData(n_ten+2));
                time_stamp = uint32(ethaccData(n_ten+1));
                ethData = ethaccData(n_ten+4);
                accData = [ethaccData(n_ten+9) ethaccData(n_ten+10) ethaccData(n_ten+8)];
                
                tempEth = ETH_Sensor.empty(length(ethData),0);
                tempAcc = Accelerometer.empty(length(accData),0);
                parfor ii = 1:length(ethData)
                    tempEth(ii) = ETH_Sensor(ethData(ii), ...
                        time_stamp(ii), frame_stamp(ii));
                    tempAcc(ii) = Accelerometer(accData(ii, :), ...
                        time_stamp(ii), frame_stamp(ii));
                end
                ethout.ethData = tempEth;
                accout.accData = tempAcc;
                clear ethaccData n_ten frame_stamp time_stamp ethData accData
            end
        end
        
        function [frame_data, pos_data] = getPositionData(this, iFrames, options)
            arguments (Input)
                this Trial
                iFrames
                options.PositionData = this.PositionFile.positionData;
            end

            pos_data = options.PositionData;
            frame_data = CameraFrame.empty(length(iFrames),0);
            for ii = 1:length(iFrames)
                frame_data(ii) = pos_data(iFrames(ii));
            end
        end
        
        function [eth_data, raw_data] = getEthData(this, indices, options)
            arguments (Input)
                this Trial
                indices
                options.EthData = this.EthFile.ethData
            end

            raw_data = options.EthData;
            eth_data = ETH_Sensor.empty(length(indices),0);
            for ii = 1:length(indices)
                eth_data(ii) = raw_data(indices(ii));
            end
        end
        
        function [acc_data, raw_data] = getAccData(this, indices, options)
            arguments (Input)
                this Trial
                indices
                options.AccData = this.AccFile.accData
            end

            raw_data = options.AccData;
            acc_data = Accelerometer.empty(length(indices),0);
            for ii = 1:length(indices)
                acc_data(ii) = raw_data(indices(ii));
            end
        end
        
        function dataout = getArenaData(this), dataout = this.ArenaFile.arenaData; end
        
        %% Ethanol Sensor Methods
        function [size_out, data_out] = getEthDataSize(this, options)
            arguments (Input)
                this Trial
                options.EthData = this.EthFile.ethData
            end

            data_out = options.EthData;
            [~, size_out] = size(data_out);
        end
        
        function out1 = getAllEthData(this, options)
            arguments (Input)
                this Trial
                options.EthData = this.EthFile.ethData
            end

            fprintf('[RTON] getAllEthData(): Init \n');
            [eth_size, ethData] = getEthDataSize(this, EthData=options.EthData);
            voltage = zeros(eth_size, 0);
            fprintf('[RTON] getAllEthData(): Collecting Ethanol Data \n');

            time = zeros(eth_size, 0);
            parfor ii = 1:eth_size
                [time(ii), voltage(ii)] = ethData(ii).getEthReading();
            end
            out1 = [time' voltage'];
        end
        
        %% Accelerometer Methods
        function [size_out, data_out] = getAccDataSize(this, options)
            arguments (Input)
                this Trial
                options.AccData = this.AccFile.accData;
            end

            data_out = options.AccData;
            [~, size_out] = size(data_out); 
        end
        
        function s_out = getAllAccelerometerData(this, options)
            arguments (Input)
                this Trial
                options.AccData = this.AccFile.accData
            end

            fprintf('[RTON] getAllAccelerometerData(): Init \n');
            [acc_size, accData] = getAccDataSize(this, AccData=options.AccData);
            x = zeros(acc_size, 0);
            y = zeros(acc_size, 0);
            z = zeros(acc_size, 0);

            fprintf('[RTON] getAllAccelerometerData(): Collecting Accelerometer Data \n');
            time = zeros(acc_size, 0);
            parfor ii = 1:acc_size
                [time(ii), x(ii), y(ii), z(ii)] = accData(ii).getAccReading();
            end
            s_out = [time' x' y' z'];
        end
        
        %% Position Data Methods
        function [size_out, data_out] = getPositionDataSize(this, options)
            arguments (Input)
                this Trial
                options.PositionData = this.PositionFile.positionData
            end

            data_out = options.PositionData;
            [~, size_out] = size(data_out); 
        end

        function v_out = calcFrameVelocity(this, frames, options)
            % CALCFRAMEVELOCITY   Calculates & returns instantaneous velocity for given
            %                     frames (pixels/second)
            %
            %   USAGE
            %       v_out = this.getVelocityBetweenFrames(frames)
            %
            %   INPUT PARAMETERS
            %       this                -   Trial object
            %       frames              -   array of frame indices
            %       
            %       optional arguments:
            %           PositionData    -   pass position data variable (saves exec time)
            %   
            %   OUTPUT PARAMETERS
            %       v_out               -   array of velocity calculations

            arguments (Input)
                this Trial
                frames
                options.PositionData = this.getPositionData(frames)
            end

            v_out = zeros(length(frames)-1,1);


            for ii = 1:length(frames)-1
                p1 = options.PositionData(ii).getFrameCoordinates();
                p2 = options.PositionData(ii+1).getFrameCoordinates();

                x1 = p1(5,1);
                y1 = p1(5,2);
                x2 = p2(5,1);
                y2 = p2(5,2);
                time_diff = (cast(options.PositionData(ii+1).getFrameIndex(),"double") ...
                    / 60) - (cast(options.PositionData(ii).getFrameIndex(), "double") ...
                    / 60); % unit: s
                position_traveled = sqrt((x2 - x1)^2 + (y2 - y1)^2);
                v_out(ii) = position_traveled / time_diff;
            end
        end
        
        function s_out = getCoordsForFrames(this, frames, options)
            arguments (Input)
                this Trial
                frames
                options.PositionData = this.getPositionData(frames)
                options.Likelihood logical = false
                options.Port logical = false
            end

            fprintf('[RTON] getCoordsForFrames(): Init \n');
            if ~options.Likelihood, columns_in = 2; else, columns_in = 3; end
            if ~options.Port, rows_in = 6; else, rows_in = 7; end

            s_out = zeros(rows_in, columns_in, length(frames));
            with_likelihood = options.Likelihood;
            with_port = options.Port;
            pos_data = options.PositionData;
            parfor ii = 1:length(frames)
                s_out(:,:,ii) = pos_data(ii).getFrameCoordinates( ...
                    Likelihood=with_likelihood, Port=with_port);
            end
        end
        
        function out1 = getAngleForFrames(this, p1_name, p2_name, frames, options)
            arguments (Input)
                this Trial
                p1_name string {mustBeMember(p1_name, ...
                    ["Nose","LeftEar","RightEar","Neck","Body","Tailbase","Port"])}
                p2_name string {mustBeMember(p2_name, ...
                    ["Nose","LeftEar","RightEar","Neck","Body","Tailbase","Port"])}
                frames
                options.PositionData = this.getPositionData(frames)
            end

            fprintf('[RTON] getAngleForFrames(): Init \n');
            a = zeros(length(frames), 0);
            pos_data = options.PositionData;

            fprintf('[RTON] getAngleForFrames(): Collecting Frame Angle \n');
            parfor ii = 1:length(options.PositionData)
                [a(ii)] = pos_data(ii).getFrameAngle(p1_name,p2_name);
            end

            fprintf('[RTON] getAngleForFrames(): Returning Data Struct \n');
            out1 = [frames a'];
        end
        
        function imgs = getImagesForFrames(this, frames)
            arguments (Input)
                this Trial
                frames
            end

            prevFolder = pwd;
            cd(strcat(this.Name, '\images'));
            
            fprintf('[RTON] getImagesForFrames(): Init \n');
            videoLoaded = false;
            imgs = zeros(length(frames), 0);
            for ii = 1:length(frames)
                image_name = strcat(num2str(frames(ii)), '__', this.Name, Trial.IMAGE_EXT);
                if ~isfile(image_name)
                    if ~videoLoaded
                        fprintf('[RTON] getImagesForFrames(): Loading Trial Video \n');
                        cd ..
                        video = read(VideoReader(this.VideoPath));
                        videoLoaded = true;
                        cd images
                    end
                    fprintf(['[RTON] getImagesForFrames(): ' ...
                        'Saving frame [%i] image to images folder \n'], frames(ii));
                    imwrite(video(:, :, :, frames(ii)), image_name);
                end
                imgs(ii).Frame = frames(ii);
                imgs(ii).Image = im2double(imread(image_name));
            end
            cd(prevFolder);
        end
        
        function obj = calcFieldBounds(this)
            prevFolder = pwd;
            cd(this.Name);
            
            video = VideoReader(this.VideoPath);
            framedata = video.read([1 100]);
            [~, ~, ~, nFrames] = size(framedata);
            graydata = zeros(256, 564, 1, 0);
            for ii = 1:nFrames
                graydata(:, :, :, ii) = imgaussfilt(rgb2gray(framedata(:,:,:,ii)), 2);
            end
            obj = mean(graydata,4);
            cd(prevFolder);
        end
        
        %% Aggregation Methods
        function [s_out, pos_Data] = getFrameData(this, options)
            arguments (Input)
                this Trial
                options.Valid_Type string {mustBeMember(options.Valid_Type, ...
                    ["valid","invalid","all"])} = "valid"
                options.Validity_Verbose logical = false
                options.PositionData = this.PositionFile.positionData
                options.Port logical = false
                options.Likelihood logical = false
            end

            fprintf('[RTON] getFrameData(): Init \n');
            [pos_size, pos_Data] = ...
                this.getPositionDataSize(PositionData=options.PositionData);
            index_data = zeros(pos_size, 0);

            if (options.Validity_Verbose)
                valid_flag = zeros(pos_size, 0); 
                reasoning = repmat({''}, pos_size, 1);
            end

            nC_Rows = 6;
            nC_Cols = 2;
            if (options.Port), nC_Rows = 7; end
            if (options.Likelihood), nC_Cols = 3; end

            coords_data = zeros(nC_Rows, nC_Cols, 0);
            currentIndex = 0;

            fprintf('[RTON] getFrameData(): Collecting Position Data \n');
            for ii = 1:pos_size
                temp = pos_Data(ii).getSingleFrameData(Likelihood=options.Likelihood, ...
                    Port=options.Port);
                validity = temp.Valid;
                if ((options.Valid_Type == "valid" && ~validity) || ...
                        (options.Valid_Type == "invalid" && validity)), continue; end
                currentIndex = currentIndex + 1;
                coords_data(:,:,currentIndex) = temp.Coordinates;
                index_data(currentIndex) = temp.Index;
                
                if(options.Validity_Verbose)
                    valid_flag(currentIndex) = validity;
                    reasoning{currentIndex} = temp.Reasoning;
                end
            end

            if (options.Valid_Type ~= "all")
                index_data = nonzeros(index_data);
                coords_data = coords_data(:,:,1:currentIndex);
                if (options.Validity_Verbose) 
                    switch(options.Valid_Type)
                        case "valid", valid_flag = nonzeros(valid_flag);
                        case "invalid", valid_flag = ...
                                zeros(length(valid_flag) - nonzeros(valid_flag));
                    end

                    reasoning(cellfun('isempty', reasoning)) = [];
                end
            end

            s_out = struct;
            s_out.FrameIndex = index_data;
            s_out.FrameCoordinates = coords_data;
            if (options.Validity_Verbose)
                s_out.FrameValidity = valid_flag;
                s_out.FrameValidityReason = reasoning;
            end
        end
        
        function s_out = getDaqStruct(this, options)
            arguments (Input)
                this Trial
                options.EthData = this.EthFile.ethData
                options.AccData = this.AccFile.accData
            end

            e_data = this.getAllEthData(EthData=options.EthData);
            a_data = this.getAllAccelerometerData(AccData=options.AccData);

            s_out = [e_data(:,1:2) a_data(:,2:end)];
        end

        function s_out = getDataStruct(this, options)
            arguments (Input)
                this Trial
                options.Valid_Type string {mustBeMember(options.Valid_Type, ...
                    ["valid","invalid","all"])} = "valid"
                options.DAQ_Output logical = true
                options.PositionData = this.PositionFile.positionData
                options.Validity_Verbose logical = false
                options.Port logical = false
                options.Likelihood logical = false
            end

            arguments (Output)
                s_out struct
            end

            fprintf('[RTON] getDataStruct(): Init \n');
            s_out.TrialDate = this.TrialDate;
            s_out.SubjectID = this.SubjectID;
            s_out.VideoPath = this.VideoPath;
            s_out.Name = this.Name;

            [s_out.PositionData, ~] = this.getFrameData(Valid_Type=options.Valid_Type, ...
                PositionData=options.PositionData, ...
                Validity_Verbose=options.Validity_Verbose, Port=options.Port, ...
                Likelihood=options.Likelihood);
            s_out.ArenaData = this.getArenaData.getArenaCoordinates();

            if(options.DAQ_Output)
                fprintf('[RTON] getDataStruct(): Collecting DAQ Data\n');
                s_out.DaqData = this.getDaqStruct();
            end

            fprintf('[RTON] getDataStruct(): Returning Data Struct \n');
        end
    end
    
    %% Save, Load
    methods (Static)
        function saveData(this, name_in, data_in)
            prevFolder = pwd;
            cd(strcat(this.Name, '\saved_data'));
            file_name = strcat(name_in, '_', ...
                string(datetime('now', 'Format', 'yyyy-MM-dd_HH.mm')), '_saved.mat');
            fprintf('[RTON] Saving Data to File: %s\n', file_name);
            mfile = matfile(file_name, 'Writable', true);
            mfile.(name_in) = data_in;
            cd(prevFolder);
        end

        function s = saveobj(obj)
            fprintf('[RTON] Saving Trial..\n');
            s = struct;
            s.PositionFile = obj.PositionFile;
            s.ArenaFile = obj.ArenaFile;
            s.EthFile = obj.EthFile;
            s.AccFile = obj.AccFile;
            s.IniFile = obj.IniFile;
            s.TrialDate = obj.TrialDate;
            s.TrialNum = obj.TrialNum;
            s.SubjectID = obj.SubjectID;
            s.Name = obj.Name;
            s.VideoPath = obj.VideoPath;
            s.BackgroundData = obj.BackgroundData;
        end

        function obj = loadobj(s)
            if isstruct(s)
                fprintf('[RTON] Loading Trial: %s\n', s.Name);
                load_trial = Trial();
                load_trial.PositionFile = s.PositionFile;
                load_trial.ArenaFile = s.ArenaFile;
                load_trial.EthFile = s.EthFile;
                load_trial.AccFile = s.AccFile;
                load_trial.IniFile = s.IniFile;
                load_trial.TrialDate = s.TrialDate;
                load_trial.TrialNum = s.TrialNum;
                load_trial.SubjectID = s.SubjectID;
                load_trial.Name = s.Name;
                load_trial.VideoPath = s.VideoPath;
                load_trial.BackgroundData = s.BackgroundData;
                load_trial.loadConfig();
                obj = load_trial;
            else
                obj = s;
            end
        end
    end
end

%#ok<*ST2NM>