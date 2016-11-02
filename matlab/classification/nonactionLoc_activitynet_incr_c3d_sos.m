function [res] = nonactionLoc_activitynet_incr_c3d_sos(opt)

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
trainTime = -1;
if ~exist(fullfile('..', 'expData', 'c3dsos_model.mat'), 'file')
    trainTimeStart = tic;
    M = MomentMat(opt.nVar, opt.mOrd);
    nTrain = nnz(trInd);
    vidTrainList = vidList(trInd);
    cVidTrainList = cVidList(trInd);
    for i = 1:nTrain
        fprintf('Processing instance %d/%d ... \n', i, nTrain);
        dataName = sprintf('/%s/c3d_features', vidTrainList{i});
        currSeq = h5read(fullfile(dataPath, fileName), dataName);
        nFeat = size(currSeq, 2);
        duration = lbl.(cVidTrainList{i}).duration;
        fps = ceil( (nFeat + 1) * 8 / duration );
        currAnnotations = lbl.(cVidTrainList{i}).annotations;
        tStart = 1;
        for j = 1:length(currAnnotations)
            anno = currAnnotations{j};
            featInd = round(anno.segment * fps / 8);
            featInd(1) = max(1, min(nFeat, featInd(1)));
            featInd(2) = max(1, min(nFeat, featInd(2)));
            tEnd = featInd(1);
            if tEnd > tStart
                M.add(currSeq(1:opt.nVar, tStart:tEnd));
            end
            if any(isnan(M.vec))
                keyboard;
            end
            tStart = featInd(2);
        end
        if tEnd > tStart
        M.add(currSeq(1:opt.nVar, tStart:end));
        end
    end
    
    M_inv = M.getMatInv;
    basis = M.getBasis;
    
    trainTime = toc(trainTimeStart);
    save(fullfile('..', 'expData', 'c3dsos_model.mat'), 'M_inv', 'basis');
else
    load(fullfile('..', 'expData', 'c3dsos_model.mat'));
end

% validation
validationTimeStart = tic;
nVal = nnz(valInd);
vidValidationList = vidList(valInd);
cVidValidationList = cVidList(valInd);
% [basis,~] = momentPowers(0, opt.nVar, opt.mOrd);
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
    X_val = currSeq(1:opt.nVar,:);
    d = zeros(size(X_val, 2), 1);
    for j = 1:size(X_val, 2)
        x = X_val(:, j);
        v = prod( bsxfun( @power, x', basis), 2);
        d(j) = v' * M_inv * v;
    end
    inlier = (d > opt.sosThres);
    interval = index2interval(inlier);
    t = interval * 8 / fps;
    
    %     y_pred = svmpredict(zeros(length(gtAnnotations), 1), X_test', model, '-q');
    dtAnnotations = struct('label',{},'score',{},'segment',{});
    dtAnnotations(1:size(t, 1)) = struct('label',[],'score',[],'segment',[]);
    for j = 1:size(t, 1)
        dtAnnotations(j).label = 1;
        dtAnnotations(j).score = 1;
        dtAnnotations(j).segment = t(j, :);
    end
    if length(dtAnnotations) == 1
        results.(cVidValidationList{i}) = {dtAnnotations};
    else
        results.(cVidValidationList{i}) = dtAnnotations;
    end
    hitCount = compareAnnotations_locOnly(gtAnnotations, dtAnnotations, opt);
    gtCount = length(gtAnnotations);
    dtCount = length(dtAnnotations);
    total_hitCount = total_hitCount + hitCount;
    total_gtCount = total_gtCount + gtCount;
    total_dtCount = total_dtCount + dtCount;
    fprintf('hit / gt = %d/%d,\t hit / dt = %d/%d\n', hitCount, gtCount, hitCount, dtCount);
end
validationTime = toc(validationTimeStart);
% valObj.version = 'VERSION 1.3';
% valObj.results = results;
% valObj.external_data.used = false;
% valObj.external_data.details = '';
% savejson('',valObj,fullfile('..', 'expData','detection_results_c3d_sos.json'));
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