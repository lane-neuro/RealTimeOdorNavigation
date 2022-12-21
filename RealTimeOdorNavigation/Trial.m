classdef Trial
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
        BackgroundData uint8
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
                obj.VideoPath = strcat(obj.Name, '_reencoded.mp4');
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
            else
                fprintf('[RTON] Empty Trial Constructor.\n');
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
                copyfile(strcat('C:\Users\girelab\2022.12.06_Tariq-Lane\2021_original-videos_no-crop\', this.VideoPath), strcat(name_in, '\', this.VideoPath)); 
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
        
        function saveData(this, name_in, data_in)
            prevFolder = pwd;
            cd(strcat('C:\Users\girelab\MATLAB_DATA\\', this.Name, '\saved_data'));
            file_name = strcat(name_in, '_', strrep(datestr(now), ':', '-'), '_saved.mat');
            fprintf('[RTON] Saving Data to File: %s\n', file_name);
            mfile = matfile(file_name, 'Writable', true);
            mfile.(name_in) = data_in;
            cd(prevFolder);
        end
        
        function dataout = getPositionData(this, iFrames)
            dataout = CameraFrame.empty(length(iFrames),0);
            posData = this.PositionFile.positionData;
            for ii = 1:length(iFrames)
                dataout(ii) = posData(iFrames(ii));
            end
            clear posData
        end
        
        function dataout = getEthData(this, iIndices)
            dataout = ETH_Sensor.empty(length(iIndices),0);
            ethData = this.EthFile.ethData;
            for ii = 1:length(iIndices)
                dataout(ii) = ethData(iIndices(ii));
            end
            clear ethData
        end
        
        function dataout = getAccData(this, iIndices)
            dataout = Accelerometer.empty(length(iIndices),0);
            accData = this.AccFile.accData;
            for ii = 1:length(iIndices)
                dataout(ii) = accData(iIndices(ii));
            end
            clear accData
        end
        
        function dataout = getArenaData(this), dataout = this.ArenaFile.arenaData; end
        
        %% Ethanol Sensor Methods
        function size_out = getEthDataSize(this), [~, size_out] = size(this.EthFile, 'ethData'); end
        
        function out1 = getAllEthData(this, inc_time)
            fprintf('[RTON] getAllEthData(): Init \n');
            eth_size = getEthDataSize(this);
            voltage = zeros(eth_size, 0);
            fprintf('[RTON] getAllEthData(): Collecting Ethanol Data \n');
            ethData = getEthData(this, 1:eth_size);
            if inc_time
                time_data = zeros(eth_size, 0);
                parfor ii = 1:eth_size
                    [voltage(ii), time_data(ii)] = getEthVoltageWithTime(ethData(ii));
                end
                out1 = [voltage' time_data'];
            else
                parfor ii = 1:eth_size, [voltage(ii)] = getEthReading(ethData(ii)); end
                out1 = voltage';
            end
        end
        
        %% Accelerometer Methods
        function size_out = getAccDataSize(this), [~, size_out] = size(this.AccFile, 'accData'); end
        
        function out1 = getAllAccelerometerData(this, inc_time)
            fprintf('[RTON] getAllAccelerometerData(): Init \n');
            acc_size = getAccDataSize(this);
            x = zeros(acc_size, 0);
            y = zeros(acc_size, 0);
            z = zeros(acc_size, 0);
            fprintf('[RTON] getAllAccelerometerData(): Collecting Accelerometer Data \n');
            accData = getAccData(this, 1:acc_size);
            if inc_time
                time = zeros(acc_size, 0);
                parfor ii = 1:acc_size
                    [x(ii), y(ii), z(ii), time(ii)] = getAccReadingWithTime(accData(ii));
                end
                out1 = [x' y' z' time'];
            else
                parfor ii = 1:acc_size, [x(ii), y(ii), z(ii)] = getAccReading(accData(ii)); end
                out1 = [x' y' z'];
            end
            clear accData
        end
        
        %% Position Data Methods
        function size_out = getPositionDataSize(this), [~, size_out] = size(this.PositionFile, 'positionData'); end
        
        function out1 = getCoordsForFrames(this, frame_num, lh, port)
            fprintf('[RTON] getCoordsForFrames(): Init \n');
            if nargin == 2
                columns_in = 2;
                rows_in = 6;
                lh = false;
                port = false;
            elseif nargin == 3
                if lh, columns_in = 3; else, columns_in = 2; end
                rows_in = 6;
            elseif nargin == 4
                if lh, columns_in = 3; else, columns_in = 2; end
                if port, rows_in = 7; else, rows_in = 6; end
            end
            out1 = zeros(rows_in, columns_in, length(frame_num));
            fprintf('[RTON] getCoordsForFrames(): Collecting Position Data \n');
            posData = this.getPositionData(frame_num);
            parfor ii = 1:length(frame_num)
                out1(:,:,ii) = posData(ii).getFrameCoordinates(lh, port);
            end
        end
        
        function out1 = getAnglesForFrames(this, iFrames)
            fprintf('[RTON] getAnglesForFrames(): Init \n');
            a = zeros(length(iFrames), 0);
            b = zeros(length(iFrames), 0);
            c = zeros(length(iFrames), 0);
            
            fprintf('[RTON] getAnglesForFrames(): Collecting Position Data \n');
            pos_data = this.getPositionData(iFrames);
            
            fprintf('[RTON] getAnglesForFrames(): Collecting Frame Angles \n');
            for ii = 1:length(pos_data)
                [a(ii), b(ii), c(ii)] = pos_data(ii).getFrameAngles();
            end

            fprintf('[RTON] getAnglesForFrames(): Returning Data Struct \n');
            out1 = [iFrames a' b' c'];
        end
        
        function imgs = getImagesForFrames(this, iFrames)
            prevFolder = pwd;
            cd(strcat('C:\Users\girelab\MATLAB_DATA\\', this.Name, '\images'));
            
            fprintf('[RTON] getImagesForFrames(): Init \n');
            videoLoaded = false;
            imgs = zeros(length(iFrames), 0);
            for ii = 1:length(iFrames)
                image_name = strcat(num2str(iFrames(ii)), '__', this.Name, '.jpg');
                if ~isfile(image_name)
                    if ~videoLoaded
                        fprintf('[RTON] getImagesForFrames(): Loading Trial Video \n');
                        cd ..
                        video = read(VideoReader(this.VideoPath));
                        videoLoaded = true;
                        cd images
                    end
                    fprintf('[RTON] getImagesForFrames(): Saving frame [%i] image to images folder \n', iFrames(ii));
                    imwrite(video(:, :, :, iFrames(ii)), image_name);
                end
                imgs(ii).Frame = iFrames(ii);
                imgs(ii).Image = imread(image_name);
            end
            cd(prevFolder);
        end
        
        function obj = calcFieldBounds(this)
            prevFolder = pwd;
            cd(strcat('C:\Users\girelab\MATLAB_DATA\', this.Name));
            
            video = VideoReader(this.VideoPath);
            framedata = video.read([1 100]);
            [~, ~, ~, nFrames] = size(framedata);
            graydata = zeros(256, 564, 1, 0, 'uint8');
            for ii = 1:nFrames
                graydata(:, :, :, ii) = imgaussfilt(rgb2gray(framedata(80:335,10:573,:,ii)), 2);
            end
            obj = uint8(mean(graydata,4));
            cd(prevFolder);
        end
        
        %% Aggregation Methods
        function out1 = getAllFrameData(this, options)
            arguments (Input)
                this Trial
                options.OnlyValid logical = true
            end

            fprintf('[RTON] getAllFrameData(): Init \n');
            out1 = struct;
            pos_size = this.getPositionDataSize();
            index_data = zeros(pos_size, 0);
%            time_data = zeros(this.getPositionDataSize(), 0);
            valid_flag = zeros(pos_size, 0);
            coords_data = zeros(7, 3, 0);
            currentIndex = 0;

            fprintf('[RTON] getAllFrameData(): Collecting Position Data \n');
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
            end

            fprintf('[RTON] getDataStruct(): Init \n');
            out1 = struct;
            out1.Date = this.TrialDate;
            out1.SubjectID = this.SubjectID;
            out1.VideoPath = this.VideoPath;
            out1.Name = this.Name;

            fprintf('[RTON] getDataStruct(): Collecting Position Data \n');
            out1.PositionData = this.getAllFrameData(options.OnlyValid);
            out1.ArenaData = this.getArenaData.getArenaCoordinates();

            if(options.EthOutput)
                fprintf('[RTON] getDataStruct(): Collecting Ethanol Sensor Data \n');
                out1.EthData = this.getAllEthData(true);
            end

            if(options.AccOutput)
                fprintf('[RTON] getDataStruct(): Collecting Accelerometer Data \n');
                out1.AccData = this.getAllAccelerometerData(true);
            end

            fprintf('[RTON] getDataStruct(): Returning Data Struct \n');
        end
    end
    
    %% Save, Load
    methods (Static)
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
                fprintf('[RTON] Loading Trial..\n');
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