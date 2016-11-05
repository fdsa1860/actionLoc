function HiIndex = getHighWeightIndex(W, thres)

nAction = size(W, 1);
HiIndex = cell(1, nAction);
for i = 1:nAction
    w = W(i, :);
    [val, ind] = sort(-w);
    val = -val;
    cs = cumsum(val);
    nSel = nnz(cs + 1e-6 < thres) + 1;
    HiIndex{i} = ind(1:nSel);
end

end