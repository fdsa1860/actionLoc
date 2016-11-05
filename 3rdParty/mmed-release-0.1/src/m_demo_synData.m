function m_demo_synData()
% function m_demo_synData()
% This function runs the synthetic data experiments. 
% It first generates 100 training and 100 testing time series.
% It runs both MMED and SOSVM and displays results graphically.
% it also also prints the Normalized Time to Detect (NTtoD) for both methods.
% The plot show how soon the SOSVM and MMED detect the target event. 
% By: Minh Hoai Nguyen (minhhoai@gmail.com)
% Date: 9 Jan 2011
% Last modified: 3 Jun 2012

addpath('../bin');

% Kernel option
% 0: 'Chi2', 1: 'Intersection', 2: 'Linear', 3:'Linear-unnormalized'
kOpt.type = 2;
kOpt.n = 5;
kOpt.L = 0.38; % for good approx. use 0.38 for Chi2 and n=5, use 0.83 for Inter and n=5;
kOpt.featType = 0; % 0: Bag, 1: Order
kOpt.sd = -1;

% Constraint option
cnstrOpt.minSegLen = 1;
cnstrOpt.maxSegLen = intmax('int32');
cnstrOpt.segStride  = 1;
cnstrOpt.trEvStride = 1;
cnstrOpt.shldCacheSegFeat  = 1;
cnstrOpt.shldCacheTrEvFeat = 1;

% Search option
sOpt.minSegLen = 1;
sOpt.maxSegLen = intmax('int32');
sOpt.segStride = 1;


nTr  = 100;
nTst = 100;
C = 1000;
[D, Ds, label, mus] = genSynData(nTr, 1);
d = size(Ds{1},1);
fd = m_getFd(kOpt, d);
w_init = rand(fd, 1);

[w,b] = m_mexMMED_ker(Ds, label, C, mus, ...
    w_init, kOpt, 'instant+extent', cnstrOpt);
[w_off, b_off] = m_mexMMED_ker(Ds, label, C, mus, ...
    w_init, kOpt, 'offline+extent', cnstrOpt);


[D_tst, Ds_tst, label_tst] = genSynData(nTst, 0);
detectScores = cell(1, nTst);
detectScores_off = cell(1, nTst);
NTtoDs = zeros(1, nTst);
NTtoDs_off = zeros(1, nTst);

nR = 5; nC = 2; lnWdth = 2; 
figure(2); clf;
for i=1:nTst
    n_i = length(D_tst{i});    
    lb_i = label_tst(:,i);
    if kOpt.type == 3
        detectOut = m_mexEval(Ds_tst{i}, w, b);
        detectOut_off = m_mexEval(Ds_tst{i}, w_off, b_off);
    else
        detectOut = m_mexEval_ker(Ds_tst{i}, w, b, kOpt, sOpt);
        detectOut_off = m_mexEval_ker(Ds_tst{i}, w_off, b_off, kOpt, sOpt);
    end;
    detectScores{i} = detectOut(3,:);
    detectScores_off{i} = detectOut_off(3,:);
    fstPosIdx = find(detectOut(3,:) > 0, 1);
    fstPosIdx_off = find(detectOut_off(3,:) > 0, 1);
    len_i = lb_i(2) - lb_i(1) + 1;
    NTtoDs(i)     = (fstPosIdx     - lb_i(1)+1)/len_i;
    NTtoDs_off(i) = (fstPosIdx_off - lb_i(1)+1)/len_i;


    fprintf('Test TS %3d, gt: [%3d %3d], SO-SVM: [%3d %3d], MMED: [%3d %3d]\n', ...
        i, label_tst(1,i), label_tst(2,i), detectOut_off(1,end), detectOut_off(2,end), ...
        detectOut(1,end), detectOut(2,end));
    
    if (i > nR*nC) % only plot a few time series
        continue;
    end;
    
    % plot the time series
    subplot(nR, nC, i);
    minY = -1;
    maxY = d ;
    
    % plot the background part of the time series
    xx = 1:label_tst(1,i)-1;
    gray = [0.2, 0.2, 0.2];
    plot(xx, D_tst{i}(xx), 'color', gray, 'LineWidth', lnWdth); hold on;
    xx = label_tst(2,i)+1:n_i;
    plot(xx, D_tst{i}(xx), 'color', gray, 'LineWidth', lnWdth); hold on;

    % plot the lines marking the moments when detector output positive results.    
    line(fstPosIdx*ones(2,1), [minY, maxY], 'color', 'r', 'LineWidth',lnWdth, 'LineStyle','-'); hold on;
    line(fstPosIdx_off*ones(2,1), [minY, maxY], 'color', 'b', 'LineWidth',lnWdth, 'LineStyle','--');
    
    % plot the event of interest
    xx =label_tst(1,i)-1:label_tst(2,i)+1;
    plot(xx, D_tst{i}(xx), 'g', 'LineWidth', lnWdth);
    axis([0 200 minY maxY]);
end;

% Plot the ROC and AMOC curves
[xroc, yroc]   = m_getPerfCurve(detectScores, label_tst,'ROC');
[xamoc, yamoc] = m_getPerfCurve(detectScores, label_tst,'AMOC');
[xroc_off, yroc_off]   = m_getPerfCurve(detectScores_off, label_tst, 'ROC');
[xamoc_off, yamoc_off] = m_getPerfCurve(detectScores_off, label_tst, 'AMOC');

