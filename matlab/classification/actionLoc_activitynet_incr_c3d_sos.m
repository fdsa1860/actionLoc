function [res] = actionLoc_activitynet_incr_c3d_sos(opt)

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

if ~exist(fullfile('..', 'expData', 'activityList.mat'), 'file')
    [activityList, vidList, cVidList, trInd, valInd, teInd] = ...
        getActivityList(info, label);
    save(fullfile('..', 'expData', 'activityList.mat'), ...
        'activityList', 'vidList', 'cVidList', 'trInd', 'valInd', 'teInd');
else
    load(fullfile('..', 'expData', 'activityList.mat'));
end

lbl = label.database;

% train incrementally

if ~exist(fullfile('..', 'expData', 'c3dsos_model2.mat'), 'file')
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
    
    if ~exist(fullfile('..', 'expData', 'train_data.mat'), 'file')
        nTrain = length(trainLabelList);
        X_train = zeros(500, nTrain);
        y_train = cell(1, nTrain);
        for i = 1:nTrain
            fprintf('Processing instance %d/%d ... \n', i, nTrain);
            dataName = sprintf('/%s/c3d_features', vidTrainList{videoIndex(i)});
            currSeq = h5read(fullfile(dataPath, fileName), dataName);
            nFeat = size(currSeq, 2);
            anno = lbl.(cVidTrainList{videoIndex(i)}).annotations{annoIndex(i)};
            duration = lbl.(cVidTrainList{videoIndex(i)}).duration;
            fps = ceil( (nFeat + 1) * 8 / duration );
            featInd = round(anno.segment * fps / 8);
            featInd(1) = max(1, min(nFeat, featInd(1)));
            featInd(2) = max(1, min(nFeat, featInd(2)));
            X_train(:, i) = mean(currSeq(:,featInd(1):featInd(2)), 2);
            y_train{i} = anno.label;
        end
        save(fullfile('..', 'expData', 'train_data.mat'), 'X_train', 'y_train');
    else
        load(fullfile('..', 'expData', 'train_data.mat'), 'X_train', 'y_train');
    end
    
    M_inv = cell(length(activityList), 1);
    X_mean = zeros(opt.nVar, length(activityList));
    r_mean = zeros(length(activityList), 1);
    for i = 1:length(activityList)
        X_uni = X_train(:, strcmp(y_train, activityList{i}));
        X_seg = X_uni(1:opt.nVar,:);
        X_mean(:,i) = mean(X_seg, 2);
        Xm = bsxfun(@minus, X_seg, X_mean(:,i));
        r_mean(i) = mean(sqrt(sum(Xm.^2)));
        Xr = Xm / r_mean(i);
        M_inv{i} = getInverseMomentMat(Xr', opt.mOrd);
    end
    
    trainTime = toc(trainTimeStart);
    save(fullfile('..', 'expData', 'c3dsos_model.mat'), 'M_inv', 'X_mean', 'r_mean');
else
    load(fullfile('..', 'expData', 'c3dsos_model.mat'));
end

% validation
validationTimeStart = tic;
nVal = nnz(valInd);
vidValidationList = vidList(valInd);
cVidValidationList = cVidList(valInd);
[basis,~] = momentPowers(0, opt.nVar, opt.mOrd);
total_hitCount = 0;
total_gtCount = 0;
total_dtCount = 0;
for i = 1:nVal
    % for i = 1:10
    fprintf('Test on Validation data %d/%d ... \t', i, nVal);
    gtAnnotations = lbl.(cVidValidationList{i}).annotations;
    %     y_val{i} = lbl.(cVidValidationList{i}).annotations{1}.label;
    dataName = sprintf('/%s/c3d_features', vidValidationList{i});
    currSeq = h5read(fullfile(dataPath, fileName), dataName);
    % estimate frames per second
    nFeat = size(currSeq, 2);
    duration = lbl.(cVidValidationList{i}).duration;
    fps = ceil( (nFeat + 1) * 8 / duration );
    
    X_test = zeros(500, length(gtAnnotations));
    intervel = zeros(length(gtAnnotations), 2);
    for j = 1:length(gtAnnotations)
        intervel(j, :) = gtAnnotations{j}.segment;
        featInd = round(intervel(j, :) * fps / 8);
        featInd(1) = max(1, min(nFeat, featInd(1)));
        featInd(2) = max(1, min(nFeat, featInd(2)));
        X_test(:, j) = mean(currSeq(:, featInd(1):featInd(2)), 2);
    end
    
    y_pred = cell(size(X_test, 2), 1);
    for j = 1:size(X_test, 2)
        d = zeros(length(M_inv), 1);
        x = X_test(1:opt.nVar, j);
        for k = 1:length(M_inv)
            xm = x - X_mean(:,k);
            xr = xm / r_mean(k);
            v = prod( bsxfun( @power, xr', basis), 2);
            d(k) = v' * M_inv{k} * v;
        end
        [~,ind] = min(d);
        y_pred{j} = activityList{ind};
    end
    
%     y_pred = svmpredict(zeros(length(gtAnnotations), 1), X_test', model, '-q');
    dtAnnotations = struct('label',{},'score',{},'segment',{});
    dtAnnotations(1:length(y_pred)) = struct('label',[],'score',[],'segment',[]);
    for j = 1:length(y_pred)
        dtAnnotations(j).label = y_pred{j};
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
validationTime = toc(validationTimeStart);
valObj.version = 'VERSION 1.3';
valObj.results = results;
valObj.external_data.used = false;
valObj.external_data.details = '';
savejson('',valObj,fullfile('..', 'expData','detection_results_c3d_sos.json'));
% a = loadjson(fullfile('..', 'expData','detection_results_c3dsvm.json'));

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