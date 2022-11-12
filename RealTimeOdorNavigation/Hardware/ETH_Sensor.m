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
        
        function voltage = getEthReading(this), voltage = this.Voltage; end
        function time = getEthTime(this), time = this.DAQ_Time; end
        
        function [voltage, time] = getEthVoltageWithTime(this)
            voltage = this.getEthReading();
            time = this.getEthTime();
        end
    end
end