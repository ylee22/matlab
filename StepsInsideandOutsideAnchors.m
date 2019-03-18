function [ inside_steps, before_outside_steps, after_outside_steps, rest_before_outside_steps, rest_after_outside_steps ] = StepsInsideandOutsideAnchors( finalTrajmin5, anchor_trajs, anchor_coords, window )
% anchored_trajs: cell array, with each element containing individual
% trajectories (1: x, 2: y, 3: frame #)
% anchor_coords: matrix, each row is a unique anchor (1: radius, 2: x, 3:
% y)
% 1. loop through all the identified anchors
% 2. for each anchor, separate the segments that are inside vs outside
% 3. if it only left for 1 frame and came back inside, then it never left
% at all

inside_steps = [];
before_outside_steps = [];
after_outside_steps = [];
rest_before_outside_steps = [];
rest_after_outside_steps = [];

for i = 1:size(anchor_coords, 1)
    curr_anchor = anchor_coords(i, 1:3);
    corresponding_trajs = anchor_trajs{i};
    for j = 1:numel(corresponding_trajs)
        curr_traj = finalTrajmin5{corresponding_trajs(j)}(:, 1:3);
        
        % identify the coordinates inside of the anchor
        inside = pdist2(curr_anchor(2:3), curr_traj(:,1:2)) <= curr_anchor(1);
        
        % determine the first and the last frames
        first_frame = find(inside, 1);
        last_frame = find(inside, 1, 'last');
        
        temp_inside = sqrt( sum( diff( curr_traj(first_frame:last_frame, 1:2) ).^2, 2 ) );
        inside_steps = cat(1, inside_steps, temp_inside);
        
        if first_frame > 1
            before = max(first_frame - window, 1);
            outside_first_segment = sqrt( sum( diff( curr_traj(before:first_frame, 1:2) ).^2, 2 ) );
            before_outside_steps = cat(1, before_outside_steps, outside_first_segment);
            if before > 1
                temp_rest_before = sqrt( sum( diff( curr_traj(1:before, 1:2) ).^2, 2 ) );
                rest_before_outside_steps = cat(1, rest_before_outside_steps, temp_rest_before);
            end
        end
        
        if last_frame < size(curr_traj, 1)
            after = min(last_frame + window, size(curr_traj, 1));
            outside_second_segment = sqrt( sum( diff( curr_traj(last_frame:after, 1:2) ).^2, 2 ) );
            after_outside_steps = cat(1, after_outside_steps, outside_second_segment);
            if after < size(curr_traj, 1)
                temp_rest_after = sqrt( sum( diff( curr_traj(after:end, 1:2) ).^2, 2 ) );
                rest_after_outside_steps = cat(1, rest_after_outside_steps, temp_rest_after);
            end
        end
        
        clearvars temp_inside outside_first_segment outside_second_segment
                
    end    
end

end