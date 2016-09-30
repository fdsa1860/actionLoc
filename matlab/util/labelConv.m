function label = labelConv(lab)
    % Segment-level label to frame-level label
    flab = zeros(1, sum(lab(:,2)));
    m = 0;
    for i = 1:size(lab,1)
        flab(1,m+1:m+lab(i,2)) = repmat(lab(i,1), 1, lab(i,2));
        m = m + lab(i,2);
    end
    label = flab;
end