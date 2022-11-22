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
        PositionData CameraFrame
        ArenaData Arena
        EthData ETH_Sensor
        AccData Accelerometer
    end
    properties
        TrialDate datetime
        TrialNum uint16
        SubjectID uint16
        Name char
        VideoPath char
    end
    methods
        %% Trial Constructor
        function obj = Trial(ethacc_file, camera_file)
            if nargin == 2
                obj.Name = extractBefore(camera_file.name, '_reencoded');
                bCheckDataDirectory(obj, obj.Name);
                obj.VideoPath = strcat(obj.Name, '.avi');
                obj.TrialDate = datetime(char(extractBefore(camera_file.name, '-M')),'InputFormat','M-d-u-h-m a');
                
                subStr = extractBetween(camera_file.name, "CB", "_");
                obj.SubjectID = str2num(char(extractBefore(subStr, '-')));
                obj.TrialNum = str2num(char(extractAfter(subStr, '-')));
                clear subStr
                
                fprintf("[RTON] Loading Positional Data...\n");
                [obj.PositionFile, obj.ArenaFile] = loadPositionData(obj, obj.Name, obj.Name, camera_file.name);
                fprintf("[RTON] Loading Ethanol & Accelerometer Data...\n");
                [obj.EthFile, obj.AccFile] = loadEthAccData(obj, obj.Name, obj.Name, ethacc_file.name);
                fprintf("[RTON] Trial: %s - Loaded!\n", obj.Name);
            end
        end
        
        function s = saveobj(obj)
            s.TrialDate = obj.TrialDate;
            s.TrialNum = obj.TrialNum;
            s.SubjectID = obj.SubjectID;
            s.Name = obj.Name;
            s.VideoPath = obj.VideoPath;
        end
        
        %% Data Storage Methods
        function out1 = bCheckDataDirectory(~, name_in)
            prevFolder = pwd;
            cd('C:\Users\girelab\MATLAB_DATA');
            out1 = true;
            if ~isfolder(name_in) 
                mkdir(name_in);
                mkdir(name_in, 'images');
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
                save(filename_in, 'dir_in', '-v7');
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
                
                import ETH_Sensor
                import Accelerometer
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
            eth_size = getEthDataSize(this);
            voltage = zeros(eth_size, 0);
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
            acc_size = getAccDataSize(this);
            x = zeros(acc_size, 0);
            y = zeros(acc_size, 0);
            z = zeros(acc_size, 0);
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
        function size_out = getPositionDataSize(this)
            [~, size_out] = size(this.PositionFile, 'positionData');
        end
        
        function out1 = getCoordsForFrames(this, frame_num, lh, port)
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
            posData = this.getPositionData(frame_num);
            parfor ii = 1:length(frame_num)
                out1(:,:,ii) = posData(ii).getFrameCoordinates(lh, port);
            end
        end
        
        function out1 = getAnglesForFrames(this, iFrames)
            a = zeros(length(iFrames), 0);
            b = zeros(length(iFrames), 0);
            c = zeros(length(iFrames), 0);
            
            pos_data = this.getPositionData(iFrames);
            for ii = 1:length(pos_data)
                [a(ii), b(ii), c(ii)] = pos_data(ii).getFrameAngles();
            end
            out1 = [iFrames a' b' c'];
        end
        
        function imgs = getImagesForFrames(this, iFrames)
            prevFolder = pwd;
            cd(strcat('C:\Users\girelab\MATLAB_DATA\\', this.Name, '\images'));
            
            videoLoaded = false;
            imgs = zeros(length(iFrames), 0);
            for ii = 1:length(iFrames)
                image_name = strcat(num2str(iFrames(ii)), '__', this.Name, '.jpg');
                if ~isfile(image_name)
                    if ~videoLoaded
                        cd ..
                        video = read(VideoReader(this.VideoPath));
                        videoLoaded = true;
                        cd images
                    end
                    imwrite(video(:, :, :, iFrames(ii)), image_name);
                end
                imgs(ii).Frame = iFrames(ii);
                imgs(ii).Image = imread(image_name);
            end
            cd(prevFolder);
        end
        
        %% Aggregation Methods
        function out1 = getAllFrameData(this, exc_valid)
            pos_size = this.getPositionDataSize();
            index_data = zeros(pos_size, 0);
%            time_data = zeros(this.getPositionDataSize(), 0);
            valid_flag = zeros(pos_size, 0);
            coords_data = zeros(7, 3, 0);
            currentIndex = 0;
            posData = this.getPositionData(1:pos_size);
            for ii = 1:pos_size
                if exc_valid && ~posData(ii).getValidity(), continue; end
                currentIndex = currentIndex + 1;
                temp = posData(ii).getFrameData();
                coords_data(:,:,currentIndex) = temp.Coordinates;
                index_data(currentIndex) = temp.Index;
%                time_data(i) = temp.Time;
                valid_flag(currentIndex) = temp.Valid;
            end
            if exc_valid
                index_data = nonzeros(index_data);
%                time_data = nonzeros(time_data);
                coords_data = coords_data(:,:,1:currentIndex);
                valid_flag = nonzeros(valid_flag);
            end
            out1.FrameIndex = index_data;
%            out1.time_data = time_data';
            out1.FrameCoordinates = coords_data;
            out1.FrameValidity = valid_flag;
            clear posData
        end
        
        function out1 = getDataStruct(this, exc_invalid)
            out1.Date = this.TrialDate;
            out1.SubjectID = this.SubjectID;
            out1.VideoPath = this.VideoPath;
%            out1.TrialNum = this.TrialNum;
%            out1.Name = this.Name;
            out1.PositionData = this.getAllFrameData(exc_invalid);
            out1.ArenaData = this.getArenaData.getArenaCoordinates();
            out1.EthData = this.getAllEthData(true);
            out1.AccData = this.getAllAccelerometerData(true);
        end
        
    end
end

%#ok<*ST2NM>