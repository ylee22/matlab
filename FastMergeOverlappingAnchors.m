function [ anchor_coords, anchor_trajs ] = FastMergeOverlappingAnchors( pre_anchor_coords, pre_anchor_trajs, finalTrajmin5, search_radius,LOC_ACC,POINT_DENSITY )
% This function combines anchors that are within localization accuracy
% radius of each other and returns the merged list of anchor coordinates
% and the trajectories that define the anchor coordinates.

new_pre_anchors = pre_anchor_coords;
new_anchor_trajs = pre_anchor_trajs;
while min(pdist(new_pre_anchors)) < LOC_ACC
    % Make kd tree
    pre_anchor_tree = KDTreeSearcher(new_pre_anchors);
    % Search for anchors overlapping within localization accuracy
    overlapping_pre_anchors = rangesearch(pre_anchor_tree, new_pre_anchors, LOC_ACC);

    % Remove duplicate rows [a b] = [b a]
    overlapping_pre_anchors = removeDuplicateRows(overlapping_pre_anchors);

    % Filter for pre anchors with no close neighbors
    overlapping_pre_anchors = filterTraj(overlapping_pre_anchors, 2);

    temp_new_coords = zeros(length(overlapping_pre_anchors), 2);
    temp_trajs = cell(1,length(overlapping_pre_anchors));

    % Combine anchors
    % overlapping_pre_anchors are indices of new_anchor_trajs, the traj ID
    % is stored in new_anchor_trajs
    for idx = 1:length(overlapping_pre_anchors)
        % Remake center
        temp_new_coords(idx, :) = mean(new_pre_anchors(overlapping_pre_anchors{idx},:));
        temp_trajs{idx} = unique([new_anchor_trajs{overlapping_pre_anchors{idx}}]);
        % Delete the merged trajs
        for removed = 1:length(overlapping_pre_anchors{idx})
            new_anchor_trajs{overlapping_pre_anchors{idx}(removed)} = [];
        end
    end

    % Filter at the end to remove deleted anchors
    remaining_pre_anchors = new_pre_anchors(~cellfun(@isempty, new_anchor_trajs), :);
    new_anchor_trajs = filterTraj(new_anchor_trajs,1);

    % Add new anchors and trajs to the end
    new_pre_anchors = cat(1, remaining_pre_anchors, temp_new_coords);
    new_anchor_trajs = cat(2, new_anchor_trajs, temp_trajs);
    
    if length(new_pre_anchors) ~= length(new_anchor_trajs)
        error('anchors and trajs do not match')
    end
    
end

anchor_coords = [];
anchor_trajs = {};
if length(new_anchor_trajs) ~= length(pre_anchor_trajs)
    for anchor = 1:length(new_anchor_trajs)
        % Find potential anchors
        [anchored_coords, ~] = anchoredFrameCoords(finalTrajmin5, new_anchor_trajs{anchor});
        min_points = floor(size(anchored_coords,1)/2);
        radius_coord_dbscanID = dbscanAnchor(anchored_coords,search_radius,min_points,LOC_ACC,POINT_DENSITY);
        % 5 columns: [radius, x, y, dbscan cluster ID]
        anchor_coords = cat(1,anchor_coords,radius_coord_dbscanID);
        for anchor_idx = 1:size(radius_coord_dbscanID,1)
            % holds trajectories (finalTrajmin5 row number)
            anchor_trajs{end+1} = new_anchor_trajs{anchor};
        end

        if size(anchor_coords,1) ~= length(anchor_trajs)
            error('anchors and trajs do not match')
        end
    end
end
    
end

