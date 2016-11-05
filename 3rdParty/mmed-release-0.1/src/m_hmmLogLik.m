function loglik = m_hmmLogLik(data, prior, transmat, mu, Sigma, mixmat)
% Simple log likelihood of GMM-HMM. Hidden states are not determined by Viterbi algo.,
% but by individual observation probability. The state transition probability, however,
% is used to calculate the final log-likelihood.

% data{m}(:,t) or data(:,t,m) if all cases have same length
% errors  is a list of the cases which received a loglik of -infinity
%
% Set mixmat to ones(Q,1) or omit it if there is only 1 mixture component

Q = length(prior);
if size(mixmat,1) ~= Q % trap old syntax
  error('mixmat should be QxM')
end
if nargin < 6, mixmat = ones(Q,1); end

if ~iscell(data)
  data = num2cell(data, [1 2]); % each elt of the 3rd dim gets its own cell
end
ncases = length(data);

loglik = 0;

for m=1:ncases
  obslik = mixgauss_prob(data{m}, mu, Sigma, mixmat);
%   [alpha, beta, gamma, ll2] = fwdback(prior, transmat, obslik, 'fwd_only', 1, 'maximize', 1);
  [ll, maxStateSeq] = cmpLogLik(prior, transmat, obslik, 1);
%   ll3 = cmpLogLik4Seq(prior, transmat, obslik, maxStateSeq);
%   [ll4, featVec4] = cmpHmmFeatVec(prior, transmat, obslik, maxStateSeq);
  
%   ll5 = cmpGmmFeatVec(prior, transmat, obslik);
  
  loglik = loglik + ll;
%   fprintf('ll: %g, ll - ll5: %g\n', ll, ll - ll5);
  
end


function [loglik, maxStateSeq] = cmpLogLik(prior, transmat, obslik, maximize)
% Inputs:
%   prior: prior probability for being initial state Q*1 vector, with Q number of states
%   transmat: transition probability between states Q*Q matrix
%   obslik: observation likelihodd Q*1 vector
%   maximize: 
%      0: compute the marginal log-likelihood
%      1: compute maximum log-likelihood
% Outputs:
%   loglik: log-lilihood 
%   maxStateSeq: only return valid sequence if maximize is set to 1. This is the sequence
%       of states that yield maximum log likelihood.


% scale(t) = Pr(O(t) | O(1:t-1)) = 1/c(t) as defined by Rabiner (1989).
% Hence prod_t scale(t) = Pr(O(1)) Pr(O(2)|O(1)) Pr(O(3) | O(1:2)) ... = Pr(O(1), ... ,O(T))
% or log P = sum_t log scale(t).
% Rabiner suggests multiplying beta(t) by scale(t), but we can instead
% normalise beta(t) - the constants will cancel when we compute gamma.


[Q T] = size(obslik);
scale = ones(1,T);
alpha = zeros(Q,T);
traceIdxs = zeros(Q, T);

t = 1;
alpha(:,1) = prior(:) .* obslik(:,t);
[alpha(:,t), scale(t)] = normalise(alpha(:,t));
for t=2:T
    trans = transmat;    
    if maximize
        [m, traceIdxs(:,t)] = max(trans.*repmat(alpha(:,t-1), 1, size(trans,2)), [], 1);
        m = m';
    else
        m = trans'*alpha(:,t-1);
    end
    alpha(:,t) = m(:) .* obslik(:,t);
    [alpha(:,t), scale(t)] = normalise(alpha(:,t));
end
if any(scale==0)
    loglik = -inf;
else
    loglik = sum(log(scale));
    if maximize
        loglik = loglik + log(max(alpha(:,T)));
    end
end

maxStateSeq = zeros(1, T);
if maximize
    [dc, maxStateSeq(T)] = max(alpha(:,T));
    for t=T:-1:2
        maxStateSeq(t-1) = traceIdxs(maxStateSeq(t), t);        
    end
end


function loglik = cmpLogLik4Seq(prior, transmat, obslik, stateSeq)
    T = length(stateSeq);
    loglik = log(prior(stateSeq(1))) + log(obslik(stateSeq(1),1));
    for t=2:T
        loglik = loglik + log(transmat(stateSeq(t-1), stateSeq(t))) ... 
            + log(obslik(stateSeq(t), t));
    end

    
function [loglik, featVec] = cmpHmmFeatVec(prior, transmat, obslik, stateSeq)
    [Q, T] = size(obslik);
    priorVec = zeros(Q,1);
    priorVec(stateSeq(1)) = log(prior(stateSeq(1)));
    obsVec = zeros(Q,1);
    obsVec(stateSeq(1)) = log(obslik(stateSeq(1),1));
    transVec = zeros(Q, Q);
    for t=2:T
        obsVec(stateSeq(t)) = obsVec(stateSeq(t)) + log(obslik(stateSeq(t), t));
        transVec(stateSeq(t-1), stateSeq(t)) = transVec(stateSeq(t-1), stateSeq(t)) + ...
            log(transmat(stateSeq(t-1), stateSeq(t)));
        
    end;
    featVec = cat(1, priorVec, obsVec, transVec(:));
    loglik = sum(featVec);
    
    
%     loglik = sum(sum(log(obslik)));

%     [loglik, featVec] = cmpHmmFeatVec(prior, transmat, obslik, stateSeq);