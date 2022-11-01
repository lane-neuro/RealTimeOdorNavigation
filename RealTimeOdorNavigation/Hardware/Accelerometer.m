classdef Accelerometer
    properties
        X {mustBeNumeric}
        Y {mustBeNumeric}
        Z {mustBeNumeric}
        Time uint32
        CameraTime uint32
    end
    methods
        function obj = Accelerometer(acc_frame_data, time, c_time)
            if nargin > 0
                obj.X = acc_frame_data(1);
                obj.Y = acc_frame_data(2);
                obj.Z = acc_frame_data(3);
                obj.Time = time;
                obj.CameraTime = c_time;
            end
        end
        
        function [x, y, z] = GetAccReading(input)
            x = input.X;
            y = input.Y;
            z = input.Z;
        end
        
        function time = GetAccTime(input)
            time = input.Time;
        end
        
        function [reading, time] = GetAccReadingWithTime(input)
            reading = input.GetAccReading();
            time = input.GetAccTime();
        end
    end
end