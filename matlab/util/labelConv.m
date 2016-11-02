% function label = labelConv(lab)
%     % Segment-level label to frame-level label
%     flab = zeros(1, sum(lab(:,2)));
%     m = 0;
%     for i = 1:size(lab,1)
%         flab(1,m+1:m+lab(i,2)) = repmat(lab(i,1), 1, lab(i,2));
%         m = m + lab(i,2);
%     end
%     label = flab;
% end

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