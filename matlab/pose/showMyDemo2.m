% show my demo results with Wei's code

close all;
addpath(genpath('../../matlab'));
param = config();

% fprintf('Description of selected model: %s \n', param.model(param.modelID).description);

%% Edit this part
actionList = {
'Diving-Side','Kicking-Front','Run-Side','Walk-Front','Golf-Swing-Back',...
'Kicking-Side','SkateBoarding-Front','Golf-Swing-Front','Lifting',...
'Swing-Bench','Golf-Swing-Side','Riding-Horse','Swing-SideAngle' };

action = 'Diving-Side';
instance = '001';
% load(fullfile('..', '..', 'expData', 'ucf_pose', action, instance,'poseCPM.mat'));
dataPath = fullfile('~','research','data','ucf_sports_actions',action,instance);
imgFiles = dir([dataPath '/*.jpg']);

poseDir = fullfile('~', 'research', 'code', 'extern', ...
    'convolutional-pose-machines-release', 'testing', 'python', ...
    'ucf_pose', action, instance);
poseFiles = dir(fullfile(poseDir, '*.mat'));

% load poseOut.mat

% display
% vidObj = VideoWriter('myData', 'MPEG-4');
% vidObj.FrameRate = 5;
% open(vidObj);
for i = 1:length(imgFiles)
    im = imread(fullfile(dataPath, imgFiles(i).name));
    load(fullfile(poseDir, poseFiles(i).name));
    if isempty(prediction)
        continue;
    end
    predict = prediction;
%     predict = reshape(poseOut(:, i), 2, [])';
    wei_visualize(im, predict, param)
%     currFrame = getframe;
%     writeVideo(vidObj, currFrame);
    pause(0.1);
end

% close(vidObj);