function seq_segment = getNullClassSeq(seq, gt)

L = size(seq, 2);
segment = getNullClassSegment(L, gt);
nSeg = size(segment, 1);
seq_segment = cell(1, nSeg);
for i = 1:nSeg
    seq_segment{i} = seq(:, segment(i, 1):segment(i, 2));
end

end