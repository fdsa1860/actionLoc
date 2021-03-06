
function [G, H] = getGram(t, opt)
% created by Xikang Zhang on 09/29/2016
% get Gram matrix of one skeleton sequence

s = size(t);

if ~exist('opt','var')
    opt.H_structure = 'HHt';
    opt.metric = 'JBLD';
end

if strcmp(opt.H_structure,'HtH')
    Hsize = opt.H_rows;
    nc = Hsize;
    nr = size(t,1)*(size(t,2)-nc+1);
    if nr<1, error('hankel size is too large.\n'); end
    Ht = blockHankel(t,[nr nc]);
    HHt = Ht' * Ht;
elseif strcmp(opt.H_structure,'HHt')
    Hsize = opt.H_rows * s(1);
    nr = floor(Hsize/size(t,1))*size(t,1);
    nc = size(t,2)-floor(nr/size(t,1))+1;
    if nc<1, error('hankel size is too large.\n'); end
    Ht = blockHankel(t,[nr nc]);
    HHt = Ht * Ht';
end
HHt = HHt / (norm(HHt,'fro') + eps);
if strcmp(opt.metric,'JBLD') || strcmp(opt.metric,'JBLD_denoise') ...
        || strcmp(opt.metric,'JBLD_XYX') || strcmp(opt.metric,'JBLD_XYY') ...
        || strcmp(opt.metric,'AIRM') || strcmp(opt.metric,'LERM')...
        || strcmp(opt.metric,'KLDM')
    I = opt.sigma*eye(size(HHt));
    G = HHt + I;
elseif strcmp(opt.metric,'binlong') || strcmp(opt.metric,'SubspaceAngle') ||...
        strcmp(opt.metric,'SubspaceAngleFast')
    G = HHt;
end
if nargout > 1
    H = Ht;
end

end