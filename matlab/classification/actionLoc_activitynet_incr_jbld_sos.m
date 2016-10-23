function [res] = actionLoc_activitynet_incr_jbld_sos(opt)

runTimeStart = tic;

dataPath = opt.dataPath;
fileName = 'sub_activitynet_v1-3.c3d.hdf5';
info = h5info(fullfile(dataPath, fileName));

if ~exist(fullfile('..', 'expData'), 'dir')
    mkdir(fullfile('..', 'expData'));
end

if ~exist(fullfile('..', 'expData', 'activityNet_label.mat'), 'file')
    label = loadjson(fullfile(dataPath, 'activity_net.v1-3.min.json'));
    save(fullfile('..', 'expData', 'activityNet_label.mat'), 'label');
else
    load(fullfile('..', 'expData', 'activityNet_label.mat'));
end

[activityList, vidList, cVidList, trInd, valInd, teInd] = ... 
    getActivityList(info, label);

lbl = label.database;

% train incrementally
trainTime = -1;
if ~exist(fullfile('..', 'expData', 'Gm.mat'), 'file')
    trainTimeStart = tic;
    nTrain = nnz(trInd);
    vidTrainList = vidList(trInd);
    cVidTrainList = cVidList(trInd);
    trainLabelList = cell(2*nTrain, 1);
    videoIndex = zeros(2*nTrain, 1);
    annoIndex = zeros(2*nTrain, 1);
    count = 1;
    for i = 1:nTrain
        currAnnotations = lbl.(cVidTrainList{i}).annotations;
        for j = 1:length(currAnnotations)
            trainLabelList{count} = currAnnotations{j}.label;
            videoIndex(count) = i;
            annoIndex(count) = j;
            count = count + 1;
        end
    end
    trainLabelList(count:end) = [];
    videoIndex(count:end) = [];
    annoIndex(count:end) = [];
    
    Gm = cell(length(activityList), 1);
    distGm = cell(length(activityList), 1);
    for j = 1:length(activityList)
        fprintf('Training activity %d/%d ... \n', j, length(activityList));
%             index1 = find(strcmp(trainLabelList, activityList{143}));
%             index2 = find(strcmp(trainLabelList, activityList{155}));
%             index = [index1; index2];
        index = find(strcmp(trainLabelList, activityList{j}));
        G_pool = cell(length(index), 1);
        len = zeros(length(index), 1);
        for i = 1:length(index)
            dataName = sprintf('/%s/c3d_features', vidTrainList{videoIndex(index(i))});
            currSeq = h5read(fullfile(dataPath, fileName), dataName);
            nFeat = size(currSeq, 2);
            anno = lbl.(cVidTrainList{videoIndex(index(i))}).annotations{annoIndex(index(i))};
            duration = lbl.(cVidTrainList{videoIndex(index(i))}).duration;
            fps = ceil( (nFeat + 1) * 8 / duration );
            featInd = round(anno.segment * fps / 8);
            featInd(1) = max(1, min(nFeat, featInd(1)));
            featInd(2) = max(1, min(nFeat, featInd(2)));
            len(i) = featInd(2) - featInd(1) + 1;
            G_pool{i} = getGram(currSeq(:,featInd(1):featInd(2)), opt);
        end
        G_pool(len < opt.minLength) = [];
        Gm{j} = gramMean(G_pool, opt);
        distGm{j} = HHdist(G_pool, Gm(j), opt);
    end
    
    trainTime = toc(trainTimeStart);
    save(fullfile('..', 'expData', 'Gm.mat'), 'Gm', 'distGm');
else
    load(fullfile('..', 'expData', 'Gm.mat'));
end

% scale = cellfun(@mean, distGm);
M_inv = cell(length(distGm), 1);
for i = 1:length(distGm)
%     ker = exp(-distGm{i}/scale(i)/10);
    M_inv{i} = getInverseMomentMat(distGm{i}, opt.mOrd);
end

% % test on training data
% total_hitCount = 0;
% total_gtCount = 0;
% total_dtCount = 0;
% nTrain = nnz(trInd);
% vidTrainList = vidList(trInd);
% cVidTrainList = cVidList(trInd);
% for i = 1:nTrain
% % for i = 97
%     fprintf('Test on training data %d/%d ... \t', i, nTrain);
%     gtAnnotations = lbl.(cVidTrainList{i}).annotations;
%     dataName = sprintf('/%s/c3d_features', vidTrainList{i});
%     currSeq = h5read(fullfile(dataPath, fileName), dataName);
%     % estimate frames per second
%     nFeat = size(currSeq, 2);
%     duration = lbl.(cVidTrainList{i}).duration;
%     fps = ceil( (nFeat + 1) * 8 / duration );
% 
%     seg = cell(length(gtAnnotations), 1);
%     intervel = zeros(length(gtAnnotations), 2);
%     for j = 1:length(gtAnnotations)
%         intervel(j, :) = gtAnnotations{j}.segment;
%         featInd = round(intervel(j, :) * fps / 8);
%         featInd(1) = max(1, min(nFeat, featInd(1)));
%         featInd(2) = max(1, min(nFeat, featInd(2)));
%         seg{j} = currSeq(:, featInd(1):featInd(2));
%     end
%     
%     G = getGram_batch(seg, opt);
%     D = HHdist(Gm, G, opt);
%     [value, ind] = min(D);
%     
%     [basis,~] = momentPowers(0, 1, opt.mOrd);
%     D2 = zeros(size(D));
%     for j = 1:size(D2, 2)
% %         ker = exp(-D(:, j)./scale/10);
%         for k = 1:size(D2, 1)
%             v = prod( bsxfun( @power, D(k, j), basis), 2);
%             D2(k, j) = v' * M_inv{k} * v;
%         end
%     end
%     [value, ind] = min(D2);
%     
% %     K = exp(bsxfun(@rdivide, -D, scale*10));
% %     [value, ind] = min(K);
% 
%     dtAnnotations = struct('label',{},'score',{},'segment',{});
%     dtAnnotations(1:length(seg)) = struct('label',[],'score',[],'segment',[]);
%     for j = 1:length(seg)
%         dtAnnotations(j).label = activityList{ind(j)};
%         dtAnnotations(j).score = 1;
%         dtAnnotations(j).segment = intervel(j, :);
%     end
%     hitCount = compareAnnotations(gtAnnotations, dtAnnotations, opt);
%     gtCount = length(gtAnnotations);
%     dtCount = length(dtAnnotations);
%     total_hitCount = total_hitCount + hitCount;
%     total_gtCount = total_gtCount + gtCount;
%     total_dtCount = total_dtCount + dtCount;
%     fprintf('hit / gt = %d/%d,\t hit / dt = %d/%d\n', hitCount, gtCount, hitCount, dtCount);
% end

