function Gs = getGram_batch(ts, opt)
% created by Xikang Zhang on 09/29/2016
% get Gram matrices from a batch of sequences

Gs = cell(1, length(ts));
for i = 1:length(ts)
    if ~isempty(ts{i})
        Gs{i} = getGram(ts{i}, opt);
    else
        Gs{i} = [];
    end
end

end