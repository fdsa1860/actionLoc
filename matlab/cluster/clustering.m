function [cLabel, W] = clustering(seg, opt)

if nargin < 2
    nCluster = 40;
    kNN = ceil(0.1 * length(seg));
    scale_sig = 1;
    winSize = 30;
else
    nCluster = opt.nCluster;
    kNN = ceil(opt.kNN_ratio * length(seg));
    scale_sig = opt.scale_sig;
    winSize = opt.winSize;
end

G = getGram_batch(seg, opt);
% tic
D = HHdist(G, [], opt);
% toc
% save D_seq1_win60_step1 D;
% load D_seq1_win30_step1;
[cLabel, W] = ncutD(D, nCluster, kNN, scale_sig);
cLabel = [cLabel(1)*ones(winSize-1, 1); cLabel];

end