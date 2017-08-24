function plotVariableAnchorSizes( traj1, anchor_coord1 )
%UNTITLED10 Summary of this function goes here
%   Detailed explanation goes here

figure
% Plot all the trajectories
for i=1:length(traj1)
%     plot(traj1{i}(:,1),traj1{i}(:,2),'Color','b')
    plot(traj1{i}(:,1),traj1{i}(:,2),'Color',rand(1,3))
    hold on;
%     for j=1:size(totalTraj{i},1)-1
%         if pdist2(totalTraj{i}(j,1:2),totalTraj{i}(j+1,1:2))<25
%             plot(totalTraj{i}(j:j+1,1),totalTraj{i}(j:j+1,2),'k','LineWidth',5)
% %             text(totalTraj{i}(j,1),totalTraj{i}(j,2),int2str(i),'FontSize',8,'Color','b')
%             hold on;
%         end
%     end
end

% Draw anchors
ang=0:0.01:2*pi;
for j=1:size(anchor_coord1, 1)
    anchor_radius=anchor_coord1(j,1);
    xp=anchor_radius*cos(ang);
    yp=anchor_radius*sin(ang);
    
    plot(anchor_coord1(j,2)+xp,anchor_coord1(j,3)+yp,'LineWidth',2,'Color','k');
    
%     if anchor_coord1(j,5) > 0
%         plot(anchor_coord1(j,2)+xp,anchor_coord1(j,3)+yp,'LineWidth',2,'Color','b');
%     elseif anchor_coord1(j,5) == 0
%         plot(anchor_coord1(j,2)+xp,anchor_coord1(j,3)+yp,'LineWidth',2,'Color','k');
%     elseif anchor_coord1(j,5) < 0
%         plot(anchor_coord1(j,2)+xp,anchor_coord1(j,3)+yp,'LineWidth',2,'Color','r');
%     end
    hold on;
end

% for b=1:length(traj2)
%     plot(traj2{b}(:,1),traj2{b}(:,2),'Color',[0.7 0.7 0.7],'LineWidth',0.5)
%     hold on;
% end
% 
% for a=1:size(anchor_coord2,1)
%     anchor_radius=anchor_coord2(a,1);
%     xp=anchor_radius*cos(ang);
%     yp=anchor_radius*sin(ang);
%     plot(anchor_coord2(a,2)+xp,anchor_coord2(a,3)+yp,'LineWidth',2,'Color','r');
%     hold on;
% end

axis image

end

