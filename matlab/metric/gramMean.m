function Xm = gramMean(X, opt)
% compute manifold mean of a group of SPD matrices

invalidInd = cellfun(@isempty, X);
X(invalidInd) = [];

if strcmp(opt.metric,'JBLD')
    Xm = steinMean(cat(3,X{1:end}));
elseif strcmp(opt.metric,'AIRM')
    Xm = karcher(X{1:end});
elseif strcmp(opt.metric,'LERM')
    Xm = logEucMean(X{1:end});
elseif strcmp(opt.metric,'KLDM')
    Xm = jefferyMean(X{1:end});
end

end