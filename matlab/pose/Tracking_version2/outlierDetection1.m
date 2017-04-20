
addpath(genpath('JBLD'));
addpath(genpath('..'));
dbstop if error

% np: number of parts(joints);
% fram: number of frames for each video
% data : a cell array with length of frame number cell(1,frameNum),each
% data{1,i} : np*2 double (joint position)
%%
load('poseCell.mat');
pose = cell(1,length(poseCell));
N = 28;
Pose2 = zeros(14,2);
for m = 1 : length(poseCell)
    
    Pose1 = poseCell{1,m};
    
for n = 1 : N/2
    
    Pose2(n,:) = [Pose1(2*n-1,1) Pose1(2*n,1)];
    
    
   
end  

 pose{1,m} = Pose2;   
end





%%

np = 14;
fram = 55;

[Jbld, SOS_score, Outlier,Joint_Frm] = OutlierDet(np,fram,pose);
% [Jbld, Joint_Frm] = OutlierDet(np,fram,pose);


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
        omega = ones(1,fram);
        omega(:,ithFram) = 0; % set omega equals to 0 at the frame of outlier
        up = zeros(2,fram);
        Omega{1,k} = omega;
        
         Joint_Frm{1,k}(:,ithFram) = 0;
        Trajec_new{1,k} = l2_fastalm_mo(Joint_Frm{1,k},lambda,'omega',Omega{1,k});
           
end