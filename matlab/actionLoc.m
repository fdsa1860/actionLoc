function label = actionLoc(data, gt, opt)

teInd = opt.teIndex;
trInd = opt.trIndex;

% get data segments for training
nAction = 36;
nTrain = length(trInd);
X = cell(nTrain, nAction);
for i = 1:nTrain
    dataCurr = data{trInd(i)};
    gtCurr = gt{trInd(i)};
    for j = 1:nAction
        segInd = find(gtCurr == j);
        if isempty(segInd)
            X{i, j} = [];
        elseif invalidSeg(segInd) % if there are more than one segment
            idx = find(diff(segInd,2), 1); % find the first segment
            X{i, j} = dataCurr(:, segInd(1:idx+1));
        else
            X{i, j} = dataCurr(:, segInd);
        end
    end
end
% get Gram matrices for each segment
opt.metric = 'JBLD';
opt.H_structure = 'HHt';
opt.H_rows = 5;
opt.sigma = 1e-4;
opt.pca = false;
% opt.pcaThres = 0.9;
G = getGram_batch(X(:), opt);
G = reshape(G, nTrain, nAction);
% get means Gram matrices from each class
Gm = cell(nAction, 1);
for i = 1:nAction
    Gm{i} = gramMean(G(:, i), opt);
end

% test
winSize = 30;
stepSize = 1;
label = cell(length(teInd), 1);
for i = 1:length(teInd)
    dataCurr = data{teInd(i)};
    seg = segmentSeqence(dataCurr, winSize, stepSize);
    G_test = getGram_batch(seg, opt);
    D = HHdist(Gm, G_test, opt);
    [val, ind] = min(D);
    label{i} = [ind(1)*ones(1, winSize-1), ind];
end

end