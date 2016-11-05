function m_demo_asl()
% Experiment on Australian Sign Language
% This run HMM-based and SVM-based detectors and plot the results.
% Fully tested, fully working code
% By: Minh Hoai Nguyen (minhhoai@cmu.edu)
% Date: 10 May 2011

%addpath('../bin/');
%addpath(genpath('/Users/hoai/Study/Libs/HMMall/')); % HMM implementation
load ../data/ASL.mat D;
svmSaveFilePrefix = '../rslt/ASL';

woiIDs = [2, 45, 94]; % This corresponds to: I love you.
TrD  = D(:, 1: 15);   % first 15 examples of each signs are used for training
TstD = D(:, 16:27);   % last 12 eampls of each signs are used for testing.
nTrSeq  = 100; % no of training sequences
nTstSeq = 200; % no of testing sequences
bgSz_bf = 15;  % no of background words before the event of interest
bgSz_af = 15;  % no of background words after the event of itnerest
[trWordSeqs, trLbs]   = crtWordSeqs(TrD,  woiIDs, nTrSeq,  bgSz_bf, bgSz_af);
[tstWordSeqs, tstLbs] = crtWordSeqs(TstD, woiIDs, nTstSeq, bgSz_bf, bgSz_af);
trSens = cell(1, nTrSeq); % sentence of interest for training

for k=1:nTrSeq
    trSens{k} = trWordSeqs{k}(:, trLbs(1,k):trLbs(2,k));
end;

nRun = 10; % set number of runs, 10 is a good number for reliable average result
for runID=1:nRun
    startT = tic;
    fprintf('------------------------->Run %d\n', runID);
    % run SVM-based detectors and save results
    svmSaveFile = sprintf('%s_%02d.mat', svmSaveFilePrefix, runID);
    detect_SVM(trSens, trWordSeqs, trLbs, tstWordSeqs, tstLbs, svmSaveFile);
        
    fprintf('Run %d took %g\n', runID, toc(startT));
end;

