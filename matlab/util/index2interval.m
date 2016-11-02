function interval = index2interval(indicator)

if all(indicator)
    interval = [1 length(indicator)];
    return;
elseif ~any(indicator)
    interval = [];
    return;
end

dif = diff(indicator);
indStart = find(dif > 0) + 1;
indEnd = find(dif < 0);

if indicator(1) == 1
    indStart = [1 indStart];
end
if indicator(end) == 1
    indEnd = [indEnd length(indicator)];
end

interval = [indStart', indEnd'];

end