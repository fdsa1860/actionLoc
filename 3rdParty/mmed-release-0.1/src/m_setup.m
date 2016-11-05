% setting up the paths
HMMpath = '../HMMall';
LibSVMpath = '~/LibSVM';

cwd = pwd;

% Compile the repmatC.c of Kevin Murphy's code. We only need to compile this file
cd(sprintf('%s/KPMtools', HMMpath'));
mex repmatC.c;


% Change back to the src directory
cd(cwd);
addpath(genpath('../HMMall'));
addpath('../bin');
addpath(LibSVMpath);
