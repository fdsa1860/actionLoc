function mu = m_func_mu(len, y, alpha, beta)
% Function for slack variable rescaling. 
% len: len of the signal, y = [start, end] of the event
% This is a piece-wise linear function.
% alpha, beta: 0 <= alpha < beta <= 1
% alpha is the proportion of the first part of [start, end] to be 0, 
% 1-beta is the proportion of the end part of [start, end] to be 1.
% By Minh Hoai Nguyen (minhhoai@gmail.com)
% Last modified: 3 June 12

s = y(1);
e = y(2);

if (s <= 0) || (s > e)
    mu = ones(1, len);
    return;
end;

bf = ones(1, s-1);
m1 = floor(alpha*(e-s));
m2 = ceil(beta*(e-s));
if m2 == m1
    mid = [zeros(1, m1), ones(1, e-s - m2)];
elseif m2 - m1 == 1
    mid = [zeros(1, m1), 0.5, ones(1, e-s - m2)];
else
    mid = [zeros(1, m1), (0:(m2-m1-1))/(m2-m1-1), ones(1, e-s - m2)];
end

af = ones(1, len - e + 1);
mu = [bf, mid, af];
