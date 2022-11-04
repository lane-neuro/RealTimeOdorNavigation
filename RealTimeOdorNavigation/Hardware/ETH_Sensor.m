classdef ETH_Sensor
    properties
        Voltage {mustBeNumeric}
        DAQ_Time uint32
        Camera_Time uint32
        Frame_Index uint32
    end
    methods
        function obj = ETH_Sensor(voltage, time, c_time)
            if nargin > 0
                obj.Voltage = voltage;
                obj.DAQ_Time = time;
                obj.Camera_Time = c_time;
            end
        end
        
        function voltage = GetETHReading(in1)
            voltage = in1.Voltage;
        end
        
        function time = GetETHTime(in1)
            time = in1.DAQ_Time;
        end
        
        function [voltage, time] = GetETHVoltageWithTime(in1)
            voltage = in1.GetETHReading();
            time = in1.GetETHTime();
        end
    end
end