function show_skel_kinect(data)

% data is (num_joints x 3) x T 

% J=[20     1     2     1     8    10     2     9    11     3     4     7     7     5     6    14    15    16    17;
%     3     3     3     8    10    12     9    11    13     4     7     5     6    14    15    16    17    18    19];

SkeletonConnectionMap = [[1 2]; % Spine
                         [2 3];
                         [3 4];
                         [3 5]; %Left Hand
                         [5 6];
                         [6 7];
                         [7 8];
                         [3 9]; %Right Hand
                         [9 10];
                         [10 11];
                         [11 12];
                         [1 17]; % Right Leg
                         [17 18];
                         [18 19];
                         [19 20];
                         [1 13]; % Left Leg
                         [13 14];
                         [14 15];
                         [15 16]];
                     J = SkeletonConnectionMap';

x = data(1:3:end,:);
z = data(2:3:end,:);
y = data(3:3:end,:);

T = size(data,2);

clf;



for t=1:T
    plot3(x(:,t),y(:,t),z(:,t),'o');
    
    set(gca,'DataAspectRatio',[1 1 1]);
    axis([min(min(x)) max(max(x)) min(min(y)) max(max(y)) min(min(z)) max(max(z))]);
    for j=1:19
        c1=J(1,j);
        c2=J(2,j);
        line([x(c1,t) x(c2,t)], [y(c1,t) y(c2,t)], [z(c1,t) z(c2,t)]);
    end
view(100,30);
%     title([num2str(t) '/' num2str(T)]);
%     axis tight;
%     axis off;
    drawnow;
    pause(0.1);
    35;
end