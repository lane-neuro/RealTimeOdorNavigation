classdef Trial
    properties
        Name char
        SubjectID uint16
        TrialNum uint16
        Date datetime
        PositionData CameraFrame
        ArenaData Arena
        EthData ETH_Sensor
        AccData Accelerometer
    end
    methods
        function obj = Trial(ethacc_file, camera_file)
            import CameraFrame
            if nargin == 2
                obj.Name = camera_file.name(1:length(camera_file.name)-4);
                subStr = extractBetween(camera_file.name, "CB", "_");
                obj.SubjectID = str2num(char(extractBefore(subStr, '-')));
                obj.TrialNum = str2num(char(extractAfter(subStr, '-')));
                clear subStr
                
                cameraData = csvread(camera_file.name, 3, 0);
                for z = 1:length(cameraData) % camera data per frame
                    obj.PositionData(z) = CameraFrame(cameraData(z, 1)+1, cameraData(z, :));
                end
                import Arena
                obj.ArenaData = Arena([mode(cameraData(:, 23)) mode(cameraData(:,24)) mode(cameraData(:,26)) mode(cameraData(:,27)) mode(cameraData(:,29)) mode(cameraData(:,30)) mode(cameraData(:,32)) mode(cameraData(:,33)) mode(cameraData(:,20)) mode(cameraData(:,21))]);
                clear cameraData
                
                ethaccData = fread(fopen(ethacc_file.name), 'float64','ieee-be');
                n_ten = find(ethaccData==-500);
                n_ten = n_ten(14:end);
                frame_stamp = uint32(ethaccData(n_ten+2));
                time_stamp = uint32(ethaccData(n_ten+1));
                ethData = ethaccData(n_ten+4);
                accData = [ethaccData(n_ten+9) ethaccData(n_ten+10) ethaccData(n_ten+8)];
                
                import ETH_Sensor
                import Accelerometer
                for i = 1:length(ethData)
                    obj.EthData(end+1) = ETH_Sensor(ethData(i), time_stamp(i), frame_stamp(i));
                    obj.AccData(end+1) = Accelerometer(accData(i, :), time_stamp(i), frame_stamp(i));
                end
                clear ethaccData n_ten frame_stamp time_stamp ethData accData
                
                obj.PositionData = obj.PositionData';
                obj.EthData = obj.EthData';
                obj.AccData = obj.AccData';
            end
        end
        
        %% Get Methods
        function out1 = GetETHData(in1, inc_time)
            voltage = zeros(size(in1.EthData));
            if inc_time
                for i = 1:length(in1.EthData)
                    time_data = zeros(size(in1.EthData));
                    [voltage(i), time_data(i)] = in1.EthData(i).GetETHVoltageWithTime();
                end
                out1 = [voltage, time_data];
            else
                for i = 1:length(in1.EthData)
                    [voltage(i)] = in1.EthData(i).GetETHReading();
                end
                out1 = voltage;
            end
        end
        
        function out1 = GetAccelerometerData(in1, inc_time)
            x = zeros(size(in1.AccData));
            y = zeros(size(in1.AccData));
            z = zeros(size(in1.AccData));
            if inc_time
                for i = 1:length(in1.AccData)
                    time = zeros(size(in1.AccData));
                    [x(i), y(i), z(i), time(i)] = in1.AccData(i).GetAccReadingWithTime();
                end
                out1 = [x, y, z, time];
            else
                for i = 1:length(in1.AccData)
                    [x(i), y(i), z(i)] = in1.AccData(i).GetAccReading();
                end
                out1 = [x, y, z];
            end
        end
        
        function out1 = GetAllFrameData(in1)
            index_data = zeros(length(in1.PositionData), 0);
            time_data = zeros(length(in1.PositionData), 0);
            coords_data = zeros(7, 3, 0);
            for i = 1:length(in1.PositionData)
                temp = in1.PositionData(i).GetDataForFrame();
                coords_data(:,:,i) = temp.coords;
                index_data(i) = temp.index;
                time_data(i) = temp.time;
            end
            out1.index_data = index_data;
            out1.time_data = time_data;
            out1.coords_data = coords_data;
        end
        
        function out1 = GetFrameCoords(trial_in, frame_num, lh, port)
            if nargin == 2
                columns_in = 2;
                rows_in = 6;
                lh = false;
                port = false;
            elseif nargin == 3
                if lh
                    columns_in = 3;
                else
                    columns_in = 2;
                end
                rows_in = 6;
            elseif nargin == 4
                if lh
                    columns_in = 3;
                else
                    columns_in = 2;
                end
                if port
                    rows_in = 7;
                else
                    rows_in = 6;
                end
            end
            out1 = zeros(rows_in, columns_in, length(frame_num));
            for i = 1:length(frame_num)
                out1(:,:,i) = trial_in.PositionData(frame_num(i)).GetCoordinates(lh, port);
            end
        end
    end
end