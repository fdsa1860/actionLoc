function W = findJointWeight2(data, label, opt)

nJoint = 20;
N = length(data);
% compute positive distance matrix
G = cell(nJoint, N);
for i = 1:N
    seq = data{i};
    for j = 1:nJoint
        jointSeq = seq(3*(j-1)+1:3*j, :);
        G{j, i} = getGram(jointSeq, opt);
    end
end

D = zeros(N, N, nJoint);
for j = 1:nJoint
    D(:, :, j) = HHdist(G(j, :), [], opt);
end

uniLabel = unique(label);
nAction = length(uniLabel);
W = zeros(nAction, nJoint);
for sel = 1:nAction
    
    indPos = find(label == sel);
    indNeg = find(label ~= sel);
    nPos = length(indPos);
    nNeg = length(indNeg);
    
    yp = ones(nPos*(nPos-1)/2, 1);
    Xp = zeros(nPos*(nPos-1)/2, nJoint);
    count = 1;
    for i = 1:length(indPos)
        for j = i+1:length(indPos)
            Xp(count, :) = reshape(D(indPos(i), indPos(j), :), 1, []);
            count = count + 1;
        end
    end
    
    yn = -ones(nPos*nNeg, 1);
    Xn = zeros(nPos*nNeg, nJoint);
    count = 1;
    for i = 1:length(indPos)
        for j = 1:length(indNeg)
            Xn(count, :) = reshape(D(indPos(i), indNeg(j), :), 1, []);
            count = count + 1;
        end
    end
    
    y = [yp; yn];
    X = [Xp; Xn];
    
    model = train(y, sparse(X), '-s 5 -c 10 -q');
    w = model.w;
    w = abs(w);
    w = w / sum(w);
    W(sel, :) = w;
end

imagesc(W);colorbar;

% y = zeros(N*(N-1)/2, 1);
% X = zeros(N*(N-1)/2, nJoint);
% count = 1;
% for i = 1:N
%     for j = i+1:N
%         y(count) = 2 * double(label(i)==label(j)) - 1;
%         X(count, :) = reshape(D(i, j, :), 1, []);
%         count = count + 1;
%     end
% end

% model = train(y, sparse(X), '-s 5 -c 1');

% lambda = 1;
% cvx_begin
% cvx_solver mosek
%     variables w(nJoint, 1)
%     variables epsilon(N*(N-1)/2, 1)
%     count = 1;
%     for i = 1:N
%         for j = i+1:N
%             y = 2 * double(label(i)==label(j)) - 1;
%             x = reshape(D(i, j, :), [], 1);
%             y * (w.' * x) >= 1 - epsilon(count);
%             count = count + 1;
%         end
%     end
%     obj = norm(w, 1) + lambda * sum(epsilon);
%     minimize(obj);
% cvx_end



end