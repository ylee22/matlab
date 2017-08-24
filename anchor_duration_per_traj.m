function [ anchor_duration ] = anchor_duration_per_traj( anchor_trajs, anchor_coords, finalTrajmin5, multiple_traj_idx, timestep )
% Takes all anchors and all anchored trajs

anchor_duration = num2cell(anchor_coords(:,end)*timestep);
anchor_duration(multiple_traj_idx)={0};

% find which frames are inside by distance
for i = 1:length(multiple_traj_idx)
    curr_anchor = multiple_traj_idx(i);
    trajs = anchor_trajs{curr_anchor};
    temp_duration = zeros(1, length(trajs));
    for j = 1:length(trajs)
        curr_traj = trajs(j);
        anchor_radius = anchor_coords(curr_anchor, 1);
        inside = pdist2(anchor_coords(curr_anchor, 2:3), finalTrajmin5{curr_traj}(:, 1:2)) <= anchor_radius;
        temp_duration(j) = sum(inside)*timestep;
    end
    anchor_duration{curr_anchor} = temp_duration;
end

if sum(cellfun(@(x) numel(x)==1, anchor_duration(multiple_traj_idx))) ~= 0
    error('some anchors with multiple trajectories are getting missed')
end

end

