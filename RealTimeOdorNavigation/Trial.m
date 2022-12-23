classdef Trial < handle
    properties (Constant, Hidden = true)
        ConfigPrefix = 'config_'
        PositionPrefix = 'pos_'
        ArenaPrefix = 'arena_'
        EthPrefix = 'eth_'
        AccPrefix = 'acc_'
    end
    properties (Hidden = true)
        PositionFile
        ArenaFile
        EthFile
        AccFile
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
                    obj.TrialDate = in1.TrialDate;
                    obj.TrialNum = in1.TrialNum;
                    obj.SubjectID = in1.SubjectID;
                    obj.Name = in1.Name;
                    obj.VideoPath = in1.VideoPath;
                    obj.BackgroundData = in1.BackgroundData;
                end
            elseif nargin == 2
                [~, tempName1, ~] = fileparts(in1);
                [~, tempName2, ~] = fileparts(in2);
                tempName1{1} = tempName1{1}(1:end-4);
                tempName1 = extractBefore(tempName1, '_reencoded');
                obj.Name = extractBefore(tempName2, '_reencoded');
                obj.VideoPath = strcat(obj.Name, '_reencodedDLC_resnet50_odor-arenaOct3shuffle1_200000_filtered_labeled.mp4');
                bCheckDataDirectory(obj, obj.Name);
                obj.TrialDate = datetime(char(extractBefore(tempName2, '-M')),'InputFormat','M-d-u-h-m a');
                
                subStr = extractBetween(tempName2, "CB", "_");
                obj.SubjectID = str2num(char(extractBefore(subStr, '-')));
                obj.TrialNum = str2num(char(extractAfter(subStr, '-')));
                
                fprintf("[RTON] Loading Positional Data...\n");
                [obj.PositionFile, obj.ArenaFile] = loadPositionData(obj, obj.Name, obj.Name, strcat(tempName2, '.csv'));

                fprintf("[RTON] Loading Ethanol & Accelerometer Data...\n");
                [obj.EthFile, obj.AccFile] = loadEthAccData(obj, obj.Name, obj.Name, strcat(tempName1, '.avi.dat'));

                fprintf("[RTON] Processing Field & Data Boundaries...\n");
                obj.BackgroundData = calcFieldBounds(obj);

                fprintf("[RTON] Trial Loaded: %s\n", obj.Name);
            end
        end
        
        %% Data Storage Methods
        function out1 = bCheckDataDirectory(this, name_in)
            prevFolder = pwd;
            cd('C:\Users\girelab\MATLAB_DATA');
            out1 = true;
            if ~isfolder(name_in) 
                mkdir(name_in);
                mkdir(name_in, 'images');
                mkdir(name_in, 'saved_data');
                copyfile(strcat('C:\\Users\\girelab\\2022.12.06_Tariq-Lane\\2022_plotted-videos_fast-quality\\', this.VideoPath), strcat(name_in, '\\', this.VideoPath)); 
                fprintf('[RTON] Created Directory: %s\n', name_in);
                out1 = false;
            end
            cd(prevFolder);
        end
        
        function [dataout, successout] = loadDataFile(~, dir_in, filename_in)
            prevFolder = pwd;
            cd(strcat('C:\Users\girelab\MATLAB_DATA\\', dir_in));
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
        
        function [posout, arenaout] = loadPositionData(this, dir_in, filename_in, camfile_name)
            [posout, existed] = loadDataFile(this, dir_in, strcat(Trial.PositionPrefix, filename_in));
            [arenaout, ~] = loadDataFile(this, dir_in, strcat(Trial.ArenaPrefix, filename_in));
            if ~existed
                cameraData = csvread(camfile_name, 3, 0);
                tempData = CameraFrame.empty(length(cameraData),0);
                for z = 1:length(cameraData)
                    tempData(z) = CameraFrame(cameraData(z, 1)+1, cameraData(z, :));
                end % camera data per frame
                posout.positionData = tempData;
                arena(1) = Arena([mode(cameraData(:, 23)) mode(cameraData(:,24)) mode(cameraData(:,26)) mode(cameraData(:,27)) mode(cameraData(:,29)) mode(cameraData(:,30)) mode(cameraData(:,32)) mode(cameraData(:,33)) mode(cameraData(:,20)) mode(cameraData(:,21))]);
                arenaout.arenaData = arena;
                clear cameraData
            end
        end
        
        function [ethout, accout] = loadEthAccData(this, dir_in, filename_in, ethaccdata_name)
            [ethout, existed] = loadDataFile(this, dir_in, strcat(Trial.EthPrefix, filename_in));
            [accout, ~] = loadDataFile(this, dir_in, strcat(Trial.AccPrefix, filename_in));
            if ~existed
                ethaccData = fread(fopen(ethaccdata_name), 'float64','ieee-be');
                n_ten = find(ethaccData==-500);
                n_ten = n_ten(14:end);
                frame_stamp = uint32(ethaccData(n_ten+2));
                time_stamp = uint32(ethaccData(n_ten+1));
                ethData = ethaccData(n_ten+4);
                accData = [ethaccData(n_ten+9) ethaccData(n_ten+10) ethaccData(n_ten+8)];
                
                tempEth = ETH_Sensor.empty(length(ethData),0);
                tempAcc = Accelerometer.empty(length(accData),0);
                parfor ii = 1:length(ethData)
                    tempEth(ii) = ETH_Sensor(ethData(ii), time_stamp(ii), frame_stamp(ii));
                    tempAcc(ii) = Accelerometer(accData(ii, :), time_stamp(ii), frame_stamp(ii));
                end
                ethout.ethData = tempEth;
                accout.accData = tempAcc;
                clear ethaccData n_ten frame_stamp time_stamp ethData accData
            end
        end
        
        function dataout = getPositionData(this, frames)
            arguments (Input)
                this Trial
                frames
            end

            dataout = CameraFrame.empty(length(frames),0);
            posData = this.PositionFile.positionData;
            for ii = 1:length(frames)
                dataout(ii) = posData(frames(ii));
            end
            clear posData
        end
        
        function dataout = getEthData(this, indices)
            arguments (Input)
                this Trial
                indices
            end

            dataout = ETH_Sensor.empty(length(indices),0);
            ethData = this.EthFile.ethData;
            for ii = 1:length(indices)
                dataout(ii) = ethData(indices(ii));
            end
            clear ethData
        end
        
        function dataout = getAccData(this, indices)
            arguments (Input)
                this Trial
                indices
            end

            dataout = Accelerometer.empty(length(indices),0);
            accData = this.AccFile.accData;
            for ii = 1:length(indices)
                dataout(ii) = accData(indices(ii));
            end
            clear accData
        end
        
        function dataout = getArenaData(this), dataout = this.ArenaFile.arenaData; end
        
        %% Ethanol Sensor Methods
        function size_out = getEthDataSize(this), [~, size_out] = size(this.EthFile, 'ethData'); end
        
        function out1 = getAllEthData(this, options)
            arguments (Input)
                this Trial
                options.Time logical = false
            end

            fprintf('[RTON] getAllEthData(): Init \n');
            eth_size = getEthDataSize(this);
            voltage = zeros(eth_size, 0);
            fprintf('[RTON] getAllEthData(): Collecting Ethanol Data \n');
            ethData = getEthData(this, Indices=1:eth_size);

            if options.Time
                time_data = zeros(eth_size, 0);
                with_time = options.Time;
                parfor ii = 1:eth_size
                    [voltage(ii), time_data(ii)] = ethData(ii).getEthReading(Time=with_time);
                end
                out1 = [voltage' time_data'];
            else
                parfor ii = 1:eth_size, [voltage(ii)] = ethData(ii).getEthReading(); end
                out1 = voltage';
            end
        end
        
        %% Accelerometer Methods
        function size_out = getAccDataSize(this), [~, size_out] = size(this.AccFile, 'accData'); end
        
        function out1 = getAllAccelerometerData(this, options)
            arguments (Input)
                this Trial
                options.Time logical = false
            end

            fprintf('[RTON] getAllAccelerometerData(): Init \n');
            acc_size = getAccDataSize(this);
            x = zeros(acc_size, 0);
            y = zeros(acc_size, 0);
            z = zeros(acc_size, 0);

            fprintf('[RTON] getAllAccelerometerData(): Collecting Accelerometer Data \n');
            accData = this.getAccData(Indices=1:acc_size);
            if options.Time
                time = zeros(acc_size, 0);
                with_time = options.Time;
                parfor ii = 1:acc_size
                    [x(ii), y(ii), z(ii), time(ii)] = accData(ii).getAccReading(Time=with_time);
                end
                out1 = [x' y' z' time'];
            else
                parfor ii = 1:acc_size, [x(ii), y(ii), z(ii)] = accData(ii).getAccReading(); end
                out1 = [x' y' z'];
            end

            clear accData
        end
        
        %% Position Data Methods
        function size_out = getPositionDataSize(this), [~, size_out] = size(this.PositionFile, 'positionData'); end
        
        function out1 = getCoordsForFrames(this, frames, options)
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

            out1 = zeros(rows_in, columns_in, length(frames));
            with_likelihood = options.Likelihood;
            with_port = options.Port;
            pos_data = options.PositionData;
            parfor ii = 1:length(frames)
                out1(:,:,ii) = pos_data(ii).getFrameCoordinates(Likelihood=with_likelihood, Port=with_port);
            end
        end
        
        function out1 = getAngleForFrames(this, p1_name, p2_name, frames, options)
            arguments (Input)
                this Trial
                p1_name string {mustBeMember(p1_name,["Nose","LeftEar","RightEar","Neck","Body","Tailbase","Port"])}
                p2_name string {mustBeMember(p2_name,["Nose","LeftEar","RightEar","Neck","Body","Tailbase","Port"])}
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
            cd(strcat('C:\Users\girelab\MATLAB_DATA\\', this.Name, '\images'));
            
            fprintf('[RTON] getImagesForFrames(): Init \n');
            videoLoaded = false;
            imgs = zeros(length(frames), 0);
            for ii = 1:length(frames)
                image_name = strcat(num2str(frames(ii)), '__', this.Name, '.png');
                if ~isfile(image_name)
                    if ~videoLoaded
                        fprintf('[RTON] getImagesForFrames(): Loading Trial Video \n');
                        cd ..
                        video = read(VideoReader(this.VideoPath));
                        videoLoaded = true;
                        cd images
                    end
                    fprintf('[RTON] getImagesForFrames(): Saving frame [%i] image to images folder \n', frames(ii));
                    imwrite(video(:, :, :, frames(ii)), image_name);
                end
                imgs(ii).Frame = frames(ii);
                imgs(ii).Image = im2double(imread(image_name));
            end
            cd(prevFolder);
        end
        
        function obj = calcFieldBounds(this)
            prevFolder = pwd;
            cd(strcat('C:\Users\girelab\MATLAB_DATA\', this.Name));
            
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
        function out1 = getFrameData(this, options)
            arguments (Input)
                this Trial
                options.OnlyValid logical = true
                options.Frames = ':'
            end

            fprintf('[RTON] getFrameData(): Init \n');
            out1 = struct;
            pos_size = this.getPositionDataSize();
            index_data = zeros(pos_size, 0);
%            time_data = zeros(this.getPositionDataSize(), 0);
            valid_flag = zeros(pos_size, 0);
            coords_data = zeros(7, 3, 0);
            currentIndex = 0;

            fprintf('[RTON] getFrameData(): Collecting Position Data \n');
            posData = this.getPositionData(1:pos_size);
            for ii = 1:pos_size
                if options.OnlyValid && ~posData(ii).getValidity(), continue; end
                currentIndex = currentIndex + 1;
                temp = posData(ii).getFrameData();
                coords_data(:,:,currentIndex) = temp.Coordinates;
                index_data(currentIndex) = temp.Index;
%                time_data(i) = temp.Time;
                valid_flag(currentIndex) = temp.Valid;
            end
            if options.OnlyValid
                index_data = nonzeros(index_data);
%                time_data = nonzeros(time_data);
                coords_data = coords_data(:,:,1:currentIndex);
                valid_flag = nonzeros(valid_flag);
            end

            out1.FrameIndex = index_data;
%            out1.time_data = time_data';
            out1.FrameCoordinates = coords_data;
            out1.FrameValidity = valid_flag;
        end
        
        function out1 = getDataStruct(this, options)
            arguments (Input)
                this Trial
                options.OnlyValid logical = true
                options.EthOutput logical = true
                options.AccOutput logical = true
                options.PositionData
                options.EthData
                options.AccData
            end

            fprintf('[RTON] getDataStruct(): Init \n');
            out1 = struct;
            out1.Date = this.TrialDate;
            out1.SubjectID = this.SubjectID;
            out1.VideoPath = this.VideoPath;
            out1.Name = this.Name;

            fprintf('[RTON] getDataStruct(): Collecting Position Data \n');
            out1.PositionData = this.getFrameData(OnlyValid=options.OnlyValid);
            out1.ArenaData = this.getArenaData.getArenaCoordinates();

            if(options.EthOutput)
                fprintf('[RTON] getDataStruct(): Collecting Ethanol Sensor Data \n');
                out1.EthData = this.getAllEthData(Time=true);
            end

            if(options.AccOutput)
                fprintf('[RTON] getDataStruct(): Collecting Accelerometer Data \n');
                out1.AccData = this.getAllAccelerometerData(Time=true);
            end

            fprintf('[RTON] getDataStruct(): Returning Data Struct \n');
        end
    end
    
    %% Save, Load
    methods (Static)
        function saveData(this, name_in, data_in)
            prevFolder = pwd;
            cd(strcat('C:\Users\girelab\MATLAB_DATA\\', this.Name, '\saved_data'));
            file_name = strcat(name_in, '_', string(datetime('now', 'Format', 'yyyy-MM-dd_HH.mm')), '_saved.mat');
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
                load_trial.TrialDate = s.TrialDate;
                load_trial.TrialNum = s.TrialNum;
                load_trial.SubjectID = s.SubjectID;
                load_trial.Name = s.Name;
                load_trial.VideoPath = s.VideoPath;
                load_trial.BackgroundData = s.BackgroundData;
                obj = load_trial;
            else
                obj = s;
            end
        end
    end
end

%#ok<*ST2NM>