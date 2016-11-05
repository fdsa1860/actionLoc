function featVecs = m_getRandSegFeatVecs(SegD, nSample, kOpt, cnstrOpt)
% function featVecs = m_getRandSegFeatVecs(SegD, nSample, option)
% Inputs:
%   SegD: d*n the raw data of a time series
%   nSample: number of random segments to get
%   kOpt: kernel option
%   cnstrOpt: constraint option, required fields: minSegLen, maxSegLen, and segStride
%       If this is empty, no constraints on segment size will be imposed.
% Output:
%   featVecs: d*nSample matrix for nSample feature vectors
% By Minh Hoai Nguyen (minhhoai@gmail.com)
% Date: 27 Jan 2011


n = size(SegD, 2);
if (n == 0)
    featVecs = [];
    return;
end;

if ~exist('cnstrOpt', 'var') || isempty(cnstrOpt)
    cnstrOpt.minSegLen = 1;
    cnstrOpt.maxSegLen = intmax('int32');
    cnstrOpt.segStride = 1;
end;

[segStarts, segEnds] = meshgrid(1:cnstrOpt.segStride:n, 1:cnstrOpt.segStride:n);
segLens = segEnds - segStarts  + 1;
validIdxs = and(segLens >= cnstrOpt.minSegLen, segLens <= cnstrOpt.maxSegLen);
if isempty(~find(validIdxs))
    featVecs = [];
    return;
end;
randSegs = [segStarts(validIdxs) segEnds(validIdxs)]';
randNums = randi(size(randSegs,2), [1, nSample]);
randSegs = randSegs(:, randNums);


d = size(SegD, 1);
fd = m_getFd(kOpt, d);
featVecs = zeros(fd, nSample);
for i=1:nSample
    featVecs(:,i) = m_getSegFeatVec(SegD(:, randSegs(1,i):randSegs(2,i)), kOpt);
end
