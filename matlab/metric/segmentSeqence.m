function seg = segmentSeqence(seq, winSize, stepSize)

[d, n] = size(seq);
nSeg = ceil((n - winSize) / stepSize) + 1;
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

