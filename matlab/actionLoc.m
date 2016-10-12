function [results, time] = actionLoc(seqs, gtE, opt)
% the main action localization function
% training and testing

teInd = opt.teIndex;
trInd = opt.trIndex;

seqs_train = seqs(trInd);
seqs_test = seqs(teInd);
gtE_train = gtE(trInd);
gte_test = gtE(teInd);

% PCA
if opt.pca == true
    [U, s] = myPCA(seqs_train);
    cs = cumsum(s) / sum(s);
    nPCA = nnz(cs < opt.pcaThres) + 1;
    P = U(:,1:nPCA).';
    seqs_train = myPCA_apply(P, seqs_train);
end

% train
trainStart = tic;
Gm = actionLoc_train(seqs_train, gtE_train, opt);
trainTime = toc(trainStart);

% PCA
if opt.pca == true
    seqs_test = myPCA_apply(P, seqs_test);
end

% test
testStart = tic;
results = actionLoc_test(seqs_test, gte_test, Gm, opt);
testTime = toc(testStart);

time.trainTime = trainTime;
time.testTime = testTime;

end