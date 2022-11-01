classdef ETH_Sensor
    properties
        Voltage {mustBeNumeric}
        Time uint32
        CameraTime uint32
        CameraFrame uint32
    end
    methods
        function obj = ETH_Sensor(voltage, time, c_time)
            if nargin > 0
                obj.Voltage = voltage;
                obj.Time = time;
                obj.CameraTime = c_time;
            end
        end
    end
end