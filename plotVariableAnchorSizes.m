function plotVariableAnchorSizes( totalTraj, anchor_coord )
%UNTITLED10 Summary of this function goes here
%   Detailed explanation goes here

figure
% Plot all the trajectories
for i=1:length(totalTraj)
    plot(totalTraj{i}(:,1),totalTraj{i}(:,2),'Color',rand(1,3))
    hold on;
    for j=1:size(totalTraj{i},1)-1
        if pdist2(totalTraj{i}(j,1:2),totalTraj{i}(j+1,1:2))<20
            plot(totalTraj{i}(j:j+1,1),totalTraj{i}(j:j+1,2),'k','LineWidth',5)
%             text(totalTraj{i}(j,1),totalTraj{i}(j,2),int2str(i),'FontSize',8,'Color','b')
            hold on;
        end
    end
end

% Draw anchors
ang=0:0.01:2*pi;
for j=1:length(anchor_coord)
    anchor_radius=anchor_coord(j,1);
    xp=anchor_radius*cos(ang);
    yp=anchor_radius*sin(ang);
    plot(anchor_coord(j,2)+xp,anchor_coord(j,3)+yp,'LineWidth',2,'Color','k');
%         text(anchor_coord{a}(i,1),anchor_coord{a}(i,2),int2str([a,i]),'FontSize',8,'Color','k')
    hold on;
end

axis image

end

