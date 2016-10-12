function [data, gt, tr_te_split] = parseActivityNet(opt)
% parse activityNet dataset

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

lbl = label.database;

L = 1000;
data = cell(L, 1);
gt = cell(L, 1);
trInd = false(L, 1);
valInd = false(L, 1);
teInd = false(L, 1);
for i = 1:L
    vid = info.Groups(i).Name(2:end);
    dataName = sprintf('/%s/c3d_features', vid);
    data{i} = h5read(fullfile(dataPath, fileName), dataName);
    cVid = convertVID(vid);
    l = lbl.(cVid);
    if ~strcmp(l.subset, 'testing')
        gt{i} = l.annotations{1}.label;
    end
    trInd(i) = strcmp(l.subset, 'training');
    valInd(i) = strcmp(l.subset, 'validation');
    teInd(i) = strcmp(l.subset, 'testing');
end

tr_te_split.trInd = trInd;
tr_te_split.valInd = valInd;
tr_te_split.teInd = teInd;

end