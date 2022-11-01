clear all;close all;clc 

% TODO: all 
% find diff<0
% of those with diff<0 find max(test)
% structure definitions %

trial_data = struct('index', {}, 'trial_name', {}, 'csv_elements', {}, 't_camera', {}, 'difference', {}, 'outliers', {});


folder = 'D:\2022TrialData';
csvFiles = dir(fullfile(folder, '*.csv'));
datFiles = dir(fullfile(folder, '*.dat'));

for i = 1:10%length(csvFiles) % 137
    clear j n_outs
    trial_data(i).index = i;
    fn = char(datFiles(i).name);
    trial_data(i).trial_name = fn(1:end-8);
    
    datatable = readtable(csvFiles(i).name, 'ReadVariableNames', false);
    trial_data(i).csv_elements = height(datatable) - 3;
    
    fileID = fopen(fn);
    dat_data = fread(fileID,'float64','ieee-be');
    n_ten = find(dat_data==-500);
    frame_stamp = dat_data(n_ten+2);
    ind = find(abs(diff(frame_stamp>10^6)), 1, 'last');
    n_ten = n_ten(ind+1:end);
    frame_stamp = dat_data(n_ten+2);
    trial_data(i).t_camera = unique(frame_stamp, 'stable');
    test = diff(trial_data(i).t_camera);
    trial_data(i).difference = numel(trial_data(i).t_camera) - trial_data(i).csv_elements;
    for j = 1:100
         n_outs(j) = numel(find(test<=j));
    end  
%   ind = [2:-1:0];
%   for k=1:numel(ind)
%    ind_out = find(n_outs-(trial_data(i).difference)==ind(k), 1, 'last');
%    if~isempty(ind_out)
%        trial_data(i).outliers(k) =ind_out;
%    else
%        trial_data(i).outliers(k) = 100;
%    end
%end
% trial_data(i).outliers = find(n_outs>=trial_data(i).difference, 1, 'last');
trial_data(i).outliers = find(n_outs>=trial_data(i).csv_elements, 1);

    fprintf('Trial Done: %i\n', i);
end