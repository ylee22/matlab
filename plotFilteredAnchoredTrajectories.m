function plotFilteredAnchoredTrajectories( totalTraj, anchored_traj, anchor_radius_coord )
%UNTITLED2 Summary of this function goes here
%   This function was written after anchor radius and coordinate were
%   stored in one variable

figure

% Plot anchored trajectories
for i=1:length(anchored_traj)
    color=rand(1,3);
    plot(totalTraj{anchored_traj(i)}(:,1),totalTraj{anchored_traj(i)}(:,2),'Color',color);
    hold on;
end

% Draw anchors
% ang=0:0.01:2*pi;
% for i=1:length(anchor_radius_coord)
%     xp=anchor_radius_coord(i,1)*cos(ang);
%     yp=anchor_radius_coord(i,1)*sin(ang);
%     plot(anchor_radius_coord(i,2)+xp,anchor_radius_coord(i,3)+yp,'LineWidth',2,'Color','k');
%     text(anchor_radius_coord(i,2),anchor_radius_coord(i,3),int2str(i),'FontSize',10)
%     hold on;
% end
axis image

end