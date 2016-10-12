function [Gs, Hs] = getGram_batch(ts, opt)
% created by Xikang Zhang on 09/29/2016
% get Gram matrices from a batch of sequences

Gs = cell(length(ts), 1);
Hs = cell(length(ts), 1);
for i = 1:length(ts)
    [Gs{i}, Hs{i}] = getGram(ts{i}, opt);
end

end