% validation
validationTimeStart = tic;
nVal = nnz(valInd);
vidValidationList = vidList(valInd);
cVidValidationList = cVidList(valInd);
total_hitCount = 0;
total_gtCount = 0;
total_dtCount = 0;

D_143 = zeros(length(activityList), 300);
count = 1;
for i = 1:nVal
% for i = 97
    fprintf('Test on Validation data %d/%d ... \t', i, nVal);
    gtAnnotations = lbl.(cVidValidationList{i}).annotations;
    if ~any(strcmp(activityList{143}, gtAnnotations{1}.label))
        continue;
    end
%     y_val{i} = lbl.(cVidValidationList{i}).annotations{1}.label;
    dataName = sprintf('/%s/c3d_features', vidValidationList{i});
    currSeq = h5read(fullfile(dataPath, fileName), dataName);
    % estimate frames per second
    nFeat = size(currSeq, 2);
    duration = lbl.(cVidValidationList{i}).duration;
    fps = ceil( (nFeat + 1) * 8 / duration );
    
%     slideSeg = segmentSeqence(currSeq, opt);
%     % cluster and re-sesgment
%     [cLabel] = greedyClustering2(slideSeg, currSeq, opt);
% %     [cLabel, W] = clustering(slideSeg, opt);
%     seg = getClusterSegment(currSeq, cLabel);
%     seg = mergeShortSegment(seg, opt);
%     len = cell2mat(cellfun(@(x)size(x, 2), seg, 'UniformOutput', false));
%     cumLen = cumsum(len);
%     t = cumLen * 8 / fps;
%     intervel = [ [0; t(1:end-1)], t];

    seg = cell(length(gtAnnotations), 1);
    intervel = zeros(length(gtAnnotations), 2);
    for j = 1:length(gtAnnotations)
        intervel(j, :) = gtAnnotations{j}.segment;
        featInd = round(intervel(j, :) * fps / 8);
        featInd(1) = max(1, min(nFeat, featInd(1)));
        featInd(2) = max(1, min(nFeat, featInd(2)));
        seg{j} = currSeq(:, featInd(1):featInd(2));
    end
    
    G = getGram_batch(seg, opt);
    D = HHdist(Gm, G, opt);
    [value, ind] = min(D);
    D_143(:, count:count+size(D,2)-1) = D;
    count = count + size(D,2);
    
    [basis,~] = momentPowers(0, 1, opt.mOrd);
    D2 = zeros(size(D));
    for j = 1:size(D2, 2)
%         ker = exp(-D(:, j)./scale/10);
        for k = 1:size(D2, 1)
            v = prod( bsxfun( @power, D(k, j), basis), 2);
            D2(k, j) = v' * M_inv{k} * v;
        end
    end
    [value, ind] = min(D2);
    
%     K = exp(bsxfun(@rdivide, -D, scale*10));
%     [value, ind] = min(K);

    dtAnnotations = struct('label',{},'score',{},'segment',{});
    dtAnnotations(1:length(seg)) = struct('label',[],'score',[],'segment',[]);
    for j = 1:length(seg)
        dtAnnotations(j).label = activityList{ind(j)};
        dtAnnotations(j).score = 1;
        dtAnnotations(j).segment = intervel(j, :);
    end
    if length(dtAnnotations) == 1
        results.(cVidValidationList{i}) = {dtAnnotations};
    else
        results.(cVidValidationList{i}) = dtAnnotations;
    end
    hitCount = compareAnnotations(gtAnnotations, dtAnnotations, opt);
    gtCount = length(gtAnnotations);
    dtCount = length(dtAnnotations);
    total_hitCount = total_hitCount + hitCount;
    total_gtCount = total_gtCount + gtCount;
    total_dtCount = total_dtCount + dtCount;
    fprintf('hit / gt = %d/%d,\t hit / dt = %d/%d\n', hitCount, gtCount, hitCount, dtCount);
end
D_143(:,count:end) = [];
save D_143 D_143;
validationTime = toc(validationTimeStart);
valObj.version = 'VERSION 1.3';
valObj.results = results;
valObj.external_data.used = false;
valObj.external_data.details = '';
savejson('',valObj,fullfile('..', 'expData','detection_results_c3d_JBLD.json'));

recall = total_hitCount / total_gtCount;
precision = total_hitCount / total_dtCount;

runTime = toc(runTimeStart);

res.recall = recall;
res.precision = precision;
res.total_hitCount = total_hitCount;
res.total_gtCount = total_gtCount;
res.total_dtCount = total_dtCount;
res.trainTime = trainTime;
res.validationTime = validationTime;
res.runTime = runTime;

save(fullfile('..', 'expData','res', 'activitynet', 'res.mat'), 'res');

end