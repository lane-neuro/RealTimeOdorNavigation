%% loads accelerometer data
clear all; close all;clc

[fns pns, ins] = uigetfile('*.avi.dat', 'MultiSelect', 'on');



cd(pns);

fileID = fopen(fns);

data = fread(fileID,'float64','ieee-be');


n_ten = find(data==-500);
n_ten = n_ten(14:end); %Disregarding the first 19 samples
t_s = data(n_ten+1); % Time in milliseconds
% TS = data(n_ten+2); %SAMPLE TIME per TRIAL
frame_stamp = data(n_ten+2); % Time stamp for each camera frame
%t_camera = unique(frame_stamp./1000); % Camera Frame time (in s)
ETH = data(n_ten+4);
x = data(n_ten+9);
y = data(n_ten+10);
z = data(n_ten+8);
dt = median(diff(t_s));
Fs = 1/(dt/1000);

new_fn = erase(fns, '.avi.dat');

[ETH, ts] = resample(ETH,t_s/1000,Fs,'linear');
x = resample(x,t_s/1000,Fs,'linear');
y = resample(y,t_s/1000,Fs,'linear');
z = resample(z,t_s/1000,Fs,'linear');

t=0:1/Fs:(150.-1/Fs);
t = t';

a= 1.;
tau_rise = 0.02;
tau_decay = 10.;

kernel = a*(exp(-t/tau_decay)-exp(-t/tau_rise)); %kernel
kernel = (kernel-min(kernel))./(max(kernel)-min(kernel));%scaling the kernel (from 0 to 1)

% paused here %

%%% Deconvolving ETH sensor
lpFilt = designfilt('lowpassfir','PassbandFrequency',0.001, ...
    'StopbandFrequency',5,'PassbandRipple',0.5, ...
    'StopbandAttenuation',100,'DesignMethod','kaiserwin',...
    'SampleRate', Fs);

ETH_filt = filtfilt(lpFilt, ETH);
ETHfilt_fft = fft(ETH_filt);
kernel_fft = fft(kernel, numel(ETH));
ETHdeconv_fft = ETHfilt_fft./kernel_fft;
ETHdeconv = ifft(ETHdeconv_fft);

%Accelerometer Signals
acc_x = (x-1.6325)./0.3;
acc_y = (y-1.665)./0.3;
acc_z = (z-1.65)./0.3;

lpFilt2 = designfilt('lowpassfir','PassbandFrequency',0.001, ...
    'StopbandFrequency',40,'PassbandRipple',0.5, ...
    'StopbandAttenuation',100,'DesignMethod','kaiserwin',...
    'SampleRate', Fs);

filt_x = filtfilt(lpFilt2, acc_x);
filt_y = filtfilt(lpFilt2, acc_y);
filt_z = filtfilt(lpFilt2, acc_z);

med_x = movmedian(filt_x, [100 0]);
med_y = movmedian(filt_y, [100 0]);
med_z = movmedian(filt_z, [100 0]);

%% load the CSV file with the position data to get the number of video frames
DLCOutput = csvread(csv_fn, 3, 0);
nFrames = size(DLCOutput, 1);
f_c = (max(t_s)./1000)./nFrames;
t_camera = DLCOutput(:, 1)*f_c;

%% Get the difference in the medians and align them with camera time
xz_diff = med_z-med_x;
xz_diff2 = interp1(ts, xz_diff, t_camera);

thr = 0.3379; %% threshold from Figure 3A

rear_inds = (xz_diff2>thr); %rearing indices > thresshold
for_inds = (xz_diff2<thr); %foraging indices < threshold