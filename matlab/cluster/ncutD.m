function [label,W] = ncutD(D,nCluster,kNN, scale_sig, eigThres)
% ncutW:
% perform normalized cut clustering distance matrix D
% Input:
% D: an N-by-N matrix
% nCluster: the number of clusters
% kNN: number of k nearest neighbors
% scale_sig: scaling factor
% Output:
% label: the clustered labeling results
% W: similarity matrix

if nargin < 5
    eigThres = 0.1;
end

if nargin < 4
    scale_sig = 1;
end

if nargin >= 3
    D = D - min(D(:));
    D2 = D;
    for j=1:size(D,1)
        [~,ind] = sort(D(:,j));
        D2(ind(kNN+1:end),j) = Inf;
        D2(ind(1:kNN),j) = D(ind(1:kNN),j) / max(D(ind(1:kNN),j)) * 0.5;
    end
    % D = min(D2,D2');%(B+B')/2;
    D = (D2+D2')/2;
    % D = max(D2,D2');
end

n = size(D, 1);
W = exp(-D.^2/(2*scale_sig^2));

if nCluster == -1
    d = sum(W);
    DInvSqrt = diag( 1 ./ sqrt(d+eps) );
    L = eye(size(W)) - DInvSqrt * W * DInvSqrt;
    % [eigVec, EigVal] = eigs(L,nEigVal,'SM');
    [eigVec, EigVal] = eig(L);
    eigVal = diag(EigVal);
    eigVal = sort(eigVal);
    nCluster = nnz(eigVal < eigThres);
end

NcutDiscrete = ncutW(W, nCluster);
% label = sortLabel_count(NcutDiscrete);
label = sortLabel_order(NcutDiscrete, 1:n);

end