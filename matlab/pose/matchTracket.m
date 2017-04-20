function [idx, leastErr] = matchTracket(poseTracklet, currPose, fr, thres)

idx = -1;
leastErr = inf;

if isempty(poseTracklet)
    return;
end


nTrack = length(poseTracklet);
for i = 1:nTrack
    if poseTracklet(i).tEnd ~= (fr - 1)
        continue;
    end
    err = norm(poseTracklet(i).data(:, end) - currPose);
    if err < leastErr
        leastErr = err;
        idx = i;
    end
end

if leastErr > thres
    idx = -1;
end

end