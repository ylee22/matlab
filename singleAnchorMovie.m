function [ movie_frame ] = singleAnchorMovie( totalTraj, anchoredTraj, anchor_radius, anchor_coord )
% Makes a movie for a single anchor
%   anchoredTraj: all of the trajectories in this anchor (must be row IDs
%   for totalTraj
%   totalTraj: finalTraj from the vbSPT output (the cell array containing
%   all of the trajectories for the movie)
figure

% calculate the x and y limits for the movie
all_coords = [];
for index = 1:length(anchoredTraj)
    all_coords = cat(1,all_coords,totalTraj{anchoredTraj(index)});    
end
max_x = max(all_coords(:,1));
min_x = min(all_coords(:,1));
max_y = max(all_coords(:,2));
min_y = min(all_coords(:,2));

% Draw the anchor
ang=0:0.01:2*pi;
xp=anchor_radius*cos(ang)+anchor_coord(1);
yp=anchor_radius*sin(ang)+anchor_coord(2);
plot(xp,yp,'LineWidth',2,'Color','k')

xlabel('First and last frame numbers for each trajectory (20 ms frame rate)')

hold on;

out_of_bounds_x = max([abs(max_x-max(xp)),abs(min_x-min(xp))]);
out_of_bounds_y = max([abs(max_y-max(yp)),abs(min_y-min(yp))]);

xlim([min(xp)-out_of_bounds_x*1.05 max(xp)+100]);
ylim([min(yp)-out_of_bounds_y*1.05 max(yp)+200]);

% Acquire movie
tot_frames=0;
for a=1:length(anchoredTraj)
    tot_frames=tot_frames+size(totalTraj{anchoredTraj(a)},1)-1;
end
movie_frame(1:tot_frames) = struct('cdata',[],'colormap',[]);
mov_frame_idx = 0;

for i=1:length(anchoredTraj)
    color=rand(1,3);
    currentTraj=totalTraj{anchoredTraj(i)};
    for j=1:size(currentTraj,1)-1
        mov_frame_idx=mov_frame_idx+1;
        plot(currentTraj(j:j+1,1),currentTraj(j:j+1,2),'Color',color);
        if j==1
            text(currentTraj(1,1),currentTraj(1,2),int2str(totalTraj{anchoredTraj(i)}(1,6)),'FontSize',8,'Color',color)
        elseif j==size(currentTraj,1)-1
            text(currentTraj(end,1),currentTraj(end,2),int2str(totalTraj{anchoredTraj(i)}(1,7)),'FontSize',8,'Color',color)
        end
        drawnow;
        movie_frame(mov_frame_idx)=getframe(gcf);
    end
end

end

% Use movie2avi function to convert the images to an avi file
