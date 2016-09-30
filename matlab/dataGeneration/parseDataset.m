function [data, gt, gtE] = parseDataset(opt)
% parse data set

if strcmp(opt.dataset, 'MAD')
    [data, gt, gtE] = parseMAD(opt);
end

end