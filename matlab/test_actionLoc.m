% test action localization

dbstop if error

clear; close all; clc;

addpath(genpath('../3rdParty'));
addpath(genpath('.'));

opt.dataset = 'MAD';
opt.dataPath = fullfile('~','research','data','MAD','data_code','Sub_all');

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

aP = zeros(kFold, 1);
aR = zeros(kFold, 1);
res = [];
for i = 1:kFold
opt.teIndex = te_split(i, :);
opt.trIndex = tr_split(i, :);
label = actionLoc(data, gt, opt);

gtE_test = gtE(opt.teIndex);
[aP(i), aR(i), results] = evalResult(gtE_test, label);
res = [res; results];
end

mPrec = mean(aP);
mRec = mean(aR);
mPrec
mRec

if ~exist(fullfile('..', 'expData', 'res'), 'dir')
    mkdir(fullfile('..', 'expData', 'res'));
end
save ../expData/res/res.mat mPrec mRec aP aR res;