function hitCount = compareAnnotations(gtAnnotations, dtAnnotations, opt)
% compare ground truth annotations with detected annotations

hitCount = 0;
for i = 1:length(gtAnnotations)
    currLabel = gtAnnotations{i}.label;
    for j = 1:length(dtAnnotations)
        if ~strcmp(dtAnnotations(j).label, currLabel)
            continue;
        end
        gtInt = gtAnnotations{i}.segment;
        dtInt = dtAnnotations(j).segment;
        if IoU(gtInt, dtInt) > opt.hitThres
            hitCount = hitCount + 1;
            break;
        end
    end
end

end

function ratio = IoU(gtInt, dtInt)

U = max(gtInt(2), dtInt(2)) - min(gtInt(1), dtInt(1));
I = max(0, min(gtInt(2), dtInt(2)) - max(gtInt(1), dtInt(1)));
ratio = I / (U + eps);

end