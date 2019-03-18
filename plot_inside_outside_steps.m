function plot_inside_outside_steps( finalTrajmin5, anchor_trajs, anchor_coords, window )
% anchored_trajs: cell array, with each element containing individual
% trajectories (1: x, 2: y, 3: frame #)
% anchor_coords: matrix, each row is a unique anchor (1: radius, 2: x, 3:
% y)
% 1. loop through all the identified anchors
% 2. for each anchor, separate the segments that are inside vs outside

c = get(gca,'colororder');
% plot them in the following order: free (state 3), intermediate (state 2),
% anchored (state 1) and intermediate gets line thickness 2
state_colors = [c(1:2,:); c(5,:)];

free_trajs = setdiff(1:numel(finalTrajmin5), [anchor_trajs{:}]);
free_trajs = finalTrajmin5(free_trajs);

for i=1:length(free_trajs)
    plot(free_trajs{i}(1:end,1),free_trajs{i}(1:end,2),'Color',state_colors(3,:));
    hold on
end

for i = 1:size(anchor_coords, 1)
    curr_anchor = anchor_coords(i, 1:3);
    corresponding_trajs = anchor_trajs{i};
    for j = 1:numel(corresponding_trajs)
        curr_traj = finalTrajmin5{corresponding_trajs(j)}(:, 1:3);
        
        % identify the coordinates inside of the anchor
        inside = pdist2(curr_anchor(2:3), curr_traj(:,1:2)) <= curr_anchor(1);
        
        % determine the first and the last frames inside of the anchor
        first_frame = find(inside, 1);
        last_frame = find(inside, 1, 'last');
        
        before = max(first_frame - window, 1);
        
        traj_end = size(curr_traj, 1);
        after = min(last_frame + window, traj_end);
        
        % color outside in green
        if before > 1
            plot(curr_traj(1:before, 1), curr_traj(1:before, 2), 'color', state_colors(3,:))
        end
        if after < traj_end
            plot(curr_traj(after:traj_end, 1), curr_traj(after:traj_end, 2), 'color', state_colors(3,:))
        end

        % color before and after in red
        if first_frame > before
            plot(curr_traj(before:first_frame, 1), curr_traj(before:first_frame, 2), 'color', state_colors(2,:), 'LineWidth', 2)
        end
        if last_frame < after
            plot(curr_traj(after:last_frame, 1), curr_traj(after:last_frame, 2), 'color', state_colors(2,:), 'LineWidth', 2)
        end

        % color anchored in blue
        plot(curr_traj(first_frame:last_frame, 1), curr_traj(first_frame:last_frame, 2), 'Color', state_colors(1,:), 'LineWidth', 2)
        
        clearvars temp_inside outside_first_segment outside_second_segment
                
    end    
end

axis equal

end