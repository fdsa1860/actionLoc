function [result] = actionLoc_concurrent_reweight(seqs, gtE, opt)

te_ind = 1:2:61;
tr_ind = 2:2:60;
actionList = {'drink', 'make_a_call', 'turn_on_monitor', ...
    'type_on_keyboard', 'fetch_water', 'pour_water', 'press_button', ...
    'pick_up_trash', 'throw_trash', 'bend_down', 'sit', 'stand'};

load ww;

seqs_train = seqs(tr_ind);
gte_train = gtE(tr_ind);
maxLen = 500;
nAction = length(actionList);
nullClassLabel = length(actionList) + 1;

X_train = cell(1, maxLen);
y_train = zeros(1, maxLen);
count = 1;
for i = 1:length(seqs_train)
    dat = seqs_train{i};
    g = gte_train{i};
    for j = 1:length(g)
        X_train{count} = dat(:, g(j).segment(1):g(j).segment(2));
        %                 data{count} = bsxfun(@times, kron(ww, [1 1 1]'), curr_data_class{count});
        y_train(count) = find(strcmp(g(j).label, actionList));
        count = count + 1;
    end
end
X_train(count:end) = [];
y_train(count:end) = [];
[y_train, sortInd] = sort(y_train);
X_train = X_train(sortInd);

% find importance weight
if exist(fullfile('..', 'expData', 'WeightMatrix.mat'), 'file')
    load(fullfile('..', 'expData', 'WeightMatrix.mat'));
else
    % w = findJointWeight(data_class, opt);
    W = findJointWeight2(X_train, y_train, opt);
    save(fullfile('..', 'expData', 'WeightMatrix.mat'), 'W');
end
HiIndex = getHighWeightIndex(W, opt.WeightThres);
HiIndex{2} = [10 11 12];
HiIndex{3} = [6 7 8];
HiIndex{5} = [2 7 8 10 11];
HiIndex{6} = [8 12];
HiIndex{9} = [7 8 11 12];
HiIndex{10} = [1 2 3 4];

G = cell(nAction, 1);
for i = 1:length(G)
    X_tmp = X_train(y_train==i);
    X_sel = selectJoint(X_tmp, HiIndex{i});
    G{i} = getGram_batch(X_sel, opt);
end

Gm = cell(length(G), 1);
for i = 1:length(G)
    Gm{i} = gramMean(G{i}, opt);
end

% determine threshold
MinvPos = cell(length(Gm), 1);
MinvNeg = cell(length(Gm), 1);
mean_intra = zeros(length(Gm), 1);
mean_inter = zeros(length(Gm), 1);
var_intra = zeros(length(Gm), 1);
var_inter = zeros(length(Gm), 1);
for i = 1:length(Gm)
    count = 1;
    d_inter = zeros(1, opt.Max);
    for j = 1:length(Gm)
        X_tmp = X_train(y_train==j);
        X_sel = selectJoint(X_tmp, HiIndex{i});
        G_temp = getGram_batch(X_sel, opt);
        if i == j
            d_intra = HHdist(Gm(i), G_temp, opt);
        else
            tmp = HHdist(Gm(i), G_temp, opt);
            d_inter(count:count+length(tmp)-1) = tmp;
            count = count + length(tmp);
        end
    end
    d_inter(count:end) = [];
    
    MinvPos{i} = getInverseMomentMat(d_intra', opt.mOrd);
    MinvNeg{i} = getInverseMomentMat(d_inter', opt.mOrd);
    mean_intra(i) = mean(d_intra);
    mean_inter(i) = mean(d_inter);
    var_intra(i) = var(d_intra);
    var_inter(i) = var(d_inter);

end
% d_thres = inf(length(Gm), 1);
d_thres = (mean_intra + mean_inter) / 2; 
d_thres(11) = 4;
d_thres(5) = 3;
d_thres(6) = 2.2;
d_thres(10) = 2.1;

[basis,~] = momentPowers(0, 1, opt.mOrd);
result.hitCount = zeros(1, length(actionList));
result.gtCount = zeros(1, length(actionList));
result.dtCount = zeros(1, length(actionList));
seqs_test = seqs(te_ind);
gte_test = gtE(te_ind);
for i = 1:length(seqs_test)
    currSeq = seqs_test{i};
    
    slideSeg = segmentSeqence(currSeq, opt);
    
    % cluster and re-sesgment
    rng(0);
    [cLabel] = greedyClustering2(slideSeg, currSeq, opt);
%     [cLabel, W] = clustering(slideSeg, opt);
    seg = getClusterSegment(currSeq, cLabel);
    seg = mergeShortSegment(seg, opt);
    X_test = seg;
    
%     seg = segmentSeqence(currSeq, opt);
%     G_test = getGram_batch(seg, opt);
%     dtLabel = [ind(1)*ones(1, opt.winSize-1), ind];
    
    len = cellfun(@(x)size(x,2), X_test);
    dtLabel = zeros(length(actionList), size(currSeq, 2));
    D = zeros(length(actionList), length(X_test));
    for k = 1:length(actionList)
        X_sel = selectJoint(X_test, HiIndex{k});
        G_test = getGram_batch(X_sel, opt);
        D(k, :) = HHdist(Gm(k), G_test, opt);
    end
%     [val, ind] = min(D);
    for k = 1:length(actionList)
%         pred = ind;
        pred = nullClassLabel * ones(1, size(D, 2));
%         pred((D(k, :) - val) ./ val < 0.1 & D(k, :) < d_thres(k)) = k;
        pred(D(k, :) < d_thres(k)) = k;
%         p_pos = exp(-(D(k,:)-mean_intra(k)).^2/(2*var_intra(k))) / sqrt(2*pi*var_intra(k));
%         p_neg = exp(-(D(k,:)-mean_inter(k)).^2/(2*var_inter(k))) / sqrt(2*pi*var_inter(k));
%         pred(p_pos > p_neg) = k;
%         for j = 1:size(D, 2)
%             v = prod( bsxfun( @power, D(k, j), basis), 2);
% %             if 1/(v'*(MinvPos{k})*v)-1/(v'*MinvNeg{k}*v) > 0
%             if v'*(MinvPos{k})*v < opt.mOrd + 1
%                 pred(j) = k;
%             end
%             
%         end
        pred(pred ~= k) = nullClassLabel;
        dtLabel(k, :) = labelConv([pred', len], 'slab2flab');
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
    figure('Units','normal','Position',[0 0.3 0.8, 0.1]);plot(labelConv([D(9,:)', len], 'slab2flab'));xlim([1 4511]);
    
    result.hitCount = result.hitCount + res.hitCount;
    result.gtCount = result.gtCount + res.gtCount;
    result.dtCount = result.dtCount + res.dtCount;
end
result.recall = result.hitCount ./ (result.gtCount + eps);
result.precision = result.hitCount ./ (result.dtCount + eps);
55
end