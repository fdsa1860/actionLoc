function results = actionLoc_test(seqs_test, gte_test, Gm, opt)
% test

results = cell(length(seqs_test), 1);
for i = 1:length(seqs_test)
    fprintf('\tnow on %d/%d ...\n', i, length(seqs_test));

    currSeq = seqs_test{i};
    slideSeg = segmentSeqence(currSeq, opt);
    
    % cluster and re-sesgment
    [cLabel] = greedyClustering2(slideSeg, currSeq, opt);
%     [cLabel, W] = clustering(slideSeg, opt);
    seg = getClusterSegment(currSeq, cLabel);
    seg = mergeShortSegment(seg, opt);
    G_test = getGram_batch(seg, opt);

    D = HHdist(Gm, G_test, opt);
    [val, ind] = min(D);
    len = cellfun(@(x)size(x,2), seg);
    label = [];
    for j = 1:length(seg)
        label = [label, ind(j) * ones(1, len(j))];
    end
    
    % if 1st derivative is used, add one more label in front
    if opt.diff == true
        label = [label(1), label];
    end
    
%     label{i} = [ind(1)*ones(1, winSize-1), ind];

    Result = funEvalDetection(gte_test{i}, label, opt.IoU_thr);
    Result.gtE = gte_test{i};
    Result.label = label;
    results{i} = Result;
end

end