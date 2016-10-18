% test action localization Sequence 97

dbstop if error;
warning off;

clear; close all; clc;

addpath(genpath('../3rdParty'));
addpath(genpath('.'));

% data parameters
opt.dataPath = fullfile('~','research','data','activitynet');
% preprocessing parameters
opt.diff = false;
opt.removeMean = false;
% train parameters
opt.metric = 'JBLD';
opt.H_structure = 'HHt';
opt.H_rows = 1;
opt.sigma = 1e-4;
% test parameters
opt.winSize = 8;
opt.stepSize = 1;
opt.minLength = 2;
opt.nCluster = -1;
opt.kNN_ratio = 0.1;
opt.scale_sig = 1;
opt.hitThres = 0.5;
opt.eigThres = 0.1;

load(fullfile('..', 'expData', 'activitynet_97.mat'));
currSeq = c3d_97;
gt = gt_97;
fps = 25;
c3d_winSize = 8;

videoFile = fullfile(opt.dataPath, 'video', 'activitynet_02_drinkBeer.mp4');
vidObj = VideoReader(videoFile);
% Create an axes
currAxes = axes;

% Read video frames until available
while hasFrame(vidObj)
    vidFrame = readFrame(vidObj);
    image(vidFrame, 'Parent', currAxes);
    currAxes.Visible = 'off';
    pause(1/vidObj.FrameRate);
end