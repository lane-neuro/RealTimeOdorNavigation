classdef Trial
    properties (Constant, Hidden = true)
        ConfigPrefix = 'config_'
        PositionPrefix = 'pos_'
        ArenaPrefix = 'arena_'
        ImagePrefix = 'img_'
        EthPrefix = 'eth_'
        AccPrefix = 'acc_'
    end
    properties
        TrialDate datetime
        TrialNum uint16
        SubjectID uint16
        Name char
        VideoPath char
        PositionData CameraFrame
        PositionFile
        ArenaData Arena
        ArenaFile
        EthData ETH_Sensor
        EthFile
        AccData Accelerometer
        AccFile
    end
    methods
        function obj = Trial(ethacc_file, camera_file)
            import CameraFrame
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
%                obj.PositionData = mat_pos.PositionData;
%                obj.ArenaData = arena_pos.ArenaData;
%                obj.EthData = mat_eth.EthData;
%                obj.AccData = mat_acc.AccData;
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
                save(filename_in);
                fprintf('[RTON] Created Data File: %s\n', filename_in);
                successout = false;
            end
            dataout = matfile(filename_in, 'Writable', true);
            cd(prevFolder);
        end
        
        function [posout, arenaout] = loadPositionData(this, dir_in, filename_in, camfile_name)
            [posout, existed] = loadDataFile(this, dir_in, strcat(Trial.PositionPrefix, filename_in));
            [arenaout, ~] = loadDataFile(this, dir_in, strcat(Trial.ArenaPrefix, filename_in));
            if ~existed
                cameraData = csvread(camfile_name, 3, 0);
                for z = 1:length(cameraData)
                    tempData(z) = CameraFrame(cameraData(z, 1)+1, cameraData(z, :));
                end % camera data per frame
                posout.PositionData = tempData';
                arena(1) = Arena([mode(cameraData(:, 23)) mode(cameraData(:,24)) mode(cameraData(:,26)) mode(cameraData(:,27)) mode(cameraData(:,29)) mode(cameraData(:,30)) mode(cameraData(:,32)) mode(cameraData(:,33)) mode(cameraData(:,20)) mode(cameraData(:,21))]);
                arenaout.ArenaData = arena;
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
                ethout.EthData = tempEth';
                accout.AccData = tempAcc';
                clear ethaccData n_ten frame_stamp time_stamp ethData accData
            end
        end
        
        %% Get Methods
        function out1 = getAllEthData(this, inc_time)
            voltage = zeros(length(this.EthData), 0);
            if inc_time
                time_data = zeros(length(this.EthData), 0);
                for i = 1:length(this.EthData)
                    [voltage(i), time_data(i)] = this.EthData(i).getEthVoltageWithTime();
                end
                out1 = [voltage' time_data'];
            else
                for i = 1:length(this.EthData), [voltage(i)] = this.EthData(i).getEthReading(); end
                out1 = voltage';
            end
        end
        
        function out1 = getAllAccelerometerData(this, inc_time)
            x = zeros(length(this.AccData), 0);
            y = zeros(length(this.AccData), 0);
            z = zeros(length(this.AccData), 0);
            if inc_time
                time = zeros(length(this.AccData), 0);
                for i = 1:length(this.AccData)
                    [x(i), y(i), z(i), time(i)] = this.AccData(i).getAccReadingWithTime();
                end
                out1 = [x' y' z' time'];
            else
                for i = 1:length(this.AccData), [x(i), y(i), z(i)] = this.AccData(i).getAccReading(); end
                out1 = [x' y' z'];
            end
        end
        
        function out1 = getAllFrameData(this, exc_valid)
            index_data = zeros(length(this.PositionData), 0);
%            time_data = zeros(length(in1.PositionData), 0);
            valid_flag = zeros(length(this.PositionData), 0);
            coords_data = zeros(7, 3, 0);
            currentIndex = 0;
            for i = 1:length(this.PositionData)
                if exc_valid && ~this.PositionData(i).getValidity(), continue; end
                currentIndex = currentIndex + 1;
                temp = this.PositionData(i).getFrameData();
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
        end
        
        function out1 = getCoordsForFrames(trial_in, frame_num, lh, port)
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
            for i = 1:length(frame_num)
                out1(:,:,i) = trial_in.PositionData(frame_num(i)).getFrameCoordinates(lh, port);
            end
        end
        
        function out1 = getDataStruct(this, exc_invalid)
            out1.Date = this.TrialDate;
            out1.SubjectID = this.SubjectID;
            out1.VideoPath = this.VideoPath;
%            out1.TrialNum = this.TrialNum;
%            out1.Name = this.Name;
            out1.PositionData = this.getAllFrameData(exc_invalid);
            out1.ArenaData = this.ArenaData.getArenaCoordinates();
            out1.EthData = this.getAllEthData(true);
            out1.AccData = this.getAllAccelerometerData(true);
        end
        
        function out1 = getAnglesForFrames(this, iFrames)
            a = zeros(length(iFrames), 0);
            b = zeros(length(iFrames), 0);
            c = zeros(length(iFrames), 0);
            for ii = 1:length(iFrames)
                [a(ii), b(ii), c(ii)] = this.PositionData(iFrames(ii)).getFrameAngles();
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
        
    end
end

%#ok<*ST2NM>