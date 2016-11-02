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
opt.IoU_thr = 0.1;
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
% SOS parameter
opt.mOrd = 2;
opt.nVar = 5;
opt.sosThres = 3;

% [data, gt, tr_te_split] = parseDataset(opt);

if strcmp(opt.dataset, 'activitynet');
%     res = actionLoc_activitynet_incr(opt);
%     res = actionLoc_activitynet_incr_jbld_sos(opt);
%     res = actionLoc_activitynet_incr_c3d_svm(opt);
%     res = actionLoc_activitynet_incr_c3d_sos(opt);
    res = nonactionLoc_activitynet_incr_c3d_sos(opt);
    
%     res = actionLoc_activitynet_incr_log_c3d_sos(opt);
%     [accuracy, y_pred, y_val] = actionLoc_activitynet(data, gt, tr_te_split, opt);
    res
end
