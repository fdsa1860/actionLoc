function poseTracklet1 = addPose(poseTracklet1, currPose)

poseTracklet1.data = [poseTracklet1.data, currPose];
poseTracklet1.tEnd = poseTracklet1.tEnd + 1;
poseTracklet1.length = poseTracklet1.length + 1;

end