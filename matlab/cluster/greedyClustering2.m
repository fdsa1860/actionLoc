function [gcLabel] = greedyClustering2(slideSeg, currSeq, opt)
% greedily comparing distance between neighbor segments,
% if there is a jump, we say there is a new segment starting
% use an anchor point

if nargin < 2
    nCluster = 40;
    kNN_ratio = 0.1;
    scale_sig = 1;
    winSize = 30;
else
    nCluster = opt.nCluster;
    kNN_ratio = opt.kNN_ratio;
    scale_sig = opt.scale_sig;
    winSize = opt.winSize;
end

G = getGram_batch(slideSeg, opt);

n = length(G);
gLabel = zeros(n, 1);
index = 1;
count = 1;
for i = 1:n
    d = HHdist(G(index), G(i), opt);
    if d > opt.greedyThr
        count = count + 1;
        index = i;
    end
    gLabel(i) = count;
end

% gLabel = [gLabel(1)*ones(winSize, 1); gLabel];

slideSeg = getClusterSlideSegment(currSeq, gLabel, opt);
G = getGram_batch(slideSeg, opt);
D = HHdist(G, [], opt);

kNN = ceil(kNN_ratio * length(slideSeg));
[cLabel, W] = ncutD(D, nCluster, kNN, scale_sig);
gcLabel = zeros(size(currSeq, 2), 1);
gcLabel(1:opt.winSize-1) = cLabel(1);
count = opt.winSize;
for i = 1:length(slideSeg)
    len = size(slideSeg{i}, 2) - opt.winSize + 1;
    gcLabel(count:count+len-1) = cLabel(i);
    count = count + len;
end

end