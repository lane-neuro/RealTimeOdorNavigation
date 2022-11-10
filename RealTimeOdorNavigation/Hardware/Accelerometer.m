classdef Accelerometer
    properties
        X {mustBeNumeric}
        Y {mustBeNumeric}
        Z {mustBeNumeric}
        DAQ_Time uint32
        CameraTime uint32
    end
    methods
        function obj = Accelerometer(acc_frame_data, time, c_time)
            if nargin > 0
                obj.X = acc_frame_data(1);
                obj.Y = acc_frame_data(2);
                obj.Z = acc_frame_data(3);
                obj.DAQ_Time = time;
                obj.CameraTime = c_time;
            end
        end
        
        function [x, y, z] = GetAccReading(in1)
            x = in1.X;
            y = in1.Y;
            z = in1.Z;
        end
        
        function time = GetAccTime(in1)
            time = in1.DAQ_Time;
        end
        
        function [x, y, z, time] = GetAccReadingWithTime(in1)
            [x, y, z] = in1.GetAccReading();
            time = in1.GetAccTime();
        end
    end
end