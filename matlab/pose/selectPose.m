% select the best pose from automatically selected candidates

dataName = 'diving001';

% show my demo results
global GLOBAL_OVERRIDER;
GLOBAL_OVERRIDER = @lsp_conf;
conf = global_conf();
pa = conf.pa;
p_no = length(pa); % p_no = 26;

if strcmp(dataName, 'diving001')
    load ../expData/CNN_Deep_13_diving001_boxes.mat;
    dataPath = '~/research/data/ucf_sports_actions/diving-side/001';
elseif strcmp(dataName, 'diving002')
    load ../expData/CNN_Deep_13_diving002_boxes.mat;
    dataPath = '~/research/data/ucf_sports_actions/diving-side/002';
elseif strcmp(dataName, 'golf001')
    load ../expData/CNN_Deep_13_golf001_boxes.mat;
    dataPath = '~/research/data/ucf_sports_actions/Golf-Swing-Side/001';
elseif strcmp(dataName, 'golf002')
    load ../expData/CNN_Deep_13_golf002_boxes.mat;
    dataPath = '~/research/data/ucf_sports_actions/Golf-Swing-Side/002';
elseif strcmp(dataName, 'swingBench001')
    load ../expData/CNN_Deep_13_SwingBench001_boxes.mat;
    dataPath = '~/research/data/ucf_sports_actions/Swing-Bench/001';
end

jpgFiles = dir([dataPath '/*.jpg']);

selBoxes = cell(1, length(boxes));

ind = ones(1, length(boxes));
invalid = zeros(1, length(boxes));

% % diving 001 manually labeled
% ind(47) = 2; ind(49) = 4; ind(50) = 4;
% invalid([24, 48, 49, 52:55]) = 1;

% % diving 002 manually labeled
% ind(39) = 6; ind(40) = 5; ind(41) = 6; ind(42) = 5; ind(43) = 5; ind(44) = 5; ind(45) = 2;
% invalid([18, 23, 33:41, 43:46, 52:55]) = 1;

% golf 001 manually labeled
% invalid([20, 25, 38:39]) = 1;

% golf 002 manually labeled
invalid([1:11, 38, 42, 54:60]) = 1;

% for i = 2
for i = 1:length(jpgFiles)
    i
%     im = imread(sprintf('dataset/MAD/fr%04d.jpg', i));
    im = imread(fullfile(dataPath, jpgFiles(i).name));
    selBoxes{i} = boxes{i}(ind(i), :);
%     selBoxes{i} = boxes{i};
    showskeletons(im, selBoxes{i}, pa);
    currFrame = getframe;
%     keyboard;
    pause(0.1);
end

ske = box2ske(selBoxes, p_no);

% save ske_golf_002 ske invalid