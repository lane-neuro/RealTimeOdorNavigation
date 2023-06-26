clear variables; clc

cd('D:\Misc-Trial-Vetting-Dataset');
import RealTimeOdorNavigation/RealTimeOdorNavigation.*
% import RealTimeOdorNavigation/deps/INI_Config/IniConfig.m

dataset = RealTimeOdorNavigation();
save('extra-trials_2.22-unfiltered.mat', 'dataset', '-v7.3');

%%
nTrials = 1:340;
sz = [length(nTrials) 12];
varTypes = ["uint16","datetime","uint16","double","double","double","double","double","double","double","double","double"];
varNames = ["Index #","Date","Subject ID","Total Frames","Total Valid","% Valid","Total Invalid","% Invalid","Due to Likelihood","% Likelihood","Due to Region","% Region"];
stat_table = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

for trialNumb = 1:length(nTrials)
%     uit.DisplayData;
    allFrames = dataset.getDataForTrials(trialNumb, Valid_Type="all", ...
        DAQ_Output=false,Likelihood=true,Validity_Verbose=true);
    t_Frames = length(allFrames.PositionData.FrameIndex);

    validFrames = dataset.getDataForTrials(trialNumb, Valid_Type="valid", ...
        DAQ_Output=false, Validity_Verbose=true, Likelihood=true);
    t_Valid = length(validFrames.PositionData.FrameIndex);
    p_valid = round(t_Valid/t_Frames * 100, 1);

    invalidFrames = dataset.getDataForTrials(trialNumb, Valid_Type="invalid", ...
        DAQ_Output=false, Validity_Verbose=true, Likelihood=true);
    likelihood_frames = invalidFrames.PositionData.FrameIndex( ...
        strcmp(invalidFrames.PositionData.FrameValidityReason,'likelihood'));
    region_frames = invalidFrames.PositionData.FrameIndex( ...
        strcmp(invalidFrames.PositionData.FrameValidityReason,'region'));
    t_Invalid = length(invalidFrames.PositionData.FrameIndex);
    p_invalid = round(t_Invalid/t_Frames * 100, 1);
    n_Likelihood = length(likelihood_frames);
    p_likelihood = round(n_Likelihood/t_Frames * 100, 1);
    n_Region = length(region_frames);
    p_region = round(n_Region/t_Frames * 100, 1);
    
    stat_table(trialNumb,:) = {trialNumb, allFrames.TrialDate, allFrames.SubjectID, ...
        t_Frames, t_Valid, p_valid, t_Invalid, p_invalid, n_Likelihood, ...
        p_likelihood, n_Region, p_region};
end
save('Lane_analysis_2-23.mat', 'stat_table', '-v7.3');

%%
trialNum = [163 184 197 214 242 256 276 279 304 312 315 316 317 323 332];

validFrames = dataset.getDataForTrials(trialNum, Valid_Type="valid", DAQ_Output=false);

%%
for ii = 6:length(trialNum)
    fprintf('[RTON] Processing Data for Trial %i (#%i/%i)\n', trialNum(ii), ii, length(trialNum));
    frames = validFrames(ii).PositionData.FrameIndex(:);
    perc_frames = round(length(frames)*0.05);
    if(perc_frames > 50), perc_frames = 50; end
    frames = sort(randsample(frames(1:end),perc_frames));

    % angles = dataset.TrialDataset(trialNum).getAngleForFrames("Neck", "Nose", frames(1:end));
    coords = dataset.TrialDataset(trialNum(ii)).getCoordsForFrames(frames);
    imgs_rear = dataset.getImagesForFramesInTrial(trialNum(ii), frames(1:end));
    save(strcat("../Lane_trial_",num2str(trialNum(ii)),".mat"),"imgs_rear","coords","frames",'-v7.3');
    % DO NOT USE VID_IMAGES. USE PROC_IMAGES.
end

%% need to overwrite vid_images var
trialNum = [163 184 197 214 242 256 276 279 304 312 315 316 317 323 332];

for ii = 1:numel(trialNum)
    load(strcat("../Lane_trial_",num2str(trialNum(ii)),".mat"));
    clear proc_images
    name = dataset.TrialDataset(trialNum(ii)).Name;
    dataset.TrialDataset(trialNum(ii)).VIDEO_FILE_SUFFIX = 'DLC_resnet50_odor-arenaOct3shuffle1_200000_labeled.mp4';
    dataset.TrialDataset(trialNum(ii)).VideoPath = strcat(name, 'DLC_resnet50_odor-arenaOct3shuffle1_200000_labeled.mp4');
    cd(strcat(name, '\images'));
    delete *_dlc_processed.png
    cd ..\..\
    proc_images = dataset.getImagesForFramesInTrial(trialNum(ii), frames(1:end));
    save(strcat("../Lane_trial_",num2str(trialNum(ii)),".mat"),"proc_images",'-append');
end

%%
% .mat file:
    % coords(ii) - 1:6 ; 1,2
    % vid_images(ii).Frame  -------> proc_images(ii).Frame
    % vid_images(ii).Image  -------> proc_images(ii).Image
% new vars
    % validity(ii):   0 = correct
    %                 1 = incorrect coord
    %                 2 = port interference
    %                 3 = body coord out-of-region

trial = 15;
trialNum = [163 184 197 214 242 256 276 279 304 312 315 316 317 323 332];
load(strcat("Lane_trial_",num2str(trialNum(trial)),".mat"));
arena_coords = dataset.getArenaDataForTrials(trialNum);
x_offset = int32(round(arena_coords(1,1,trial) - mean(arena_coords(1,1,:))));
y_offset = int32(round(arena_coords(1,2,trial) - mean(arena_coords(1,2,:))));

