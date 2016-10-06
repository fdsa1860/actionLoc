
% The MAD database example codes
% Citation: 
% Dong Huang, Yi Wang, Shitong Yao and F. De la Torre. Sequential Max-Margin Event Detectors, ECCV 2014

function Result= funEvalDetection(gtlabE, tslab, thr)
% INPUTS:
%
% gtlab: frame-level ground truth label (obtain by loading a true label file)
% tslab: frame-level label obtained by your algorithm
% thr: threshold of overlap ratio between 
% 
% OUTPUTS:
% Result.tru_N: total number of events 
%       .dct_N: total number of detected events
%       .dct_NT:dct_NT: number of correctly detection events
%       .Prec: correctly detected events over all detected events (dct_NT/dct_N)
%       .Rec: correctly detected events over all ground truth events (dct_NT/tru_N)

class_N = max(unique(gtlabE(:,1))); % null class is always the largest
e = cumsum(gtlabE(:,2));
s = [1; e(1:end-1)+1];
seglab = [s e];

sel = (gtlabE(:,1)~=class_N);
gtlab = gtlabE(sel,:);
seglab = seglab(sel,:);

dct_NT = 0;
tru_N = sum(sel);
for i = 1:size(seglab,1)
    tsseg = tslab(seglab(i,1):seglab(i,2));
    ratio = sum(tsseg==gtlab(i,1)) / gtlab(i,2);
    if ratio > thr
        dct_NT = dct_NT + 1;
    end
end

dct_N=0;
changeframe=1; 
for i=1:length(tslab)-1
    if (abs(tslab(i+1)-tslab(i))>0) % a change point
       if  ((i-changeframe)>10) % min length
           changeframe=i; 
           if tslab(changeframe)~=36 % not null class
              dct_N=dct_N+1; 
           end
       end
    end
    
end

% Output------
Result.tru_N= tru_N; %total number of events 
Result.dct_N= dct_N; %total number of detected events
Result.dct_NT=dct_NT; %number of correctly detection events
Result.Prec= dct_NT/dct_N; %correctly detected events over all detected events (dct_NT/dct_N)
Result.Rec=dct_NT/tru_N;%correctly detected events over all ground truth events (dct_NT/tru_N)




% Show Bar-------

f = figure('Units', 'normalized', 'Position', [0,0.5,.8,0.2]);

param.height = 1;
param.class_N = class_N;   
cmap = colormap(lines(param.class_N));
cmap(class_N,:) = .9*[1 1 1];
colormap(cmap);

im_true = labelConv(gtlabE, 'slab2flab');
im_test = tslab;

gt = subplot(2,1,1);
image(im_true);
% ft1 = title('');
% set(ft1, 'FontSize', 10);
set(gt, 'XTick', []);
set(get(gca,'XLabel'),'String','Frame')
set(gt, 'XTickLabel', []);
set(gt, 'YTick', []);
set(get(gca,'YLabel'),'String','True')
set(gt, 'Layer', 'bottom');
axis on
title(['Event-based Detection Results (',num2str(thr),' overlap): Total Events=',num2str(Result.tru_N),...
       ': Precision=', num2str(Result.Prec),...
       '; Recall=', num2str(Result.Rec)])

ts = subplot(2,1,2);
image(im_test);
% ft2 = title('');
% set(ft2, 'FontSize', 10);
set(ts, 'XTick', []);
set(get(gca,'XLabel'),'String','Frame')
set(ts, 'XTickLabel', []);
set(ts, 'YTick', []);
set(get(gca,'YLabel'),'String','Detected')
set(ts, 'Layer', 'bottom');
axis on
end



function label = labelConv(lab, mode)
%
% Convert from frame-level label to segment-level label, or vice versa.
%
% Description 
% label = labelConv(lab, mode) convert between frame-level label and
% segment-level label according to the mode.
%
% Inputs ------------------------------------------------------------------
%   o lab  : Frame-level label or segment-level label. Segment-level label
%            must be N*2, the first column is the label, the second column
%            should be segment length.
%   o mode : 2 mode. 'flab2slab' or 'slab2flab'. 
% Outputs -----------------------------------------------------------------
%   o label: label after conversion
% 
% By: Shitong Yao  // yshtng(at)gmail.com    
% Last modified: 18 July 2012
% 
if nargin < 2
    error('Two input arguments required!'); 
elseif nargin > 2
    error('Too many input arguments!');
end

if strcmpi(mode, 'flab2slab')
    % Frame-level label to segment-level label
    lab = [lab NaN];
    slab = zeros(length(lab),2);
    frame_count = 0;
    seg_count = 0;
    for i = 1:length(lab)-1
        frame_count = frame_count + 1;        
        if lab(i) ~= lab(i+1)   
            seg_count = seg_count + 1;
            slab(seg_count,:) = horzcat(lab(i), frame_count);
            frame_count = 0;   
            if i+1 == length(lab)
                break; 
            end
        end
    end
    label = slab(1:seg_count,:);  
elseif strcmpi(mode, 'slab2flab')
    % Segment-level label to frame-level label
    flab = zeros(1, sum(lab(:,2)));
    m = 0;
    for i = 1:size(lab,1)
        flab(1,m+1:m+lab(i,2)) = repmat(lab(i,1), 1, lab(i,2));
        m = m + lab(i,2);
    end
    label = flab;
else
    error('No such mode!');
end

end