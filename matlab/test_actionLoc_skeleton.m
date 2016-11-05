% test action localization

dbstop if error;
warning off;

clear; close all; clc;

addpath(genpath('../3rdParty'));
addpath(genpath('.'));

% dataset parameters
% opt.dataset = 'MAD';
% opt.dataPath = fullfile('~','research','data','MAD','data_code','Sub_all');
% opt.nAction = 36;
opt.dataset = 'ConcurrentAction';
opt.dataPath = fullfile('~','research','data','concurrentAction');

% preprocessing parameters
opt.diff = false;
opt.removeMean = false;
% train parameters
opt.metric = 'JBLD';
% opt.metric = 'JBLD_XYX';
opt.H_structure = 'HHt';
% opt.H_structure = 'HtH';
opt.H_rows = 3;
opt.sigma = 1e-4;
opt.pca = false;
opt.pcaThres = 0.99;
% test parameters
opt.IoU_thr = 0.5;
opt.winSize = 30;
opt.stepSize = 1;
opt.minLength = 10;
opt.nCluster = 40;
opt.kNN_ratio = 0.1;
opt.scale_sig = 1;
opt.greedyThr = 0.1;
opt.eigThres = 0.1;
% opt.greedyThr = 9;
opt.hitThres = 0.5;
opt.WeightThres = 0.5;
opt.Max = 1000;
% SOS parameter
opt.mOrd = 2;
opt.nVar = 5;
opt.sosThres = 3;

time.trainTime = 0;
time.testTime = 0;
time.runTime = 0;

[data, gtE] = parseDataset(opt);

% data = preProcessing(data, opt);

% [results] = actionLoc_concurrent(data, gtE, opt);
% [results] = actionLoc_concurrent_reweight(data, gtE, opt);
[result] = actionLoc_concurrent_subspaceVel2(data, gtE, opt);

kFold = 5;
nSequence = 40;
index = (1:nSequence);
indicator = logical(kron(eye(kFold, kFold),ones(1, nSequence/kFold)));
te_split = zeros(kFold, nSequence / kFold);
tr_split = zeros(kFold, nSequence - nSequence / kFold);
for i = 1:kFold
    te_split(i, :) = index(indicator(i, :));
    tr_split(i, :) = index(~indicator(i, :));
end

tStart = tic;
fprintf('Start ...\n');
res = [];
for i = 1:kFold
    fprintf('Processing Fold %d ...\n', i);
    opt.teIndex = te_split(i, :);
    opt.trIndex = tr_split(i, :);
    [results, T] = actionLoc(data, gtE, opt);
    res = [res; results];
    time.trainTime = time.trainTime + T.trainTime;
    time.testTime = time.testTime + T.testTime;
end
fprintf('finish!\n');
time.runTime = toc(tStart);

precision = zeros(length(res), 1);
recall = zeros(length(res), 1);
for i = 1:length(res)
    precision(i) = res{i}.Prec;
    recall(i) = res{i}.Rec;
end

mPrec = mean(precision);
mRec = mean(recall);
mPrec
mRec

if ~exist(fullfile('..', 'expData', 'res'), 'dir')
    mkdir(fullfile('..', 'expData', 'res'));
end
save ../expData/res/res.mat res mPrec mRec time;