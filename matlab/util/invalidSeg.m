function invalid = invalidSeg(segmentIndex)

invalid = ~all(diff(segmentIndex));

end