function [result] = actionLoc_concurrent_subspaceVel2(seqs, gtE, opt)

[seqs]= Skeleton_Preprocessing(seqs); 

%Trajectory analysis
options.window_size=30; 
options.remove_mean=0; 
options.step=1; 
options.PC_No=3; 
options.n=60;
options.k=3; 
options.t=0.01; 

%compute features 
if ~exist('VelocityVector.mat', 'file')
    VelocityVector = VelocityVectorFeature(seqs, options);
else
    VelocityVector = importdata('VelocityVector.mat');
end

te_ind = 1:2:61;
tr_ind = 2:2:60;
actionList = {'drink', 'make_a_call', 'turn_on_monitor', ...
    'type_on_keyboard', 'fetch_water', 'pour_water', 'press_button', ...
    'pick_up_trash', 'throw_trash', 'bend_down', 'sit', 'stand'};


seqs_train = seqs(tr_ind);
vel_train = VelocityVector(tr_ind);
gte_train = gtE(tr_ind);
maxLen = 500;
nAction = length(actionList);
nullClassLabel = length(actionList) + 1;

data = cell(1, maxLen);
label = zeros(1, maxLen);
count = 1;
for i = 1:length(seqs_train)
    dat = seqs_train{i};
    vel = vel_train{i};
    g = gte_train{i};
    for j = 1:length(g)
%         data{count} = dat(:, g(j).segment(1):g(j).segment(2));
        label(count) = find(strcmp(g(j).label, actionList));
        if g(j).segment(2)-g(j).segment(1)+1 >= options.window_size
            data{count} = vel(:, g(j).segment(1):g(j).segment(2)-options.window_size);
        else
            if g(j).segment(1) + options.window_size - 1 < size(dat, 2)
                data{count} = vel(:, g(j).segment(1));
            elseif g(j).segment(2) - options.window_size > 1
                data{count} = vel(:, g(j).segment(2)-options.window_size);
            else
                error('the sequence is smaller than the windwo size\n');
            end
        end
        count = count + 1;
    end
end
data(count:end) = [];
label(count:end) = [];
[label, sortInd] = sort(label);
data = data(sortInd);

velHist = zeros((options.n-options.PC_No)*2, length(data)); 
for i = 1:length(data)
    Histogram = getHistogram(data{i});
    Histogram = Histogram / (norm(Histogram)+eps);
    velHist(:, i) = Histogram;
end

model = cell(1, nAction);
y = zeros(size(label));
for i = 1:nAction
    y(label==i) = 1;
    y(label~=i) = -1;
    model{i} = svmtrain(y', velHist', sprintf('-s 0 -t 0 -b 1 -w1 %f -w-1 %f -c 10',nnz(label~=i), nnz(label==i)));
end

result.hitCount = zeros(1, length(actionList));
result.gtCount = zeros(1, length(actionList));
result.dtCount = zeros(1, length(actionList));
seqs_test = seqs(te_ind);
vel_test = VelocityVector(te_ind);
gte_test = gtE(te_ind);
for i = 1:length(seqs_test)
    currSeq = seqs_test{i};
    currVel = vel_test{i};
    
    p = 30;
    X_test = zeros((options.n-options.PC_No)*2, size(currVel, 2)-p);
    for j = 1:size(currVel, 2)-p
        Histogram = getHistogram(currVel(:,j:j+p));
        Histogram = Histogram / (norm(Histogram)+eps);
        X_test(:, j) = Histogram;
    end
    
    W = zeros(length(actionList), size(currSeq, 2));
    for k = 1:length(model)
        [val, ~, prob] = svmpredict(zeros(size(X_test, 2), 1), X_test', model{k}, '-b 1');
        W(k,:) = [prob(:,1); prob(end,1)*ones(options.window_size + p, 1)].';
    end
    
    p_thres = 0.3 * ones(1, nAction);
    dtLabel = zeros(length(actionList), size(currSeq, 2));
    for k = 1:length(actionList)
        pred = nullClassLabel * ones(1, size(W, 2));
        pred(W(k, :) > p_thres(k)) = k;
        pred(pred ~= k) = nullClassLabel;
        dtLabel(k, :) = pred;
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