% test action localization

dbstop if error;
warning off;

clear; close all; clc;

addpath(genpath('../3rdParty'));
addpath(genpath('.'));

% dataset parameters
opt.dataset = 'activitynet';
opt.dataPath = fullfile('~','research','data','activitynet');

% preprocessing parameters
opt.diff = false;
opt.removeMean = false;
% train parameters
opt.metric = 'JBLD';
opt.H_structure = 'HHt';
% opt.H_structure = 'HtH';
opt.H_rows = 1;
opt.sigma = 1e-4;
opt.pca = false;
opt.pcaThres = 0.99;
% test parameters
opt.IoU_thr = 0.5;
opt.winSize = 8;
opt.stepSize = 1;
opt.minLength = 4;
opt.nCluster = -1;
opt.kNN_ratio = 0.1;
opt.scale_sig = 1;
% opt.greedyThr = 0.1;
% opt.greedyThr = 9;
opt.greedyThr = 0;
opt.hitThres = 0.5;
opt.eigThres = 0.1;

% [data, gt, tr_te_split] = parseDataset(opt);

if strcmp(opt.dataset, 'activitynet');
    res = actionLoc_activitynet_incr(opt);
%     [accuracy, y_pred, y_val] = actionLoc_activitynet(data, gt, tr_te_split, opt);
    res
end
