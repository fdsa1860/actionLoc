function tNew = removeMean(t)

tm = mean(t, 2);
tNew = bsxfun(@minus, t, tm);

end