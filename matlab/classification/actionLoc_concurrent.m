function [results, T] = actionLoc_concurrent(data, gtE, opt)

te_ind = 1:2:61;
tr_ind = 2:2:60;
actionList = {'drink', 'make_a_call', 'turn_on_monitor', ...
    'type_on_keyboard', 'fetch_water', 'pour_water', 'press_button', ...
    'pick_up_trash', 'throw_trash', 'bend_down', 'sit', 'stand'};

load ww;

seqs_train = data(tr_ind);
gte_train = gtE(tr_ind);
maxLen = 100;
nullClassLabel = length(actionList) + 1;

nAction = length(actionList);
data_class = cell(nAction, 1);
for ai = 1:nAction
    curr_data_class = cell(1, maxLen);
    count = 1;
    for i = 1:length(seqs_train)
        dat = seqs_train{i};
        g = gte_train{i};
        for j = 1:length(g)
            if strcmp(g(j).label, actionList{ai})
                curr_data_class{count} = dat(:, g(j).segment(1):g(j).segment(2));
%                 curr_data_class{count} = bsxfun(@times, kron(ww, [1 1 1]'), curr_data_class{count});
                count = count + 1;
            end
        end
%         if strcmp(actionList{ai}, 'null')
%             curr_data_class = getNullClassSeq(dat, g);
%             count = count + length(curr_data_class);
%         end
    end
    curr_data_class(count:end) = [];
    data_class{ai} = curr_data_class;
end

% find importance weight
% w = findJointWeight(data_class, opt);

G = cell(nAction, 1);
for ai = 1:nAction
    G{ai} = getGram_batch(data_class{ai}, opt);
end

Gm = cell(length(G), 1);
for i = 1:length(G)
    Gm{i} = gramMean(G{i}, opt);
end

% determine threshold
mean_intra = zeros(length(Gm), 1);
mean_inter = zeros(length(Gm), 1);
for i = 1:length(Gm)
    count = 0;
    sum_inter = 0;
    for j = 1:length(G)
        if i == j
            d_intra = HHdist(Gm(i), G{j}, opt);
        else
            d_inter = HHdist(Gm(i), G{j}, opt);
            sum_inter = sum_inter+ sum(d_inter);
            count = count + length(d_inter);
        end
    end
    mean_intra(i) = mean(d_intra);
    mean_inter(i) = sum_inter / count;
end
d_thres = (mean_intra + mean_inter) / 2;

result.hitCount = zeros(1, length(actionList));
result.gtCount = zeros(1, length(actionList));
result.dtCount = zeros(1, length(actionList));
seqs_test = data(te_ind);
gte_test = gtE(te_ind);
for i = 1:length(seqs_test)
    currSeq = seqs_test{i};
    
    slideSeg = segmentSeqence(currSeq, opt);
    
    % cluster and re-sesgment
    [cLabel] = greedyClustering2(slideSeg, currSeq, opt);
%     [cLabel, W] = clustering(slideSeg, opt);
    seg = getClusterSegment(currSeq, cLabel);
    seg = mergeShortSegment(seg, opt);
    G_test = getGram_batch(seg, opt);
    
%     seg = segmentSeqence(currSeq, opt);
%     G_test = getGram_batch(seg, opt);
%     dtLabel = [ind(1)*ones(1, opt.winSize-1), ind];
    
    D = HHdist(Gm, G_test, opt);
    [val, ind] = min(D);
    
    len = cellfun(@(x)size(x,2), seg);
    dtLabel = zeros(length(actionList), size(currSeq, 2));
    for k = 1:length(actionList)
        label = ind;
        label((D(k, :) - val) ./ val < 0.1 & D(k, :) < d_thres(k)) = k;
        label(label ~= k) = nullClassLabel;
        dtLabel(k, :) = labelConv([label', len], 'slab2flab');
    end
    
    gtLabel =  nullClassLabel * ones(length(actionList), size(currSeq, 2));
    currGt = gte_test{i};
    for k = 1:length(actionList)
        for j = 1:length(currGt)
            if strcmp(currGt(j).label, actionList{k})
                gtLabel(k, currGt(j).segment(1):currGt(j).segment(2)) = k;
            end
        end
    end
    
%     gtLabelE = labelConv(gtLabel,'flab2slab');
%     Result = funEvalDetection2(gtLabelE, dtLabel, opt.hitThres);
    displayLoc(gtLabel, dtLabel);
    
    dtAnnotation = struct('label', {}, 'segment', {});
    cnt = 1;
    for k = 1:length(actionList)
        dt_sLabel = fLabel2sLabel(dtLabel(k, :));
        for j = 1:size(dt_sLabel, 1)
            if dt_sLabel(j, 1) == nullClassLabel
                continue;
            end
            dtAnnotation(cnt).label = actionList{dt_sLabel(j, 1)};
            dtAnnotation(cnt).segment = dt_sLabel(j, 2:3);
            cnt = cnt + 1;
        end
    end
    
%     hitCount = compareAnnotations(currGt, dtAnnotation, opt.hitThres);
    res = eval_ConcurrentAction(currGt, dtAnnotation, actionList);
    
    result.hitCount = result.hitCount + res.hitCount;
    result.gtCount = result.gtCount + res.gtCount;
    result.dtCount = result.dtCount + res.dtCount;
end
result.recall = result.hitCount ./ (result.gtCount + eps);
result.precision = result.hitCount ./ (result.dtCount + eps);
55
end