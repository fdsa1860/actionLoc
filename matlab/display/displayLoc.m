
function displayLoc(gtlab, tslab)
% INPUTS:
%
% gtlab: frame-level ground truth label (obtain by loading a true label file)
% tslab: frame-level label obtained by your algorithm

class_N = max(unique(gtlab));

% Show Bar-------

f = figure('Units', 'normalized', 'Position', [0,0.5,.8,0.2]);

param.height = 1;
param.class_N = class_N;   
cmap = colormap(lines(param.class_N));
cmap(class_N,:) = .9*[1 1 1];
colormap(cmap);

im_true = gtlab;
im_test = tslab;

gt = subplot(2,1,1);
imagesc(im_true);
% ft1 = title('');
% set(ft1, 'FontSize', 10);
set(gt, 'XTick', []);
set(get(gca,'XLabel'),'String','Frame')
set(gt, 'XTickLabel', []);
set(gt, 'YTick', []);
set(get(gca,'YLabel'),'String','True')
set(gt, 'Layer', 'bottom');
axis on
title('Event-based Detection Results');

ts = subplot(2,1,2);
imagesc(im_test);
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
