% test
addpath(genpath('JBLD'));
addpath(genpath('..'));
dbstop if error


actionList = {
    'Diving-Side','Kicking-Front','Run-Side','Walk-Front','Golf-Swing-Back',...
    'Kicking-Side','SkateBoarding-Front','Golf-Swing-Front','Lifting',...
    'Swing-Bench','Golf-Swing-Side','Riding-Horse','Swing-SideAngle' };

action = 'Diving-Side';
instance = '001';

poseDir = fullfile('~', 'research', 'code', 'extern', ...
    'convolutional-pose-machines-release', 'testing', 'python', ...
    'ucf_pose', action, instance);
poseFiles = dir(fullfile(poseDir, '*.mat'));

np = 14;
nFrame = length(poseFiles);
poseIn = cell(1, nFrame);
for i = 1:length(poseFiles)
    load(fullfile(poseDir, poseFiles(i).name));
    if isempty(prediction)
        poseIn{i} = zeros(np, 2);
        continue;
    end
    poseIn{i} = prediction;
end

[Jbld, SOS_score, Outlier,Joint_Frm] = OutlierDet(np,nFrame,poseIn);

%% Outlier frames

% dt & fr are defined in 'JbldValue_New.m'
dt = 2; %shifting frame
fr = 9; %window size when computing Jbld

OutlierFram = cell(1,np);% {1,i} : joint position on one frame
Omega = cell(1,np);
Trajec_new = cell(1,np);
lambda = 10;

for k = 1 : np
    ithOut = Outlier{1,k};%
    ithFram = ithOut*dt+fr; % the frame when outlier occured
    OutlierFram{1,k} = ithFram;
    % smooth tracjectory
    omega = ones(1,nFrame);
    omega(:,ithFram) = 0; % set omega equals to 0 at the frame of outlier
    up = zeros(2,nFrame);
    Omega{1,k} = omega;
    
    Joint_Frm{1,k}(:,ithFram) = 0;
    Trajec_new{1,k} = l2_fastalm_mo(Joint_Frm{1,k},lambda,'omega',Omega{1,k});
end

poseOut = cell2mat(Trajec_new');
save poseOut poseOut