lnWdth = 3; fntSz = 16;
figure(3); clf; 
subplot(2,1,1); plot(xroc_off, yroc_off, 'b', 'LineWidth',lnWdth, 'LineStyle','--');
hold on; plot(xroc, yroc, 'r', 'LineWidth',lnWdth, 'LineStyle','-');
axis([0 1 0 1]); axis square;
xlabel('False Positive Rate', 'FontSize', fntSz); 
ylabel('True Postivie Rate', 'FontSize', fntSz);
legend('SOSVM', 'MMED'); 
set(gca, 'FontSize', fntSz);
title('ROC');

subplot(2,1,2); plot(xamoc_off, yamoc_off, 'b', 'LineWidth',lnWdth, 'LineStyle','--');
hold on; plot(xamoc, yamoc, 'r', 'LineWidth',lnWdth,'LineStyle','-');
axis([0 1 0 1]); axis square;
xlabel('False Positive Rate', 'FontSize', fntSz); 
ylabel('Normalized Time to Detect', 'FontSize', fntSz);
legend('SOSVM', 'MMED');
set(gca, 'FontSize', fntSz);
title('AMOC');

fprintf('NTtoD for SOSVM: %g, MMED: %g\n', mean(NTtoDs_off), mean(NTtoDs));



% Generate synthetic data, the data are simpler (less bins/steps) than genSynData    
% D: a cell structure, D{i} is one dimensional vector
% Ds: a cell structure, Ds{i} is a binary matrix encoding
% This is the main data for synthetic experiment
function [D, Ds, label, mus] = genSynData(n, shldDisp)
    baseL = 10;
    pat1 = repmat([1 2], baseL, 1); pat1 = pat1(:)';
    pat2 = repmat([-1 -2], baseL, 1); pat2 = pat2(:)';
    pat0 = repmat([1 -1 2 -2], baseL, 1); pat0 = pat0(:)';

    minElem = min(pat0);
    pat1 = pat1 - minElem;
    pat2 = pat2 - minElem;
    pat0 = pat0 - minElem;
    bg = -minElem;
    nBin = max([pat0, pat1, pat2]);

    pats = {pat1, pat2, pat0};
    masks = {zeros(1, length(pat1)), zeros(1, length(pat2)), ones(1, length(pat0))};
    
    if shldDisp
        % plotting
        figure(1); clf;
        nR = 2; nC = 2; maxX = 50; minY = -1; maxY = 5; bgL = 10;
        fntSz = 12; lnWdth = 2; gray = [0.2, 0.2, 0.2];
        subCnt = 1; subplot(nR, nC, subCnt); hold off;
        plot([bg, pat0, bg], 'r', 'LineWidth', lnWdth);
        axis([0 maxX, minY, maxY]); title('i', 'fontsize', fntSz);

        subCnt = subCnt+1; subplot(nR, nC, subCnt); 
        plot([bg*ones(1, bgL), pat1, bg*ones(1, bgL)], 'color', gray, 'LineWidth', lnWdth); 
        axis([0 maxX, minY, maxY]); title('ii', 'fontsize', fntSz);

        subCnt = subCnt+1; subplot(nR, nC, subCnt); 
        plot([bg*ones(1, bgL), pat2, bg*ones(1, bgL)], 'color', gray, 'LineWidth', lnWdth); 
        axis([0 maxX, minY, maxY]); title('iii', 'fontsize', fntSz);

        subCnt = subCnt+1; subplot(nR, nC, subCnt); 
        plot(bg*ones(1, 3*bgL), 'color', gray, 'LineWidth', lnWdth); 
        axis([0 maxX, minY, maxY]); title('iv', 'fontsize', fntSz);
    end;

    D = cell(1, n);
    label = zeros(2, n);
    mus = cell(1, n);
    mu_alpha = 0;
    mu_beta = 1;
    for t=1:n
        idxs = randi(2, [1,3]); % which of pat1, pat2 to use?
        pat0_pos = randi(3); % is the pat in the left, center, right of two of {pat1, pat2}?
        idxs(pat0_pos) = 3;
        segs = cell(1, 7);
        segs([2,4,6]) = pats(idxs);
        lb = cell(1, 7);
        lb([2,4,6]) = masks(idxs);
        for i=1:4
            l_i = randi([2*baseL, baseL*3]);
            segs{2*i-1} = bg*ones(1, l_i);
            lb{2*i-1} = zeros(1, l_i);
        end;
        D{t} = cat(2, segs{:});
        lb = cat(2, lb{:});
        lb = find(lb); 
        label(:,t) = [lb(1), lb(end)];
        mus{t} = m_func_mu(length(D{t}), label(:,t), mu_alpha, mu_beta);
    end;

    d = nBin + 1;
    Ds = cell(1,n);
    for i=1:n
        Ds{i} = zeros(d, length(D{i}));
        linIdxs = sub2ind(size(Ds{i}), D{i}+ 1, 1:length(D{i}));
        Ds{i}(linIdxs) = 1;
    end;
        