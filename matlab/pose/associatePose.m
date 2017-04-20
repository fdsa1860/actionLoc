function poseTracklet = associatePose(poseDet, opt)
% this function connect pose detections into short tracklets according to
% location neighborhood
% TODO: make the connection also affected by appearance similarity

poseTracklet = struct('data',{}, 'tStart',{}, 'tEnd',{}, 'length', {});
nTracklet = 0;
for i = 1:length(poseDet)
    currPose = poseDet{i};
    if isempty(currPose)
        continue;
    end
    nPose = size(currPose, 2);
    for j = 1:nPose
        [idx, leastErr] = matchTracket(poseTracklet, currPose(:, j), i, opt.locThres);
        if idx > 0
            poseTracklet(idx) = addPose(poseTracklet(idx), currPose(:, j));
        else
            nTracklet = nTracklet + 1;
            poseTracklet(nTracklet) = struct('data',currPose(:, j), 'tStart',i, 'tEnd',i, 'length', 1);
        end
    end
end

end