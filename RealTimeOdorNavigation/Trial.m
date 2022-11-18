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
                
                [obj.PositionFile, obj.ArenaFile] = loadPositionData(obj, obj.Name, obj.Name, camera_file.name);
                [obj.EthFile, obj.AccFile] = loadEthAccData(obj, obj.Name, obj.Name, ethacc_file.name);
            end
        end
        
        %% Data Storage Methods
        function out1 = bCheckDataDirectory(~, name_in)
            prevFolder = pwd;
            cd('D:\RealTimeOdorNavigation\_DATA');
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
            cd(strcat('D:\RealTimeOdorNavigation\_DATA\\', dir_in));
            filename_in = strcat(filename_in, '.mat');
            successout = true;
            if ~isfile(filename_in)
                save(filename_in, 'dir_in', '-v6');
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
                posout.positionData = tempData';
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
                tempEth(1) = ETH_Sensor(ethData(1), time_stamp(1), frame_stamp(1));
                tempAcc(1) = Accelerometer(accData(1, :), time_stamp(1), frame_stamp(1));
                for i = 2:length(ethData)
                    tempEth(end+1) = ETH_Sensor(ethData(i), time_stamp(i), frame_stamp(i));
                    tempAcc(end+1) = Accelerometer(accData(i, :), time_stamp(i), frame_stamp(i));
                end
                ethout.ethData = tempEth';
                accout.accData = tempAcc';
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
        function size_out = getEthDataSize(this), [size_out, ~] = size(this.EthFile, 'ethData'); end
        
        function out1 = getAllEthData(this, inc_time)
            voltage = zeros(this.getEthDataSize(), 0);
            ethData = this.getEthData(1:this.getEthDataSize());
            if inc_time
                time_data = zeros(this.getEthDataSize(), 0);
                for ii = 1:this.getEthDataSize()
                    [voltage(ii), time_data(ii)] = ethData(ii).getEthVoltageWithTime();
                end
                out1 = [voltage' time_data'];
            else
                for ii = 1:this.getEthDataSize(), [voltage(ii)] = ethData(ii).getEthReading(); end
                out1 = voltage';
            end
        end
        
        %% Accelerometer Methods
        function size_out = getAccDataSize(this), [size_out, ~] = size(this.AccFile, 'accData'); end
        
        function out1 = getAllAccelerometerData(this, inc_time)
            x = zeros(this.getAccDataSize(), 0);
            y = zeros(this.getAccDataSize(), 0);
            z = zeros(this.getAccDataSize(), 0);
            accData = this.getAccData(1:this.getAccDataSize());
            if inc_time
                time = zeros(this.getAccDataSize(), 0);
                for ii = 1:this.getAccDataSize()
                    [x(ii), y(ii), z(ii), time(ii)] = accData(ii).getAccReadingWithTime();
                end
                out1 = [x' y' z' time'];
            else
                for ii = 1:this.getAccDataSize(), [x(ii), y(ii), z(ii)] = accData(ii).getAccReading(); end
                out1 = [x' y' z'];
            end
            clear accData
        end
        
        %% Position Data Methods
        function size_out = getPositionDataSize(this)
            [size_out, ~] = size(this.PositionFile, 'positionData');
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
            for ii = 1:length(frame_num)
                out1(:,:,ii) = posData(ii).getFrameCoordinates(lh, port);
            end
        end
        
        function out1 = getAnglesForFrames(this, iFrames)
            a = zeros(length(iFrames), 0);
            b = zeros(length(iFrames), 0);
            c = zeros(length(iFrames), 0);
            
            for ii = 1:length(iFrames)
                [a(ii), b(ii), c(ii)] = this.getPositionData(iFrames(ii)).getFrameAngles();
            end
            out1 = [iFrames a' b' c'];
        end
        
        function imgs = getImagesForFrames(this, iFrames)
            prevFolder = pwd;
            cd(strcat('D:\RealTimeOdorNavigation\_DATA\', this.Name, '\images'));
            
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
            index_data = zeros(this.getPositionDataSize(), 0);
%            time_data = zeros(this.getPositionDataSize(), 0);
            valid_flag = zeros(this.getPositionDataSize(), 0);
            coords_data = zeros(7, 3, 0);
            currentIndex = 0;
            posData = this.getPositionData(1:this.getPositionDataSize());
            for i = 1:this.getPositionDataSize()
                if exc_valid && ~posData(i).getValidity(), continue; end
                currentIndex = currentIndex + 1;
                temp = posData(i).getFrameData();
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