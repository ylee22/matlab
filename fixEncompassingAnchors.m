function [ anchor_coords, anchor_trajs ] = fixEncompassingAnchors( anchor_coords, anchor_trajs )
% Check to see if one anchor is in the other

for i = 1:numel(anchor_trajs)
    curr_anchor = anchor_coords(i, :);
    other_anchors = anchor_coords;
    other_anchors(i, :) = curr_anchor*-1;
    
    % distance between current anchor and the rest of the anchors
    dist = pdist2(curr_anchor(2:3), other_anchors(:, 2:3));
    
    % find overlapping
    overlap_idx = dist < curr_anchor(1);
    
    if sum(overlap_idx) > 0
        % calculate overlapping area
        d = dist(overlap_idx);
        r2 = curr_anchor(1);
        r1 = other_anchors(overlap_idx, 1);
        A = (d^2 + r1^2 - r2^2) / (2 * d * r1);
        B = (d^2 + r2^2 - r1^2) / (2 * d * r2);
        C = (-d + r1 + r2) * (d + r1 - r2) * (d - r1 + r2) * (d + r1 + r2);
        area = r1^2*acos(A) + r2^2*acos(B) - 1/2*sqrt(C);

        % if the overlapping area is a certain fraction of the total
        % smaller anchor area
        if area/(pi*r1^2) > 0.75
            % add the trajectory and remove the anchor
            anchor_trajs{i} = [anchor_trajs{i} anchor_trajs{overlap_idx}];
            overlap_idx = find(overlap_idx==1);
            for j = 1:numel(overlap_idx)
                anchor_trajs{overlap_idx(j)} = [];
            end
        end
    end

end

anchor_coords = anchor_coords(~cellfun(@isempty, anchor_trajs), :);
anchor_trajs = anchor_trajs(~cellfun(@isempty, anchor_trajs));
end