% aggregate results and plot
aggregateRslt(nRun, svmSaveFilePrefix);

    
       
    
% do experiment for SVM-based detector
% trSens: a cell structure of sentences (or sequences) of interest
% trWordSeqs: training sequences
% tstWordSeqs: testing sequences
% runID: ID of the run, for saving result purpose    
function detect_SVM(trSens, trWordSeqs, trLbs, tstWordSeqs, tstLbs, saveFile)
    nState = 20;
    trSens = cat(2, trSens{:});
    [mu_gmm, Sigma_gmm, mixmat_gmm] = mixgauss_em(trSens(:,1:5:end), nState);
    tr  = crtTSData(trWordSeqs, trLbs, mu_gmm, Sigma_gmm, mixmat_gmm);
    tst = crtTSData(tstWordSeqs, tstLbs, mu_gmm, Sigma_gmm, mixmat_gmm);

    % kernel option
    kOpt.type = 6; % linear with length normalization
    kOpt.n = 0;
    kOpt.L = 0; 
    kOpt.featType = 0; % 0: for BoW, 1: for ordered-sampling
    kOpt.sd = 0;
    kOpt.nSegDiv = 2; % segment is divided into two subsegments

    % Constraint option
    cnstrOpt.minSegLen = 100;
    cnstrOpt.maxSegLen = intmax('int32');
    cnstrOpt.segStride  = 5;
    cnstrOpt.trEvStride = 5;
    cnstrOpt.shldCacheSegFeat  = 0;
    cnstrOpt.shldCacheTrEvFeat = 1;

    % Search option
    sOpt.minSegLen = 100;
    sOpt.maxSegLen = intmax('int32');
    sOpt.segStride = 5;

    C = 1;
    d = size(tr.Ds{1},1);
    fd = m_getFd(kOpt, d);
    figure(1); clf; nR = 1; nC = 2;
    cnt = 0;

    [w_trunc, b_trunc] = m_trnSegSVM(tr.Ds, tr.segLbs, kOpt, C, [0.5, 1], cnstrOpt, 10);
    [rocArea_trunc, xroc_trunc, yroc_trunc, xamoc_trunc, yamoc_trunc] = ...
        m_tstSegSVM(tst.Ds, tst.segLbs, kOpt, sOpt, w_trunc, b_trunc, 'AMOC-mean');
    fprintf('rocArea_Seg-[0.5,1]: %g\n', rocArea_trunc);
    subplot(nR,nC,1); plot(xroc_trunc, yroc_trunc, 'k', 'LineStyle','-.'); hold on;
    subplot(nR,nC,2); plot(xamoc_trunc, yamoc_trunc, 'k', 'LineStyle','-.'); hold on;
    cnt = cnt+1; legends{cnt} = sprintf('Seg-[0.5,1] %.2f', 100*rocArea_trunc);

    w_init = ones(fd, 1);
    startT = tic;
    [w_so, b_so] = m_mexMMED_ker(tr.Ds, tr.segLbs, C, tr.mus, w_init, ...
        kOpt, 'offline+extent', cnstrOpt);
    fprintf('training SOSVM took %g\n', toc(startT));
    [rocArea_so, xroc_so, yroc_so, xamoc_so, yamoc_so] = ...
        m_tstSegSVM(tst.Ds, tst.segLbs, kOpt, sOpt, w_so, b_so, 'AMOC-mean');
    fprintf('rocArea_SOSVM: %g\n', rocArea_so);
    subplot(nR,nC,1); plot(xroc_so, yroc_so, 'b', 'LineStyle','--'); 
    subplot(nR,nC,2); plot(xamoc_so, yamoc_so, 'b', 'LineStyle','--'); 
    cnt = cnt+1; legends{cnt} = sprintf('SOSVM %.2f', 100*rocArea_so);

    startT = tic;
    [w_instant, b_instant] = m_mexMMED_ker(tr.Ds, tr.segLbs, C, tr.mus, w_init, ...
        kOpt, 'instant+extent', cnstrOpt);
    fprintf('training MMED took %g\n', toc(startT));
    [rocArea_instant, xroc_instant, yroc_instant, xamoc_instant, yamoc_instant] = ...
        m_tstSegSVM(tst.Ds, tst.segLbs, kOpt, sOpt, w_instant, b_instant, 'AMOC-mean');
    fprintf('rocArea_MMED: %g\n', rocArea_instant);
    subplot(nR,nC,1); plot(xroc_instant, yroc_instant, 'r');
    subplot(nR,nC,2); plot(xamoc_instant, yamoc_instant, 'r');
    cnt = cnt+1; legends{cnt} = sprintf('MMED %.2f', 100*rocArea_instant);

    subplot(nR,nC,1); legend(legends{:}, 'Location', 'SouthEast'); title('ROC');
    subplot(nR,nC,2); legend(legends{:}); axis([0, 1, 0, 1]); title('AMOC');

    fprintf('ROC-area, Seg-[0.5,1]: %g, SOSVM: %g, MMED: %g\n', ...
        rocArea_trunc, rocArea_so, rocArea_instant);

    clear trWordSeqs tstWordSeqs tr tst mu_gmm Sigma_gmm mixmat_gmm nState;
    save(saveFile);

