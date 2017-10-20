function first_anchored_frame = FirstAnchoredFrame( anchor_coords, anchor_trajs, finalTrajmin5 )
% input: anchor coords and the corresponding anchored trajs

% find anchor with multiple trajs
mult_idx = cellfun(@(x) numel(x)>1, anchor_trajs);

mult_anchors = anchor_coords(mult_idx,:);
mult_trajs = anchor_trajs(mult_idx);

% holds the first frame inside of the anchor for anchored trajs
first_anchored_frame = cell(1, sum(mult_idx));

% find which frames are inside by distance
for i = 1:length(mult_trajs)
    curr_anchor = mult_anchors(i, :);
    trajs = mult_trajs{i};
    temp_duration = zeros(length(trajs), 2);
    anchor_radius = curr_anchor(1);
    for j = 1:length(trajs)
        curr_traj = trajs(j);
        inside = pdist2(curr_anchor(2:3), finalTrajmin5{curr_traj}(:, 1:2)) <= anchor_radius;
        temp_duration(j,:) = [min(finalTrajmin5{curr_traj}(inside, end-2)) max(finalTrajmin5{curr_traj}(inside, end-2))];
    end
    first_anchored_frame{i} = temp_duration;
end


end

