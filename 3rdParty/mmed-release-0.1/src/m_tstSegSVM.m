function [rocArea, xroc, yroc, xamoc, yamoc, xF1, yF1] = ...
    m_tstSegSVM(Ds, lbs, kOpt, sOpt, w, b, amocOpt)
% function [rocArea, xroc, yroc, xamoc, yamoc, xF1, yF1] = ...
%    m_tstSegSVM(Ds, lbs, kOpt, sOpt, w, b, amocOpt)
% Test a frame-based SVM
% Inputs:
%   Ds: n*1 cell structure of time series, Ds{i} is d*n_i matrix
%   lbs: 2*n matrix for gt labels, lbs(:,i) is 2*1 vector for event's onset and offset
%   kOpt: kernel option
%   sOpt: search and segment option
%   w, b: parameters of linear SVM model
%   amocOpt: option for AMOC curve, either 'mean' or 'median', default is 'median'
% Outputs:
%   rocArea: 
%   xroc, yroc, xamoc, yamoc: performance curves
%   xF1, yF1: F1 curve
% By Minh Hoai Nguyen (minhhoai@gmail.com)
% Date: 27 Jan 2011
% Last modified: 11 Feb 11


nTst = length(Ds);
detectScores = cell(1, nTst);

yF1s = cell(1, nTst);

for i=1:nTst
    detectOut = m_mexEval_ker(Ds{i}, w, b, kOpt, sOpt);
    detectScores{i} = detectOut(3,:);    
    [xF1, yF1s{i}] = m_mexF1curve(detectOut, lbs(:,i), 0.001);
%     if (i <= nR*nC)
%         subplot(nR, nC, i); hold on; plot(xF1, yF1s{i});
%     end;
end;

[xroc, yroc, rocArea]   = m_getPerfCurve(detectScores, lbs,'ROC');
if ~exist('amocOpt', 'var') || isempty(amocOpt) || strcmpi(amocOpt, 'AMOC-median')
    [xamoc, yamoc] = m_getPerfCurve(detectScores, lbs,'AMOC');
elseif strcmpi(amocOpt, 'AMOC-mean')
    [xamoc, yamoc] = m_getPerfCurve(detectScores, lbs,'AMOC-mean');
else
    error('m_tstSegSVM.m: unknown amocOpt');
end;
yF1 = mean(cat(1, yF1s{:}),1);


