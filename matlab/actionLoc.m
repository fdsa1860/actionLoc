function results = actionLoc(seqs, gtE, opt)

if opt.diff == true
    seqs = cellfun( @(t) diff(t,[],2), seqs, 'UniformOutput', false);
end

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
Gm = actionLoc_train(seqs_train, gtE_train, opt);

% PCA
if opt.pca == true
    seqs_test = myPCA_apply(P, seqs_test);
end

% test
results = actionLoc_test(seqs_test, gte_test, Gm, opt);


end