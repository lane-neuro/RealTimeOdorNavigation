classdef Accelerometer < handle
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
        
        function [time, x, y, z, cam_time] = getAccReading(this)
            arguments (Input)
                this Accelerometer
            end

            time = this.getAccTime();
            x = this.X;
            y = this.Y;
            z = this.Z;
            cam_time = this.Camera_Time;
        end
        
        function time = getAccTime(this), time = this.DAQ_Time; end
    end
    
    %%
    methods (Static)
        function s = saveobj(obj)
            s = struct;
            s.X = obj.X;
            s.Y = obj.Y;
            s.Z = obj.Z;
            s.DAQ_Time = obj.DAQ_Time;
            s.Camera_Time = obj.Camera_Time;
        end

        function obj = loadobj(s)
            if isstruct(s)
                obj = Accelerometer([s.X s.Y s.Z], s.DAQ_Time, s.Camera_Time);
            else
                obj = s;
            end
        end
    end
end