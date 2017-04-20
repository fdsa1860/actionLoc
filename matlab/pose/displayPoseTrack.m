function displayPoseTrack(imgPath, poseTrack)
% display pose tracks

addpath(genpath('../matlab'));
param = config();
model = param.model(param.modelID);
np = model.np;

imgFiles = dir([imgPath '/*.jpg']);
for i = 1:length(imgFiles)
    im = imread(fullfile(imgPath, imgFiles(i).name));
    predict = [];
    for k = 1:length(poseTrack)
        idx = i - poseTrack(k).tStart + 1;
        if idx < 1 || idx > poseTrack(k).length
            pred = [];
        else
            pred = poseTrack(k).data(:, idx);
            pred = reshape(pred, 2, [])';
            predict = cat(3, predict, pred);
        end
    end
    if isempty(predict)
        continue;
    end
    wei_visualize(im, predict, param)
    title(sprintf('Frame %d', i));
    pause;
end
