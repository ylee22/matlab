function plotTrajDiffGradient( totalTraj, anchoredTraj, anchor_radius, anchor_coord )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

figure

% Max Displacement/Traj Length
maxDispperframe=[];
for i=1:length(totalTraj)
    maxDispperframe(end+1) = max(pdist(totalTraj{i}(:,1:2)))/size(totalTraj{i},1);
end

% Now each trajectory is linked to its diffusion rate
diffperTraj=[maxDispperframe',[1:length(totalTraj)]'];
% Sort by diffusion rate and add color gradient according to speed
diffperTraj=sortrows(diffperTraj);
color_gradient=[[1:length(maxDispperframe)]'/length(maxDispperframe),[1:length(maxDispperframe)]'/length(maxDispperframe),[1:length(maxDispperframe)]'/length(maxDispperframe)];
diffperTraj=[diffperTraj,color_gradient];
% Sort by the index number (2nd column) to match the order of the color to trajectories
diffperTraj_sorted=sortrows(diffperTraj,2);
color_gradient=diffperTraj_sorted(:,3:end)*0.9;

% Plot all the trajectories
for i=1:length(totalTraj)
    plot(totalTraj{i}(:,1),totalTraj{i}(:,2),'Color',color_gradient(i,:))
    hold on;
end

% % Plot anchored trajectories
% for i=1:length(anchoredTraj)
%     for j=1:length(anchoredTraj{i})
%         color=rand(1,3);
%         plot(totalTraj{anchoredTraj{i}(j)}(:,1),totalTraj{anchoredTraj{i}(j)}(:,2),'Color',color);
%         text(totalTraj{anchoredTraj{i}(j)}(1,1),totalTraj{anchoredTraj{i}(j)}(1,2),int2str(totalTraj{anchoredTraj{i}(j)}(1,6)),'FontSize',8,'Color',color)
%         text(totalTraj{anchoredTraj{i}(j)}(end,1),totalTraj{anchoredTraj{i}(j)}(end,2),int2str(totalTraj{anchoredTraj{i}(j)}(1,7)),'FontSize',8,'Color',color)
%         hold on;
%     end
% end

% Draw anchors
ang=0:0.01:2*pi;
xp=anchor_radius*cos(ang);
yp=anchor_radius*sin(ang);
for i=1:length(anchor_coord)
    plot(anchor_coord(i,1)+xp,anchor_coord(i,2)+yp,'LineWidth', 1,'Color','r');
    hold on;
end

axis image

colormap(diffperTraj(:,3:end)*0.9)
colorbar
caxis([min(maxDispperframe),max(maxDispperframe)])

end