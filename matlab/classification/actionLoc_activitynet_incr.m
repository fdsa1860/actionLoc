function [accuracy, y_pred, y_val] = actionLoc_activitynet_incr(opt)

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
if ~exist(fullfile('..', 'expData', 'Gm.mat'), 'file')
    nTrain = nnz(trInd);
    vidTrainList = vidList(trInd);
    cVidTrainList = cVidList(trInd);
    trainLabelList = cell(nTrain, 1);
    for i = 1:nTrain
        trainLabelList{i} = lbl.(cVidTrainList{i}).annotations{1}.label;
    end
    
    Gm = cell(length(activityList), 1);
    for j = 1:length(activityList)
        fprintf('Training activity %d/%d ... \n', j, length(activityList));
        index = find(strcmp(trainLabelList, activityList{j}));
        G_pool = cell(length(index), 1);
        for i = 1:length(index)
            dataName = sprintf('/%s/c3d_features', vidTrainList{index(i)});
            data = h5read(fullfile(dataPath, fileName), dataName);
            G_pool{i} = getGram(data, opt);
        end
        Gm{j} = gramMean(G_pool, opt);
    end
    
    save(fullfile('..', 'expData', 'Gm.mat'), 'Gm');
else
    load(fullfile('..', 'expData', 'Gm.mat'));
end

% validation
nVal = nnz(valInd);
vidValidationList = vidList(valInd);
cVidValidationList = cVidList(valInd);
y_pred = cell(nVal, 1);
y_val = cell(nVal, 1);
for i = 1:nVal
    fprintf('Test on Validation data %d/%d ... \n', i, nVal);
    y_val{i} = lbl.(cVidValidationList{i}).annotations{1}.label;
    dataName = sprintf('/%s/c3d_features', vidValidationList{i});
    data = h5read(fullfile(dataPath, fileName), dataName);
    G = getGram(data, opt);
    d = HHdist(Gm, {G}, opt);
    [~, ind] = min(d);
    y_pred{i} = activityList{ind};
end

% y_pred = cell(length(info.Groups), 1);
% y_val = cell(length(info.Groups), 1);
% count = 1;
% for i = 1:length(info.Groups)
%     vid = info.Groups(i).Name(2:end);
%     cVid = convertVID(vid);
%     l = lbl.(cVid);
%     if ~strcmp(l.subset, 'validation')
%         continue;
%     end
%     dataName = sprintf('/%s/c3d_features', vid);
%     data = h5read(fullfile(dataPath, fileName), dataName);
%     G = getGram(data, opt);
%     d = HHdist(Gm, {G}, opt);
%     [~, ind] = min(d);
%     y_pred{count} = activityList{ind};
%     y_val{count} = l.annotations{1}.label;
%     count = count + 1;
% end
% y_pred(count:end) = [];
% y_val(count:end) = [];

accuracy = nnz(strcmp(y_val, y_pred)) / length(y_val);

save(fullfile('..', 'expData', 'res_activitynet.mat'), accuracy, y_pred, ...
    y_val);

end