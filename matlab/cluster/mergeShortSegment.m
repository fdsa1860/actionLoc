function seg2 = mergeShortSegment(seg, opt)
% merge short segments

seg2 = cell(size(seg));
count = 1;
for i = 1:length(seg);
    seg2{count} = [seg2{count}, seg{i}];
    if size(seg2{count}, 2) >= opt.minLength
        count = count + 1;
    end
end

if count <= length(seg2)
    if ~isempty(seg2{count})
        seg2{count-1} = [seg2{count-1}, seg2{count}];
    end
    seg2(count:end) = [];
end

end