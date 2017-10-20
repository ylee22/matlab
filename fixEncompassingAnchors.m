function [ anchor_coords, anchor_trajs ] = fixEncompassingAnchors( anchor_coords, anchor_trajs )
% Check to see if one anchor is in the other

for i = 1:numel(anchor_trajs)
    curr_anchor = anchor_coords(i, :);
    other_anchors = anchor_coords;
    other_anchors(i, :) = curr_anchor*-1;
    
    % distance between current anchor and the rest of the anchors
    dist = pdist2(curr_anchor(2:3), other_anchors(:, 2:3));
    
    % find overlapping
    overlap_idx = dist < curr_anchor(1)*.8;
    
    if sum(overlap_idx) > 0
        % add the trajectory and remove the anchor
        anchor_trajs{i} = [anchor_trajs{i} anchor_trajs{overlap_idx}];
        overlap_idx = find(overlap_idx==1);
        for j = 1:numel(overlap_idx)
            anchor_trajs{overlap_idx(j)} = [];
        end
    end

end

anchor_coords = anchor_coords(~cellfun(@isempty, anchor_trajs), :);
anchor_trajs = anchor_trajs(~cellfun(@isempty, anchor_trajs));
end
