% test JBLD

dataPath = fullfile('..','..','expData', 'ucf_tracks');

actionList = {
    'Diving-Side','Golf-Swing-Back','Golf-Swing-Front','Golf-Swing-Side',...
    'Kicking-Front','Kicking-Side','Lifting','Riding-Horse','Run-Side',...
    'SkateBoarding-Front','Swing-Bench','Swing-SideAngle','Walk-Front',...
    };
nInstanceList = [14, 5, 8, 5, 10, 10, 6, 12, 13, 12, 20, 13, 22];

feat = {};
% load diving001;
% feat{end+1} = poseTrack.data;
% load diving002;
% feat{end+1} = poseTrack.data;
% load walk001;
% feat{end+1} = poseTrack.data;
% load walk002;
% feat{end+1} = poseTrack.data;

label = [];
for ai = 1:13
    action = actionList{ai};
    for vi = 1:nInstanceList(ai)
        instance = sprintf('%03d', vi);
        file = fullfile(dataPath, action, instance, 'poseTrack.mat');
        if ~exist(file, 'file'), continue; end
        load(file);
        normalizedPoseTrack = normalizePose(poseTrack.data);
        v = diff(normalizedPoseTrack, [], 2);
        feat{end+1} = normalizedPoseTrack;
        label(end+1) = ai;
    end
end


opt.metric = 'JBLD';
opt.sigma = 10^-4;
opt.H_structure = 'HHt';
opt.H_rows = 3;

HH  = getGram_batch(feat,opt);
D = HHdist(HH, [], opt);
figure;imagesc(D);