% crop parameters
x1 = 9; 
x2 = 573; 
y1 = 79; 
y2 = 335;


validity = zeros(length(proc_images), 0);
figure('WindowState','maximized');
set(gcf,'Units','pixels');
set(groot,'defaultLineMarkerSize',20);

for zz = 1:length(proc_images)
    hold off

    % X: +5 px; Y: +30 px
%    imagesc(vid_images(zz).Image(84:340, 39:603, :));
    % X: +5 px; Y: +4 px
%    imagesc(vid_images(zz).Image(84:340, 13:577, :));
    % Y: crop parameters
%    imagesc(vid_images(zz).Image(y1:y2, x1:x2, :));
    % raw image
    imagesc(proc_images(zz).Image());

    title(strcat(int2str(proc_images(zz).Frame), " (",int2str(zz),")"));
    axis image
    axis tight
    hold on

    % coordinate plotting for DLC validation measures
    plot(coords(1,1,zz), coords(1,2,zz), '.');
    plot(coords(2,1,zz), coords(2,2,zz), '.');
    plot(coords(3,1,zz), coords(3,2,zz), '.');
    plot(coords(4,1,zz), coords(4,2,zz), '.');
    plot(coords(5,1,zz), coords(5,2,zz), '.');
    plot(coords(6,1,zz), coords(6,2,zz), '.');
    plot(arena_coords(1,1,trial), arena_coords(1,2,trial), '.');
    plot([CameraFrame.LEFT_INSET, CameraFrame.LEFT_INSET],[0, 256],'-');
    plot([CameraFrame.WIDTH - CameraFrame.RIGHT_INSET, ...
        CameraFrame.WIDTH - CameraFrame.RIGHT_INSET],[0, 256],'-');
    figure(gcf);

    waitfor(gcf,'CurrentCharacter');
    switch uint8(get(gcf,'CurrentCharacter'))
        case 97, validity(zz) = 0;
        case 115, validity(zz) = 1;
        case 100, validity(zz) = 2;
        case 102, validity(zz) = 3;
        otherwise, break;
    end
    set(gcf,'CurrentCharacter','p');
    pause(.3);
end
%save(strcat("Lane_trial_",num2str(trialNum(trial)),".mat"),"validity",'-append');
fprintf('[RTON] Validation %i/%i Complete: Trial %i\n', trial, length(trialNum), trialNum(trial));
close all

%%
fileName = strcat("Lane_trial_",num2str(trialNum(:)),".mat");
validity_mat = zeros(15,50);

%%
for t = 1:15
    load(fileName(t), 'validity');
    sz = numel(validity);
    validity_mat(t,1:sz) = validity(1,1:sz);
end

%%
Trial.saveData(dataset.TrialDataset(trialNum), 'frames', frames);
%%
for ii = 1:numel(slim_frames)
    [nRows, ~, ~] = size(slim_frames(ii).Image);
    if nRows > 300
        slim_frames(ii).Image = imcrop(slim_frames(ii).Image, [10 80 563 255]); % vid_images(ii).Image(80:335, 10:573, :)
    end

    figure, set(gcf,'Units','pixels','WindowState','maximized');
    image(slim_frames(ii).Image);
    axis image
    hold on
    title(slim_frames(ii).Frame);
    %text(20,285, sprintf('Neck->Nose   %0.5f', angles(ii,2)), 'FontSize',12);
    
%     plot([rear_coords(1,1,ii), rear_coords(4,1,ii)], [rear_coords(1,2,ii), rear_coords(4,2,ii)], '.');
%     plot([rear_coords(4,1,ii), rear_coords(5,1,ii)], [rear_coords(4,2,ii), rear_coords(5,2,ii)], '.');
%     plot([rear_coords(5,1,ii), rear_coords(6,1,ii)], [rear_coords(5,2,ii), rear_coords(6,2,ii)], '.');
    %plot(rear_coords(7,1,ii), rear_coords(7,2,ii), '.');    
end

%% Trim Rearing Frames to 50 per trial
for ii = 1:15
    rear_trim(ii).Rearing_Frames = randsample(rear_trim(ii).Rearing_Frames(1:end),50);
end

%% Rearing Validation

% .mat file:
    % rear_trim(iTrial).Rearing_Frames(ii).Frame
    % rear_trim(iTrial).Rearing_Frames(ii).Image
    % rear_trim(iTrial).Rearing_Frames(ii).xz_diff
    % rear_trim(iTrial).Rearing_Frames(ii).Validity (likelihood validity)
% new vars
    % rear_trim(iTrial).Rearing_Frames(ii).rear_value:  0 = correct (rearing)
    %                                                   1 = incorrect (not rearing)

clear rear_value
figure('WindowState','maximized');
set(gcf,'Units','pixels');
set(groot,'defaultLineMarkerSize',20);

for ii = 1:50
    hold off

    imagesc(rear_trim(iTrial).Rearing_Frames(ii).Image());

    title(strcat(int2str(rear_trim(iTrial).Rearing_Frames(ii).Frame), ...
        " (",int2str(ii),")"));
    axis image
    axis tight
    hold on

    figure(gcf);

    waitfor(gcf,'CurrentCharacter');
    switch uint8(get(gcf,'CurrentCharacter'))
        case 97, rear_trim(iTrial).Rearing_Frames(ii).rear_value = 0;
        case 115, rear_trim(iTrial).Rearing_Frames(ii).rear_value = 1;
        otherwise, break;
    end
    set(gcf,'CurrentCharacter','p');
    pause(.3);
end

rear_value = [rear_trim(iTrial).Rearing_Frames.rear_value];
iTrial = iTrial + 1;
close all


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