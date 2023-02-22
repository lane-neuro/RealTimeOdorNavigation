clear variables; clc

cd('D:\Misc-Trial-Vetting-Dataset');
import RealTimeOdorNavigation/RealTimeOdorNavigation.*
% import RealTimeOdorNavigation/deps/INI_Config/IniConfig.m

dataset = RealTimeOdorNavigation();
save('extra-trials_2.22-unfiltered.mat', 'dataset', '-v7.3');

%%
nTrials = 1:15;
sz = [length(nTrials) 12];
varTypes = ["uint16","datetime","uint16","double","double","double","double","double","double","double","double","double"];
varNames = ["Index #","Date","Subject ID","Total Frames","Total Valid","% Valid","Total Invalid","% Invalid","Due to Likelihood","% Likelihood","Due to Region","% Region"];
stat_table = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
% fig = uifigure;
% uit = uitable(fig);
% uit.Data = stat_table;
% uit.ColumnSortable = true;
% uit.ColumnEditable = [false false true];
% uit.Position = [20 20 uit.Extent(3) uit.Extent(4)];

for trialNumb = 1:length(nTrials)
%     uit.DisplayData;
    allFrames = dataset.getDataForTrials(trialNumb, Valid_Type="all", DAQ_Output=false);
    t_Frames = length(allFrames.PositionData.FrameIndex);

    validFrames = dataset.getDataForTrials(trialNumb, Valid_Type="valid", DAQ_Output=false);
    t_Valid = length(validFrames.PositionData.FrameIndex);
    p_valid = round(t_Valid/t_Frames * 100, 1);

    invalidFrames = dataset.getDataForTrials(trialNumb, Valid_Type="invalid", DAQ_Output=false);
    likelihood_frames = invalidFrames.PositionData.FrameIndex(strcmp(invalidFrames.PositionData.FrameValidityReason,'likelihood'));
    region_frames = invalidFrames.PositionData.FrameIndex(strcmp(invalidFrames.PositionData.FrameValidityReason,'region'));
    t_Invalid = length(invalidFrames.PositionData.FrameIndex);
    p_invalid = round(t_Invalid/t_Frames * 100, 1);
    n_Likelihood = length(likelihood_frames);
    p_likelihood = round(n_Likelihood/t_Frames * 100, 1);
    n_Region = length(region_frames);
    p_region = round(n_Region/t_Frames * 100, 1);
    
    stat_table(trialNumb,:) = {trialNumb, allFrames.TrialDate, allFrames.SubjectID, t_Frames, t_Valid, p_valid, t_Invalid, p_invalid, n_Likelihood, p_likelihood, n_Region, p_region};
end
save('Lane_analysis_1-10.mat', 'stat_table', '-v7.3');

%%
trialNum = 1:15; % [13 16 18 20 28 29 41 42 56 64 69 83 88 104 105 106 118 130];
validFrames = dataset.getDataForTrials(trialNum, Valid_Type="valid", DAQ_Output=false);

for ii = 1:length(trialNum)
    fprintf('[RTON] Processing Data for Trial %i (#%i)\n', ii, trialNum(ii));
    frames = validFrames(ii).PositionData.FrameIndex(:);
    perc_frames = round(length(frames)*0.05);
    if(perc_frames > 50), perc_frames = 50; end
    frames = sort(randsample(frames(1:end),perc_frames));

    % angles = dataset.TrialDataset(trialNum).getAngleForFrames("Neck", "Nose", frames(1:end));
    coords = dataset.TrialDataset(trialNum(ii)).getCoordsForFrames(frames);
    vid_images = dataset.getImagesForFramesInTrial(trialNum(ii), frames(1:end));
    save(strcat("Lane_trial_",num2str(trialNum(ii)),".mat"),"vid_images","coords","frames",'-v7.3');
end

%%
% .mat file:
    % coords(ii) - 1:6 ; 1,2
    % vid_images(ii).Frame
    % vid_images(ii).Image
% new vars
    % validity(ii):   0 = correct
    %                 1 = incorrect coord
    %                 2 = port interference
    %                 3 = body coord out-of-region

trial = 15;
trialNum = 1:15; % [16 18 20 28 29 41 42 56 64 69 83 104 105 106 118];
validity = zeros(length(vid_images), 0);
figure('WindowState','maximized');
set(gcf,'Units','pixels');
set(groot,'defaultLineMarkerSize',20);

for zz = 1:length(vid_images)
    hold off
    imagesc(vid_images(zz).Image);
    title(strcat(int2str(vid_images(zz).Frame), " (",int2str(zz),")"));
    axis image
    axis tight
    hold on

    plot(coords(1,1,zz), coords(1,2,zz), '.');
    plot(coords(2,1,zz), coords(2,2,zz), '.');
    plot(coords(3,1,zz), coords(3,2,zz), '.');
    plot(coords(4,1,zz), coords(4,2,zz), '.');
    plot(coords(5,1,zz), coords(5,2,zz), '.');
    plot(coords(6,1,zz), coords(6,2,zz), '.');
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
        case 122, zz = zz - 2;
    end
    set(gcf,'CurrentCharacter','p');
    pause(.3);
end
save(strcat("Lane_trial_",num2str(trialNum(trial)),".mat"),"validity",'-append');
close all

%%
trialNum = 1:15;% [16 18 20 28 29 41 42 56 64 69 83 104 105 106 118];
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

for ii = 1:numel(vid_images)
    [nRows, ~, ~] = size(vid_images(ii).Image);
    if nRows > 300
        vid_images(ii).Image = imcrop(vid_images(ii).Image, [10 80 563 255]); % vid_images(ii).Image(80:335, 10:573, :)
    end

    figure, set(gcf,'Units','pixels');
    image(vid_images(ii).Image);
    axis image
    hold on
    title(vid_images(ii).Frame);
    text(20,285, sprintf('Neck->Nose   %0.5f', angles(ii,2)), 'FontSize',12);
    
    plot([coords(1,1,ii), coords(4,1,ii)], [coords(1,2,ii), coords(4,2,ii)], '.');
    plot([coords(4,1,ii), coords(5,1,ii)], [coords(4,2,ii), coords(5,2,ii)], '.');
    plot([coords(5,1,ii), coords(6,1,ii)], [coords(5,2,ii), coords(6,2,ii)], '.');
    plot(coords(7,1,ii), coords(7,2,ii), '.');    
end


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