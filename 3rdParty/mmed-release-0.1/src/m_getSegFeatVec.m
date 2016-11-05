function featVec = m_getSegFeatVec(SegD, kOpt)
% Compute feature vector representing a segment
% Inputs:
%   SegD: d*k the raw segment data
%   kOpt: kernel option must have fileds: type, n, L
% Output:
%   featVec: feature vector
% By Minh Hoai Nguyen (minhhoai@gmail.com)
% Date: 27 Jan 2011
% Last modified: 11 Feb 2011    


if ~isfield(kOpt, 'nSegDiv')
    featVec = getSegFeatVec_oneDiv(SegD, kOpt);
else
    divLen = floor(size(SegD, 2)/kOpt.nSegDiv);
    feats = cell(1, kOpt.nSegDiv);
    
    ev_i_s = 1;
    for i=1:(kOpt.nSegDiv-1)
        feats{i} = getSegFeatVec_oneDiv(SegD(:, ev_i_s:(ev_i_s + divLen - 1)), kOpt);
        ev_i_s = ev_i_s + divLen;
    end;
    feats{kOpt.nSegDiv} = getSegFeatVec_oneDiv(SegD(:, ev_i_s:end), kOpt);
    featVec = cat(1, feats{:});
end;


function featVec = getSegFeatVec_oneDiv(SegD, kOpt)

    if kOpt.featType == 0
        rawFeatVec = sum(SegD, 2);
    elseif kOpt.featType == 1
    %     fprintf('size(SegD,2): %d\n', size(SegD,2));
        rawFeatVec = m_mexSampleSeg(SegD, [1, size(SegD,2)], kOpt.sd);
    %     fprintf('   done\n');
    elseif kOpt.featType == 2
        rawFeatVec = SegD(:,end) - SegD(:,1);
    end;

    if kOpt.type <= 5
        featVec = m_getFrmFeatVecs(rawFeatVec, kOpt);   
    elseif kOpt.type == 6 % linear, length normalized.
        featVec = rawFeatVec/size(SegD, 2);
    end;

