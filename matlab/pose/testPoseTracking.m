% show my demo results with Wei's code

close all; dbstop if error;
addpath(genpath('../../matlab'));
addpath(genpath('../../3rdParty'));
param = config();
model = param.model(param.modelID);
np = model.np;

% fprintf('Description of selected model: %s \n', param.model(param.modelID).description);

%% Edit this part
actionList = {
    'Diving-Side','Golf-Swing-Back','Golf-Swing-Front','Golf-Swing-Side',...
    'Kicking-Front','Kicking-Side','Lifting','Riding-Horse','Run-Side',...
    'SkateBoarding-Front','Swing-Bench','Swing-SideAngle','Walk-Front',...
    };
action = 'Lifting';
instance = '001';
% load(fullfile('..','..', 'expData', 'ucf_pose', action, instance,'poseCPM.mat'));
imgPath = fullfile('~','research','data','ucf_sports_actions',action,instance);

% get pose detections
poseDir = fullfile('~', 'research', 'code', 'extern', ...
    'convolutional-pose-machines-release', 'testing', 'python', ...
    'ucf_pose', action, instance);
poseFiles = dir(fullfile(poseDir, '*.mat'));

poseDetection = cell(1, length(poseFiles));
for i = 1:length(poseFiles)
    load(fullfile(poseDir, poseFiles(i).name));
    if isempty(prediction)
        continue;
    end
    for j = 1:size(prediction, 3)
        pred = permute(prediction, [2 1 3]);
        pred = reshape(pred, [], size(prediction, 3));
        poseDetection{i} = pred;
    end
end

% associate detection into tracklets
opt.locThres = 1000;
poseTracklet = associatePose(poseDetection, opt);

poseTrackletClean = cleanTracklet(poseTracklet);

% len = [poseTracklet.length];
% ind = find(len == max(len), 1);
% poseTrack = poseTracklet(ind);

% associate short tracklets into longer tracks
nFrame = length(poseFiles);
poseTrack = associateTracklet(poseTrackletClean, np, nFrame);

% display the trackes superposed on video
displayPoseTrack(imgPath, poseTrack);