function update = Prediction_sliding(n1,n2,EndFrame,data)
% EndFrame: when given trajectory ends,length(trajectory)< fram, incomplet
            % trajectory
 
 
%  n1 = 20; % the number of data which is croped from the given data
%  n2 = 10; % the number of data which is going to be predicted

Omega = ones(1,n1+n2); 

lambda = 10;
Omega(:,n2) = 0;
up = zeros(2,n1+n2);

up(:,1:n1) = data(:,EndFrame-n1+1:EndFrame);

update = l2_fastalm_mo(up,lambda,'omega',Omega);

end