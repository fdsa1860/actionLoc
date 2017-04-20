function [Jbld, SOS_score, Outlier,Joint_Frm] = OutlierDet2(data)
% np : number of parts(joints)
% fram: frame numbers
%Joint_Frm : 1xnp cell, each cell:one joint position over entire frame
%length

d = size(data, 1);
nFrame = size(data, 2);
assert(mod(d, 2)==0);
np = d / 2;
% fram = n;
Joint_Frm = cell(1, np);
for i = 1:np
    Joint_Frm{i} = data(2*(i-1)+1:2*i, :);
end
             
% Joint1_frm = zeros(2,fram);
% Joint_Frm = cell(1,np);
%  for m = 1 : np
% 
% for i = 1 : fram
%     
%     Joint1_frm(:,i) = (data{1,i}(m,:))';
%     
%     
% end
% 
%     Joint_Frm{1,m} = Joint1_frm;
%  end 
% end
%% Jbld Value & SOS score
order = 2; %Moment order
dim = 1;
Outlier = cell(1,np);
Jbld = cell(1,np);
SOS_score = cell(1,np);
thres = nchoosek(order+dim, order);
% thres = 3;

opt.dt = 2;%shifting frame
if mod(nFrame, opt.dt)==0
    opt.fr = 10; %window size
else
    opt.fr = 9; %window size
end

for n = 1 : np
    
%     Jbld{1,n} = JbldValue_New(Joint_Frm{1,n});
    Jbld{1,n} = JbldValue(Joint_Frm{1,n}, opt);
    
     [M,basis] = SOStrain(Jbld{1,n}, order, dim);

     SOS_score{1,n} = SOStest(Jbld{1,n}, M, basis);    
  
%     figure(1)
%      plot(Jbld{1,n},'-*'),hold on
%      title('JBLD');
%      figure(2)
%      plot(score{1,n},'-*'),hold on
%      title('SOS');

%Threshold value
   score = SOS_score{1,n};
%   Outlier{1,n} = score(find(score > thres));
   ind = find(score>thres);
   ithFram1 = [];
   ithFram2 = [];
   for k = 1:opt.dt
       ithFram1 = [ithFram1; ind*opt.dt+opt.fr-k+1]; % the frame when outlier occured
       ithFram2 = [ithFram2; ind*opt.dt-k+1]; % the frame when outlier occured
   end
%    ithFram(ithFram>nFrame) = [];
   Outlier{1,n} = intersect(ithFram1,ithFram2);
     
end
end
