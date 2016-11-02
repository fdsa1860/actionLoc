function segment = getNullClassSegment(len, gt)

s = ones(1, len);
for i = 1:length(gt)
    s(gt(i).segment(1):gt(i).segment(2)) = 0;
end

segment = index2interval(s);

end