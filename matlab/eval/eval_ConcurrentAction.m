function res = eval_ConcurrentAction(gtAnnotations, dtAnnotations, actionList)
% compare ground truth annotations with detected annotations
% with protocol from Wei Ping et al, Concurrent Action Detection With
% Structured Prediction, ICCV 2013
% i.e. IoU > 60% or detected interval is totally covered by groundtruth

gtCount = getClasswiseCount(gtAnnotations, actionList);
dtCount = getClasswiseCount(dtAnnotations, actionList);

hitCount = zeros(1, length(actionList));
for i = 1:length(gtAnnotations)
    currLabel = gtAnnotations(i).label;
    for j = 1:length(dtAnnotations)
        if ~strcmp(dtAnnotations(j).label, currLabel)
            continue;
        end
        d_index = find(strcmp(dtAnnotations(j).label, actionList));
        gtInt = gtAnnotations(i).segment;
        dtInt = dtAnnotations(j).segment;
        if IoU(gtInt, dtInt) > 0.6
            hitCount(d_index) = hitCount(d_index) + 1;
            break;
        end
        if gtInt(1) <= dtInt(1) && gtInt(2) >= dtInt(2)
            hitCount(d_index) = hitCount(d_index) + 1;
            break;
        end
    end
end

recall = hitCount ./ (gtCount + eps);
precision = hitCount ./ (dtCount + eps);

res.gtCount = gtCount;
res.dtCount = dtCount;
res.hitCount = hitCount;
res.recall = recall;
res.precision = precision;

end
