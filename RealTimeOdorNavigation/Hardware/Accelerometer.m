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
    end
end