% Aggreate results of different runs and plot results    
function aggregateRslt(nRun, svmSaveFilePrefix)
    yamoc_seg = cell(1, nRun);
    yamoc_so = yamoc_seg;
    yamoc_trunc = yamoc_seg;
    yamoc_instant = yamoc_seg;
    
    rocArea_seg = zeros(1, nRun);
    rocArea_trunc = rocArea_seg;
    rocArea_so = rocArea_seg;
    rocArea_instant = rocArea_seg;

    for runID=1:nRun
        rslt = load(sprintf('%s_%02d.mat', svmSaveFilePrefix, runID));

        yamoc_trunc{runID} = rslt.yamoc_trunc;
        yamoc_so{runID} = rslt.yamoc_so;
        yamoc_instant{runID} = rslt.yamoc_instant;
        
        
        rocArea_trunc(runID) = rslt.rocArea_trunc;
        rocArea_so(runID) = rslt.rocArea_so;
        rocArea_instant(runID) = rslt.rocArea_instant;        
        
        xamoc = rslt.xamoc_instant;
    end;

    yamoc_trunc = mean(cat(2,yamoc_trunc{:}), 2);
    yamoc_so = mean(cat(2,yamoc_so{:}), 2);
    yamoc_instant = mean(cat(2,yamoc_instant{:}), 2);
    
    rocArea_trunc = mean(rocArea_trunc);
    rocArea_so = mean(rocArea_so);
    rocArea_instant = mean(rocArea_instant);

    lnWdth = 3; fntSz = 16;
    figure(100); clf;    
    plot(xamoc, yamoc_trunc, 'k', 'LineWidth', lnWdth, 'LineStyle','-.'); hold on;
    plot(xamoc, yamoc_so, 'b', 'LineWidth',lnWdth, 'LineStyle','--');
    plot(xamoc, yamoc_instant, 'r', 'LineWidth',lnWdth, 'LineStyle','-');
    legend('Seg-[0.5,1]', 'SOSVM', 'MMED', 'Location', 'NorthEast');
    xlabel('False Positive Rate', 'FontSize', fntSz); 
    ylabel('Normalized Time to Detect', 'FontSize', fntSz);
    set(gca, 'FontSize', fntSz);
    
    fprintf('ROC-area, Seg-[0.5,1]: %g, SOSVM: %g, MMED: %g\n', ...
        rocArea_trunc, rocArea_so, rocArea_instant);


% Create word sequences that contains a sentence of interest.    
% D{i,j}: for symbol i, session j.    
% woiIDs: IDs for the words to creat sentence of interest
% nSeq: number of sequence to generate
% bgSz: number of words in the backgrounds.
function [wordSeqs, lbs] = crtWordSeqs(D, woiIDs, nSeq, bgSz_bf, bgSz_af)
    [nSym, nSample] = size(D);
    wordSeqs = cell(1, nSeq);
    lbs = zeros(2, nSeq);
    D_fg = D(woiIDs, :); % foreground parts
    m = length(woiIDs); % length of the sentence of interest
    fgColIdxs = randi(nSample, [nSeq m]); % random sample IDs correspond to rows in woiIDs
    
    bgColIdxs_bf = randi(nSample, [nSeq bgSz_bf]);
    bgRowIdxs_bf = randi(size(D,1), [nSeq bgSz_bf]);

    bgColIdxs_af = randi(nSample, [nSeq bgSz_af]);
    bgRowIdxs_af = randi(size(D,1), [nSeq bgSz_af]);
    
    for k=1:nSeq
        fgIdxs = sub2ind(size(D_fg), 1:m, fgColIdxs(k,:));
        soi = cat(2, D_fg{fgIdxs});
        bgIdxs_bf = sub2ind(size(D), bgRowIdxs_bf(k,:), bgColIdxs_bf(k,:));
        bg_bf = cat(2, D{bgIdxs_bf});
        
        bgIdxs_af = sub2ind(size(D), bgRowIdxs_af(k,:), bgColIdxs_af(k,:));
        bg_af = cat(2, D{bgIdxs_af});
        
        lbs(:,k) = [size(bg_bf,2)+1, size(bg_bf,2) + size(soi, 2)];
        wordSeqs{k} = cat(2, bg_bf, soi, bg_af);
    end;
        

% Create time series data for SVM-based detectors
% From raw features, do soft-clustering using GMM, compute log-likelihood, retain
% the top three values and output it as frame-level feature vectors.
function tr = crtTSData(wordSeqs, lbs, mu, Sigma, mixmat)
    mu_alpha = 0.25;
    mu_beta  = 1;

    n = length(wordSeqs);
    tr.mus = cell(1, n);
    tr.Ds  = cell(1, n);
    tr.segLbs = lbs;
    
    d = length(mixmat);
    for i=1:n
        n_i = size(wordSeqs{i}, 2);
        tr.mus{i} = m_func_mu(n_i, lbs(:,i), mu_alpha, mu_beta);
        tr.Ds{i} = zeros(d, n_i);
        obslik = mixgauss_prob(wordSeqs{i}, mu, Sigma, mixmat);
                
        % retain the top three values
        prctileVals = prctile(obslik, (d-3)*100/d, 1);
        idxs = obslik > repmat(prctileVals, d, 1);
        tr.Ds{i}(idxs) = log(obslik(idxs));
    end;
