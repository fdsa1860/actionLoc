function [Jbld, SOS_score, Outlier,Joint_Frm] = OutlierDet(np,fram , Data)
% np : number of parts(joints)
% fram: frame numbers
%Joint_Frm : 1xnp cell, each cell:one joint position over entire frame
             %length

Joint1_frm = zeros(2,fram);
Joint_Frm = cell(1,np);
 for m = 1 : np

for i = 1 : fram
    
    Joint1_frm(:,i) = (Data{1,i}(m,:))';
    
    
end

    Joint_Frm{1,m} = Joint1_frm;
 end 
% end
%% Jbld Value & SOS score
order = 2; %Moment order
dim = 1;
Outlier = cell(1,np);
Jbld = cell(1,np);
SOS_score = cell(1,np);
thres = nchoosek(order+dim, order);

for n = 1 : np
    
    Jbld{1,n} = JbldValue_New(Joint_Frm{1,n});
    
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
   Outlier{1,n} = ind;
     
end
end
