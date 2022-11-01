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
        function result = GetETHData(input, inc_time)
            voltage = zeros(size(input.EthData));
            import ETH_Sensor
            if inc_time
                for i = 1:length(input.EthData)
                    time = zeros(size(input.EthData));
                    [voltage(i), time(i)] = input.EthData(i).GetETHVoltageWithTime();
                end
                result = [voltage, time];
            else
                for i = 1:length(input.EthData)
                    [voltage(i)] = input.EthData(i).GetETHReading();
                end
                result = voltage;
            end
        end
        
        function result = GetAccelerometerData(input, inc_time)
            import Accelerometer
            x = zeros(size(input.AccData));
            y = zeros(size(input.AccData));
            z = zeros(size(input.AccData));
            if inc_time
                for i = 1:length(input.AccData)
                    time = zeros(size(input.AccData));
                    [x(i), y(i), z(i), time(i)] = input.AccData(i).GetAccReadingWithTime();
                end
                result = [x, y, z, time];
            else
                for i = 1:length(input.AccData)
                    [x(i), y(i), z(i)] = input.AccData(i).GetAccReading();
                end
                result = [x, y, z];
            end
        end
        
        function result = GetFrameData(input)
            import CameraFrame
            index = zeros(size(input.PositionData));
            timestamp = zeros(size(input.PositionData));
            coords = zeros(size(input.PositionData));
            for i = 1:size(input.PositionData)
                [index(i), timestamp(i), coords(i)] = input.PositionData(i).GetDataForFrame();
            end
            result = [index, timestamp, coords];
        end
    end
end