classdef ETH_Sensor
    properties
        Voltage double
        DAQ_Time uint32
        Camera_Time uint32
        Frame_Index uint32 = 0
    end
    methods
        function obj = ETH_Sensor(voltage, time, c_time)
            if nargin > 1
                obj.Voltage = voltage;
                obj.DAQ_Time = time;
                obj.Camera_Time = c_time;
            end
        end
        
        function s = saveobj(obj)
            s.Voltage = obj.Voltage;
            s.DAQ_Time = obj.DAQ_Time;
            s.Camera_Time = obj.Camera_Time;
            s.Frame_Index = obj.Frame_Index;
        end
        
        function voltage = getEthReading(this), voltage = this.Voltage; end
        function time = getEthTime(this), time = this.DAQ_Time; end
        
        function [voltage, time] = getEthVoltageWithTime(this)
            voltage = this.getEthReading();
            time = this.getEthTime();
        end
    end
    
    %%
    methods (Static)
        function obj = loadobj(s)
            if isstruct(s)
                obj = ETH_Sensor(s.Voltage, s.DAQ_Time, s.Camera_Time);
            else
                obj = s;
            end
        end
    end
end