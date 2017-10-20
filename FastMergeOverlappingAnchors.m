function [ anchor_coords, anchor_trajs ] = FastMergeOverlappingAnchors( pre_anchor_coords, pre_anchor_trajs, finalTrajmin5, SEARCH_RADIUS, LOC_ACC, POINT_DENSITY, ABS_MIN_POINTS, min_fraction )
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
        % Find non empty entries (could have been deleted from before)
        non_empty = ~cellfun(@isempty,new_anchor_trajs(overlapping_pre_anchors{idx}));
        current_overlapping = overlapping_pre_anchors{idx}(non_empty);
        % Remake center
        temp_new_coords(idx, :) = [mean(new_pre_anchors(current_overlapping,1)), mean(new_pre_anchors(current_overlapping,2))];
        temp_trajs{idx} = unique([new_anchor_trajs{current_overlapping}]);
        % Delete the merged trajs
        for removed = 1:length(current_overlapping)
            new_anchor_trajs{current_overlapping(removed)} = [];
        end
    end

    % Filter at the end to remove deleted anchors
    remaining_pre_anchors = new_pre_anchors(~cellfun(@isempty, new_anchor_trajs), :);
    new_anchor_trajs = filterTraj(new_anchor_trajs,1);

    % Add new anchors and trajs to the end
    new_pre_anchors = cat(1, remaining_pre_anchors, temp_new_coords);
    new_anchor_trajs = cat(2, new_anchor_trajs, temp_trajs);
    
    if size(new_pre_anchors, 1) ~= numel(new_anchor_trajs)
        error('anchors and trajs do not match')
    end
    
end

% Filter at the end to remove deleted anchors
new_anchor_trajs = filterTraj(new_anchor_trajs,1);

anchor_coords = [];
anchor_trajs = {};
for anchor = 1:length(new_anchor_trajs)
    
    % Find potential anchors
    if numel(new_anchor_trajs{anchor}) > 1
        combined_trajs = new_anchor_trajs{anchor};
        trajs_coords = {};
        [trajs_coords{1:numel(combined_trajs)}] = deal(finalTrajmin5{combined_trajs});
        trajs_coords = cellfun(@(x) x(:,1:2), trajs_coords, 'UniformOutput', false);
    else
        trajs_coords = {finalTrajmin5{new_anchor_trajs{anchor}}(:,1:2)};
    end
    
    [radius_coord, trajs] = dbscanAnchor(SEARCH_RADIUS, LOC_ACC, POINT_DENSITY, trajs_coords, new_anchor_trajs{anchor}, ABS_MIN_POINTS, min_fraction);
    
    if isempty(radius_coord)
        min_fraction2 = 3;
        [radius_coord, trajs] = dbscanAnchor(SEARCH_RADIUS, LOC_ACC, POINT_DENSITY, trajs_coords, new_anchor_trajs{anchor}, ABS_MIN_POINTS, min_fraction2);
    end
    
    if ~isempty(radius_coord)
        % 4 columns: [radius, x, y, frames in anchor]
        anchor_coords = cat(1, anchor_coords, radius_coord);

        % holds trajectories (finalTrajmin5 row number)
        anchor_trajs = cat(2, anchor_trajs, trajs);


        if size(anchor_coords, 1) ~= length(anchor_trajs)
            error('anchors and trajs do not match')
        end
    end
end
    
end

