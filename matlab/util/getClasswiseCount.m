function classwiseCount = getClasswiseCount(annotations, actionList)

classwiseCount = zeros(1, length(actionList));
for i = 1:length(annotations)
    index = find(strcmp(annotations(i).label, actionList));
    classwiseCount(index) = classwiseCount(index) + 1;
end

end