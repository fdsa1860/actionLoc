function Gm = actionLoc_train(seqs_train, gtE_train, opt)

% get data segments for training
nTrain = length(seqs_train);
ts = cell(opt.nAction, 1);
for i = 1:nTrain
    currSeq = seqs_train{i};
    currGt = gtE_train{i};
    index = 1;
    for j = 1:size(currGt, 1)
        id = currGt(j, 1);
        dur = currGt(j, 2);
        if opt.diff == true && j == 1
            dur = dur - 1;
        end
        if dur >= opt.minLength
            ts{id}{end+1} = currSeq(:, index:index+dur-1);
        end
        index = index + dur;
    end
%     for j = 1:nAction
%         segInd = find(currGt == j);
%         if isempty(segInd)
%             X{i, j} = [];
%         elseif invalidSeg(segInd) % if there are more than one segment
%             idx = find(diff(segInd,2), 1); % find the first segment
%             X{i, j} = currSeq(:, segInd(1:idx+1));
%         else
%             X{i, j} = currSeq(:, segInd);
%         end
%     end
end

% get Gram matrices for each segment
G = cell(length(ts), 1);
% H = cell(length(ts), 1);
for i = 1:length(ts)
    [G{i}] = getGram_batch(ts{i}, opt);
end
% get means Gram matrices from each class
Gm = cell(length(G), 1);
for i = 1:length(G)
    Gm{i} = gramMean(G{i}, opt);
end