function [activityList, vidList, cVidList, trInd, valInd, teInd] = getActivityList(info, label)
% get all activity name list of the activityNet dataset

lbl = label.database;
L = length(info.Groups);
gt = cell(L, 1);
vidList = cell(L, 1);
cVidList = cell(L, 1);
trInd = false(L, 1);
valInd = false(L, 1);
teInd = false(L, 1);
for i = 1:L
    vidList{i} = info.Groups(i).Name(2:end);
    cVidList{i} = convertVID(vidList{i});
    l = lbl.(cVidList{i});
    if ~strcmp(l.subset, 'testing')
        gt{i} = l.annotations{1}.label;
    end
    trInd(i) = strcmp(l.subset, 'training');
    valInd(i) = strcmp(l.subset, 'validation');
    teInd(i) = strcmp(l.subset, 'testing');
end

gt_valid = gt(~cellfun(@isempty, gt));
activityList = unique(gt_valid);

end