function [data, gt, output3] = parseDataset(opt)
% parse data set

if strcmp(opt.dataset, 'MAD')
    [data, gt, output3] = parseMAD(opt);
elseif strcmp(opt.dataset, 'activitynet');
    [data, gt, output3] = parseActivityNet(opt);
end

end