function w = findJointWeight(data, opt)

nJoint = 20;
% compute positive distance matrix
GG = cell(1, length(data));
for i = 1:length(data)
    class = data{i};
    G = cell(nJoint, length(class));
    for j = 1:length(class)
        seq = class{j};
        for k = 1:nJoint
            jointSeq = seq(3*(k-1)+1:3*k, :);
            G{k, j} = getGram(jointSeq, opt);
        end
    end
    GG{i} = G;
end

wp = zeros(nJoint, length(GG));
for i = 1:length(GG)
    G = GG{i};
    m = size(G, 2);
    n = (m-1)*m/2;
    K = zeros(nJoint, n);
    for j = 1:nJoint
        D = HHdist(G(j, :), [], opt);
        trilInd = tril(true(size(D)), -1);
        K(j,:) = D(trilInd);
    end
    wp(:, i) = mean(K, 2);
end

wn = zeros(nJoint, length(GG));
for i = 1:length(GG)
    G1 = GG{i};
    m1 = size(G1, 2);
    for j = 1:length(GG)
        if j == i, continue; end
        G2 = GG{j};
        m2 = size(G2, 2);
        n = m1 * m2;
        K = zeros(nJoint, n);
        for k = 1:nJoint
            D = HHdist(G1(k, :), G2(k, :), opt);
            K(k,:) = D(:)';
        end
        wn(:, i) = (wn(:, i) * (j-1) + mean(K, 2)) / j;
    end
end

w = wp - wn;

55

end