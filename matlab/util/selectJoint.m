function X_truncate = selectJoint(X, jointIndex)
% Given joint indices, select the data corresponding to the joints

ind_tmp = [3*jointIndex-2; 3*jointIndex-1; 3*jointIndex];
selInd = ind_tmp(:);
s.type = '()';
s.subs = {selInd, ':'};
X_truncate = cellfun(@(A)subsref(A, s), X, 'uniform', false);

end