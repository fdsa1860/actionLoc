
function [Jbld,G_reg,G_norm,H,h] = JbldValue_New(Data)

 dt = 2;%shifting frame
 FrameNum = size(Data,2);
 if mod(FrameNum, dt)==0
     fr = 16; %window size
 else
     fr = 15; %window size
 end

R = 4; % R rows fixed when forming hankel matrix

h = cell(1,FrameNum-fr); %All windows which are going to form the hankel matrix
for i = 1 : dt : FrameNum-fr+1
    h{1,i} = Data(:,i:i+fr-1);
end
 emptyCells = cellfun('isempty', h); 
 h(emptyCells) = [];

 H = cell(1,(FrameNum-fr)/dt); % same size as h 
 
G = cell(1,size(h,2));
G_norm = cell(1,size(h,2));
G_reg = cell(1,size(h,2));

for i = 1 : size(h,2)
    
    H{1,i} = hankel_rowfixed(h{1,i},R);
    
    G{1,i} = H{1,i}*H{1,i}';% G./det(G)
    
    G_norm{1,i} = G{1,i}/norm(G{1,i},'fro');
    
    resdue = (1e-4)*eye(size(G{1,1}));
        %     
    G_reg{1,i} = G_norm{1,i} + resdue;

end

Jbld = zeros(size(G_reg,2)-1,1);

for j = 1 : size(Jbld,1)
    Jbld(j,1) = JBLD(G_reg{j+1},G_reg{j}); %JBLD(G1,G2);
    
end
end
