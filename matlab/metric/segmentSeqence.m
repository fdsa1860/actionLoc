function seg = segmentSeqence(seq, opt)

winSize = opt.winSize;
stepSize = opt.stepSize;

[d, n] = size(seq);
nSeg = max(1, ceil((n - winSize) / stepSize) + 1);
seg = cell(1, nSeg);
count = 1;
tStart = 1;
tEnd = min([tStart + winSize - 1, n]);
while tEnd < n
    seg{count} = seq(:, tStart:tEnd);
    count = count + 1;
    tStart = tStart + stepSize;
    tEnd = min([tStart + winSize - 1, n]);
end
seg{count} = seq(:, tStart:tEnd);

if nSeg ~= length(seg)
    error('Length of segments is not equal to the computed.\n');
end

end

