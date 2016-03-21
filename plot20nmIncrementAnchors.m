function plot20nmIncrementAnchors( totalTraj, immobileSpots, anchor_coord )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

figure

% Plot all the trajectories
for i=1:length(totalTraj)
%     color=rand(1,3);
    plot(totalTraj{i}(:,1),totalTraj{i}(:,2),'Color',[0.7 0.7 0.7],'LineWidth',0.25);
    hold on;
    for j=1:size(totalTraj{i},1)      
        if j < size(totalTraj{i},1) && pdist(totalTraj{i}(j:j+1,1:2)) <= 20
           plot(totalTraj{i}(j:j+1,1),totalTraj{i}(j:j+1,2),'r','LineWidth',5)
           hold on;
        end
    end
end
% 
% scatter(immobileSpots(:,1),immobileSpots(:,2),'.')
% hold on;

% Plot anchored trajectories
% for z=1:length(anchoredTraj)
%     for i=1:length(anchoredTraj{z})
%         for j=1:length(anchoredTraj{z}{i})
%             color=rand(1,3);
%             plot(totalTraj{anchoredTraj{z}{i}(j)}(:,1),totalTraj{anchoredTraj{z}{i}(j)}(:,2),'Color',color);
% %             text(totalTraj{anchoredTraj{z}{i}(j)}(1,1),totalTraj{anchoredTraj{z}{i}(j)}(1,2),int2str([z,i]))
%     %         text(totalTraj{anchoredTraj{i}(j)}(1,1),totalTraj{anchoredTraj{i}(j)}(1,2),int2str(totalTraj{anchoredTraj{i}(j)}(1,6)),'FontSize',8,'Color',color)
%     %         text(totalTraj{anchoredTraj{i}(j)}(end,1),totalTraj{anchoredTraj{i}(j)}(end,2),int2str(totalTraj{anchoredTraj{i}(j)}(1,7)),'FontSize',8,'Color',color)
%             hold on;
%         end
%     end
% end

% Draw anchors
ang=0:0.01:2*pi;
for a=1:length(anchor_coord)
    anchor_radius=20*a;
    xp=anchor_radius*cos(ang);
    yp=anchor_radius*sin(ang);
    for i=1:size(anchor_coord{a},1)
        plot(anchor_coord{a}(i,1)+xp,anchor_coord{a}(i,2)+yp,'LineWidth',2,'Color','k');
        hold on;
    end
end

axis image

end

