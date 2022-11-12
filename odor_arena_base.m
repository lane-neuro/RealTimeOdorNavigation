clear all; close all; clc

cd('D:\2022TrialData')

[file, ~] = uigetfile('*.csv;*.dat', 'MultiSelect', 'on');
for i = 1:length(file), files(i) = dir(char(file(i))); end
clear file i

import RealTimeOdorNavigation
dataset = RealTimeOdorNavigation(files);
clear files

test = dataset.getDataStructForTrials(1:2);
test = dataset.findValidFramesForTrials(1:2);

%%
%{   

%% Velocity/Timing Calculations

port_med = [0 0];
bodyCoords = [];
likelihood_matrix = [];

for k = 1:length(trial_data)
    port_med = repmat([trial_data(k).arena(1).port(1).x trial_data(k).arena(1).port(1).y], length(trial_data(k).frame), 1);
    for z = 1:length(trial_data(k).frame)
        bodyCoords(end+1, :) = [trial_data(k).frame(z).bodyPart.body.x trial_data(k).frame(z).bodyPart.body.y];
        likelihood_matrix(end+1, :) = trial_data(k).frame(z).bodyPart.body.likelihood;
    end
    
    vel_matrix = vecnorm(bodyCoords' - port_med')';
    vel_change = vecnorm((bodyCoords(1:end-1, :) - bodyCoords(2:end, :)), 2, 2);
    
    % startFrame = first instance of likelihood_matrix > 0.99 & vel_change
    % < 2.0
    for t = 2:length(trial_data(k).frame)
        if(likelihood_matrix(t) > 0.99 && vel_change(t) < 1)
            trial_data(k).stats(1).startFrame = t;
            fprintf('Trial %i - startFrame: %i\n', k, t);
            break
        end
    end
    
    % endFrame = vel_matrix < 20 & likelihood > 0.995 & vel_change < 1.0
    for v = trial_data(k).stats(1).startFrame+60:length(trial_data(k).frame)
        if(likelihood_matrix(v) > 0.99 && vel_change(v-1) < 2 && vel_matrix(v) < 20)
            trial_data(k).stats(1).endFrame = v;
            fprintf('Trial %i - endFrame: %i\n', k, v);
            break
        end
    end

    %{
    % jumps: startFrame = first vel_change > 50; endFrame (4th instance of) = (vel_change <
    % 50) + 1
    for p = trial_data(k).stats(1).startFrame:trial_data(k).stats(1).endFrame
        if(vel_change(p) > 50)
            if(trial_data(k).stats(1).jumps(end).startFrame > 0)
                while vel_change(p) > 50
                    p = p + 1;
                end
                trial_data(k).stats(1).jumps(end).endFrame = p;
                trial_data(k).stats(1).jumps(end+1).startFrame = 0;
                continue
            end
            trial_data(k).stats(1).jumps(end).startFrame = p;
            while vel_change(p) > 50
                p = p + 1;
            end
        end
    end
    %}
    
    % jumps: via likelihood_matrix
    % find frame().index of all frame().bodyPart.body.likelihood < 0.9
    trial_data(k).stats(1).jumps = find(arrayfun(@(index) (trial_data(k).frame(index).bodyPart.body.likelihood < 0.9 && trial_data(k).frame(index).bodyPart.body.likelihood > 0.2), 1:numel(trial_data(k).frame)))';
    
    %figure('Name', append(trial_data(k).stats(1).trialName, ': vel_matrix')), plot(vel_matrix(1:numel(trial_data(k).frame)-1), 'r');
    %drawJumps(trial_data, k);
    %figure('Name', append(trial_data(k).stats(1).trialName, ': vel_change')), plot(vel_change(1:numel(trial_data(k).frame)-1), 'b');
    %drawJumps(trial_data, k);
    figure('Name', append(trial_data(k).stats(1).trialName, ': likelihood_matrix')), plot(likelihood_matrix(1:numel(trial_data(k).frame)-1), 'g');
    drawJumps(trial_data, k);
end

function drawJumps(trial_data, trialnum)
hold on
for t = 2:numel(trial_data(trialnum).stats(1).jumps)-2
    if(trial_data(trialnum).stats(1).jumps(t) ~= trial_data(trialnum).stats(1).jumps(t-1)+1 || trial_data(trialnum).stats(1).jumps(t) ~= trial_data(trialnum).stats(1).jumps(t+1)-1)
        xline(trial_data(trialnum).stats(1).jumps(t), '--k');
    end
end
hold off
end
%}