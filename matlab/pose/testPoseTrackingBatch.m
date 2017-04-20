% show my demo results with Wei's code

close all; dbstop if error;
addpath(genpath('../../matlab'));
addpath(genpath('../../3rdParty'));
param = config();

% fprintf('Description of selected model: %s \n', param.model(param.modelID).description);

%% Edit this part
np = 14;

trackPath = fullfile('..','..','expData', 'ucf_tracks');

actionList = {
    'Diving-Side','Golf-Swing-Back','Golf-Swing-Front','Golf-Swing-Side',...
    'Kicking-Front','Kicking-Side','Lifting','Riding-Horse','Run-Side',...
    'SkateBoarding-Front','Swing-Bench','Swing-SideAngle','Walk-Front',...
    };
nInstanceList = [14, 5, 8, 5, 10, 10, 6, 12, 13, 12, 20, 13, 22];

% action = 'Diving-Side';
    % instance = '001';
%     actionIndex = find(strcmp(action, actionList));
for ai = 1:length(actionList)
    action = actionList{ai};
    if ~exist(fullfile(trackPath, action), 'dir')
        mkdir(fullfile(trackPath, action))
    end
    actionIndex = find(strcmp(action, actionList));
    for vi = 1:nInstanceList(actionIndex);
        instance = sprintf('%03d', vi);
        if ~exist(fullfile(trackPath, action, instance), 'dir')
            mkdir(fullfile(trackPath, action, instance))
        end
        
        if ~exist(fullfile('..','..', 'expData', 'ucf_pose', action, instance,'poseCPM.mat'), 'file')
            continue;
        end
        load(fullfile('..','..', 'expData', 'ucf_pose', action, instance,'poseCPM.mat'));
        dataPath = fullfile('~','research','data','ucf_sports_actions',action,instance);
        imgFiles = dir([dataPath '/*.jpg']);
        
        poseDir = fullfile('~', 'research', 'code', 'extern', ...
            'convolutional-pose-machines-release', 'testing', 'python', ...
            'ucf_pose', action, instance);
        poseFiles = dir(fullfile(poseDir, '*.mat'));
        
        poseVideo = cell(1, length(poseFiles));
        for i = 1:length(poseFiles)
            load(fullfile(poseDir, poseFiles(i).name));
            if isempty(prediction)
                continue;
            end
            for j = 1:size(prediction, 3)
                pred = permute(prediction, [2 1 3]);
                pred = reshape(pred, [], size(prediction, 3));
                poseVideo{i} = pred;
            end
        end
        opt.thres = 300;
        poseTracklet = connectPose(poseVideo, opt);
        if isempty(poseTracklet), continue; end
        
%         nFrame = length(poseFiles);
%         poseTrack = associateTracklet(poseTracklet, np, nFrame);

        len = [poseTracklet.length];
        ind = find(len == max(len), 1);
        poseTrack = poseTracklet(ind);
        
        save(fullfile(trackPath, action, instance, 'poseTrack.mat'), 'poseTrack');
        
%         for i = 1:length(imgFiles)
%             im = imread(fullfile(dataPath, imgFiles(i).name));
%             load(fullfile(poseDir, poseFiles(i).name));
%             pred = poseTrack.data(:, i);
%             pred = reshape(pred, 2, [])';
%             predict = pred;
%             if isempty(predict)
%                 continue;
%             end
%             wei_visualize(im, predict, param)
%             pause(0.1);
%         end
        
    end
end