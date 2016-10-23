function  listVideoFiles(dataPath, outputFile)

fileList = dir(fullfile(dataPath, '*.mp4'));
fid = fopen(outputFile,'w');
for i = 1:length(fileList)
    fprintf(fid,'%s\n',fullfile(dataPath, fileList(i).name));
end
fclose(fid);

% fileName = 'sub_activitynet_v1-3.c3d.hdf5';
% info = h5info(fullfile(dataPath, fileName));
% 
% if ~exist(fullfile('..', 'expData'), 'dir')
%     mkdir(fullfile('..', 'expData'));
% end
% 
% if ~exist(fullfile('..', 'expData', 'activityNet_label.mat'), 'file')
%     label = loadjson(fullfile(dataPath, 'activity_net.v1-3.min.json'));
%     save(fullfile('..', 'expData', 'activityNet_label.mat'), 'label');
% else
%     load(fullfile('..', 'expData', 'activityNet_label.mat'));
% end
% 
% [activityList, vidList, cVidList, trInd, valInd, teInd] = ... 
%     getActivityList(info, label);
% 
% fid = fopen('activitynetVideoList.txt','w');
% for i = 1:length(vidList)
% fprintf(fid, '%s.mp4\n', vidList{i});
% end
% fclose(fid);

end