function [data, gt, gtE] = parseMAD(opt)

dataPath = opt.dataPath;

nSub = 20;
nSeq = 2;
data = cell(nSub*nSeq, 1);
gt = cell(nSub*nSeq, 1);
gtE = cell(nSub*nSeq, 1);

index = reshape(1:60, 20, 3);
index = index';
index = index(:);

for i = 1:nSub
    subName = sprintf('sub%02d', i);
    for j = 1:nSeq
        skeletonFileName = sprintf('seq%02d_sk.mat',j);
        labelFileName = sprintf('seq%02d_label.mat',j);
         load(fullfile(dataPath, subName, skeletonFileName));
         M = cell2mat(skeleton);
         M = reshape(M, 60, []);
         M = M(index, :);
         data{(i-1)*nSeq+j} = M;
         load(fullfile(dataPath, subName, labelFileName));
         % note the inconsistency of label file in sub 20 seq 1
         if i==20 && j==1, label(end, 3) = 6504; end % correct inconsistency
         label2 = zeros(size(label,1), 4);
         temp = label(:, 1);
         temp(temp > 35) = 36;
         label2(:, 1) = temp;
         label2(:, 2) = label(:,3)-label(:,2)+1;
         label2(:, 3:4) = label(:, 4:5);
         gtE{(i-1)*nSeq+j} = label2;
         frame_label = labelConv([label2(:,1) label(:,3)-label(:,2)+1]);
         gt{(i-1)*nSeq+j} = frame_label;
    end
end

end