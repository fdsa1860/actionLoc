function seg = getClusterSegment(seq, cLabel)
% get new segments according to cluster labels

d_cLabel = diff(cLabel);
ind = find(d_cLabel); % find indices of nonzero elements
index = [1; ind + 1]; % begining indices of segments

seg = cell(length(index), 1);
for i = 1:length(index)-1
    seg{i} = seq(:, index(i):index(i+1)-1);
end
seg{end} = seq(:, index(end):end);

end