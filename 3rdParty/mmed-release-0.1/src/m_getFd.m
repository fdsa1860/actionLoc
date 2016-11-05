function fd = m_getFd(kOpt, d)
% function fd = m_getFd(kOpt, d)
% Get the dimension of feature vector
% Inputs:
%   kOpt: kernel option
%   d: the dimension of raw feature vectors
% Outputs:
%   fd: the dimension of feature vectors
% By Minh Hoai Nguyen (minhhoai@gmail.com)
% Date: 10 Feb 2011
% Last modified: 24 Feb 2011

if kOpt.featType == 0 || kOpt.featType == 2
    rd = d;
else
    rd = kOpt.sd*d;
end;

if (kOpt.type == 0) || (kOpt.type == 1)
    fd = rd*(2*kOpt.n + 1);
else
    fd = rd;
end;

if ~isfield(kOpt, 'nSegDiv')
    kOpt.nSegDiv = 1;
end
fd = fd*kOpt.nSegDiv;
    


