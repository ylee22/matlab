function plotAnchorsandRAFs( anchor_radius_coord, RAF_final_traj )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

figure

% Draw anchors
ang=0:0.01:2*pi;
for i=1:length(anchor_radius_coord)
    xp=anchor_radius_coord(i,1)*cos(ang);
    yp=anchor_radius_coord(i,1)*sin(ang);
    plot(anchor_radius_coord(i,2)+xp,anchor_radius_coord(i,3)+yp,'LineWidth',2,'Color','k');
    hold on;
end

% Draw RAF on top of the anchors
for i=1:length(RAF_final_traj)
    color=rand(1,3);
    plot(RAF_final_traj{i}(:,1),RAF_final_traj{i}(:,2),'Color',color);
    hold on;
end

axis image

end

