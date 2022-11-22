classdef Accelerometer
    properties
        X double
        Y double
        Z double
        DAQ_Time uint32
        Camera_Time uint32
    end
    methods
        function obj = Accelerometer(acc_data, time, c_time)
            if nargin > 1
                obj.X = acc_data(1);
                obj.Y = acc_data(2);
                obj.Z = acc_data(3);
                obj.DAQ_Time = time;
                obj.Camera_Time = c_time;
            end
        end
        
        function s = saveobj(this)
            s.X = this.X;
            s.Y = this.Y;
            s.Z = this.Z;
            s.DAQ_Time = this.DAQ_Time;
            s.Camera_Time = this.Camera_Time;
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
    
    %%
    methods (Static)
        function obj = loadobj(s)
            if isstruct(s)
                obj = Accelerometer([s.X s.Y s.Z], s.DAQ_Time, s.Camera_Time);
            else
                obj = s;
            end
        end
    end
end