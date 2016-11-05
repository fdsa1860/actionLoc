function [data, gt, frameIndex] = parseConcurrentAction(opt)

if ~exist(fullfile('..', 'expData', 'concurrentAction_data.mat'), 'file')
    
    dataPath = opt.dataPath;
    
    skePath = fullfile(dataPath, 'sequence skeleton');
    labelPath = fullfile(dataPath, 'sequence label');
    
    nSeq = 61;
    nJoints = 20;
    dimSeq = nJoints * 3;
    
    data = cell(1, nSeq);
    frameIndex = cell(1, nSeq);
    for i = 1:nSeq
        seqName = sprintf('sequence_%03d', i);
        fileList = dir(fullfile(skePath, seqName, '*.txt'));
        seqLength = length(fileList);
        validInd = true(1, seqLength);
        seq_id = 0;
        seq = zeros(dimSeq, seqLength);
        frInd = zeros(1, seqLength);
        for j = 1:seqLength
            fid = fopen(fullfile(skePath, seqName, fileList(j).name));
            id = fscanf(fid, '%d\n', 1);
            if isempty(id)
                validInd(j) = false;
                fclose(fid);
                continue;
            end
            if seq_id == 0
                seq_id = id;
            end
            fseek(fid, 0, 'bof');
            terminate = false;
            while ~terminate
                id = fscanf(fid, '%d\n', 1);
                if isempty(id)
                    seq_id = pre_id;
                    break;
                end
                if id == seq_id
                    terminate = true;
                end
                raw = fscanf(fid, '%f,%f,%f,%d\n', [4, 20]);
                pre_id = id;
%                 if id == seq_id
%                     terminate = true;
%                 elseif isempty(id)
%                     validInd(j) = false;
%                     terminate = true;
%                 end
            end
            fclose(fid);
%             if ~validInd(j)
%                 continue;
%             end
            xyz = raw(1:3, :);
            seq(:, j) = xyz(:);
            frInd(j) = sscanf(fileList(j).name, 'frame_%d_*');
        end
        seq(:, ~validInd) = [];
        frInd(~validInd) = [];
        data{i} = seq;
        frameIndex{i} = frInd;
    end
    
    gt = cell(1, nSeq);
    for i = 1:nSeq
%         if i==20, keyboard; end
        count = 1;
        actions = struct('label',{}, 'segment', {});
        fileName = sprintf('sequence_%03d.txt', i);
        fid = fopen(fullfile(labelPath, fileName));
        while ~feof(fid)
            line = fgetl(fid);
            if isempty(line)
                continue;
            end
            s = sscanf(line, '%d');
            if isempty(s)
                currAction = sscanf(line, '%s');
            else
                actions(count).label = currAction;
                actions(count).segment(1) = find(frameIndex{i}>=s(1), 1, 'first');
                actions(count).segment(2) = find(frameIndex{i}<=s(2), 1, 'last');
                count = count + 1;
            end
        end
        fclose(fid);
        gt{i} = actions;
    end
    
    save(fullfile('..', 'expData', 'concurrentAction_data.mat'), 'data', 'gt', 'frameIndex');
    
else
    load(fullfile('..', 'expData', 'concurrentAction_data.mat'), 'data', 'gt', 'frameIndex');
end

end