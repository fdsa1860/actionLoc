function [w, b] = m_trnSegSVM(Ds, lbs, kOpt, C, truncRatios, cnstrOpt, nNegPerTS)
% [w, b] = m_trnSegSVM(Ds, lbs, C)
% Train a segment-based SVM
%   The positve samples are the gt events, and possibly truncated gt events
%   The negative samples are random segments that do not overlap with gt events.
% Inputs:
%   Ds: n*1 cell structure of time series, Ds{i} is d*n_i matrix
%   lbs: 2*n matrix for gt labels, lbs(:,i) is 2*1 vector for event's onset and offset
%   kOpt: kernel option
%   C: C for SVM
%   truncRatios: 1*k vector whose entries are between 0 and 1.
%       This tells us the proportions of gt events are used as positive samples
%       Default value is [1];
%   cnstrOpt: options for constraints. Only two fields are used: minSegLen and maxSegLen
%   nNegPerTS: number of negative segments per time series. Default is 20.
% Outputs:
%   w, b: for linear SVM
% By Minh Hoai Nguyen (minhhoai@gmail.com)
% Date: 27 Jan 2011
% Last modified: 9 May 2011

if ~exist('truncRatios', 'var') || isempty(truncRatios)
    truncRatios = 1;
end;
    
if ~exist('nNegPerTS', 'var') || isempty(nNegPerTS)
    nNegPerTS = 20; % number of negative samples per time series
end;
nNegPerTS_o2 = ceil(nNegPerTS/2); 


n = length(Ds);
d = size(Ds{1},1);
fd = m_getFd(kOpt, d);
posFeatVecs = cell(1, n);
negFeatVecs = cell(1, n);
for i=1:n
    D = Ds{i};
    lb = lbs(:,i);
    len_i = lb(2) - lb(1) + 1;
    if (lb(1) > 0) % contain the event of interest
        posVecs = zeros(fd, length(truncRatios));
        for k=1:length(truncRatios)
            truncLen = floor(truncRatios(k)*len_i);
            posVecs(:,k) = m_getSegFeatVec(D(:, lb(1):(lb(1)+truncLen-1)), kOpt);
        end;
        posFeatVecs{i} = posVecs;
    end;
    
    negFeatVecs_i1 = m_getRandSegFeatVecs(D(:,1:lb(1)-1), nNegPerTS_o2, kOpt, cnstrOpt);
    negFeatVecs_i2 = m_getRandSegFeatVecs(D(:,lb(2)+1:end), nNegPerTS_o2, kOpt, cnstrOpt);
    negFeatVecs{i} = cat(2, negFeatVecs_i1, negFeatVecs_i2);
end;

posD = cat(2, posFeatVecs{:});
negD = cat(2, negFeatVecs{:});
nPos = size(posD, 2);
nNeg = size(negD, 2);

trLb = [ones(nPos,1); -ones(nNeg, 1)];
TrD = [posD, negD];

% Include option for reweighting two classes
opts = sprintf('-t 0 -c %g -w1 %g -w-1 %g', C, 1/nPos, 1/nNeg);
% opts = sprintf('-t 0 -c %g', C);
model = svmtrain(trLb, TrD', opts);  
w = model.SVs'*model.sv_coef;
b = - model.rho;

