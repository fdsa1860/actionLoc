function [accuracy, y_pred, y_val] = actionLoc_activitynet(data, gt, tr_te_split, opt)

trInd = tr_te_split.trInd;
valInd = tr_te_split.valInd;
teInd = tr_te_split.teInd;

% train
X_train = data(trInd);
G_train = getGram_batch(X_train, opt);
y_train = gt(trInd);
className = unique(y_train);
% get means Gram matrices from each class
tic
Gm = cell(length(className), 1);
for i = 1:length(className)
    index = strcmp(y_train, className{i});
    Gm{i} = gramMean(G_train(index), opt);
end
toc

% validation
X_val = data(valInd);
G_val = getGram_batch(X_val, opt);
y_val = gt(valInd);
D = HHdist(Gm, G_val, opt);
[~, ind] = min(D);
y_pred = className(ind);

accuracy = nnz(strcmp(y_val, y_pred)) / length(y_val);

save(fullfile('..', 'expData', 'res_activitynet.mat'), accuracy, y_pred, ...
    y_val, D);

end