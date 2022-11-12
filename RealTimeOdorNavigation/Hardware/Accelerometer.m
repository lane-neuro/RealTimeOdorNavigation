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
        
        function [x, y, z] = getAccReading(this)
            x = this.X;
            y = this.Y;
            z = this.Z;
        end
        
        function time = getAccTime(this), time = this.DAQ_Time; end
        
        function [x, y, z, time] = getAccReadingWithTime(this)
            [x, y, z] = this.getAccReading();
            time = this.getAccTime();
        end
    end
end