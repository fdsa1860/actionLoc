% test action localization

dbstop if error;
warning off;

clear; close all; clc;

addpath(genpath('../3rdParty'));
addpath(genpath('.'));

% dataset parameters
opt.dataset = 'MAD';
opt.dataPath = fullfile('~','research','data','MAD','data_code','Sub_all');
opt.nAction = 36;
% train parameters
opt.metric = 'JBLD';
opt.H_structure = 'HHt';
opt.H_rows = 1;
opt.sigma = 1e-4;
opt.pca = false;
opt.pcaThres = 0.9;
opt.diff = false;
% test parameters
opt.IoU_thr = 0.5;
opt.winSize = 60;
opt.stepSize = 1;
opt.minLength = 40;
opt.nCluster = 40;
% opt.kNN = 400;
opt.kNN_ratio = 0.1;
opt.scale_sig = 1;
opt.greedyThr = 0.1;

[data, gt, gtE] = parseDataset(opt);

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
    results = actionLoc(data, gtE, opt);
    res = [res; results];
end
fprintf('finish!\n');
runTime = toc(tStart);

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
save ../expData/res/res.mat res mPrec mRec runTime;