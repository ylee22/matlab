function plotTrajectories( traj1 )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

figure
for i=1:length(traj1)
    color=rand(1,3);
    plot(traj1{i}(1:end,1),traj1{i}(1:end,2),'Color',color);
%     text(totalTraj{i}(1,1),totalTraj{i}(1,2),int2str(i),'FontSize',20,'Color',color)
%     text(totalTraj{i}(1,1),totalTraj{i}(1,2),int2str(totalTraj{i}(1,5)),'FontSize',8,'Color',color)
    hold on;
%     for j=1:size(totalTraj{i},1)      
%         if j < size(totalTraj{i},1) && pdist(totalTraj{i}(j:j+1,1:2)) <= 20
%            plot(totalTraj{i}(j:j+1,1),totalTraj{i}(j:j+1,2),'k','LineWidth',5)
%            hold on;
%         end
%     end
end

% for j=1:length(traj2)
%     plot(traj2{j}(:,1),traj2{j}(:,2),'Color','r');
% end

axis image
end
