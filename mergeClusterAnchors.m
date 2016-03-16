function anchored_trajs = mergeClusterAnchors(pre_anchored_trajs, localization_acc, center_coords)
% Summary: merges centroids using kdtree and rangesearch in increments of
% 20n radius until there aren't any centroids within reach (n = natural
% number)

% Input:
%   pre_anchored_trajs: cell array of overlapping traj centroids within
%   localization_acc distance. If a trajectory is not overlapped with any
%   other centroid, then the entry only contains a single trajectory index
%   (index of finalTraj). This hasn't been merged yet. Just output from the
%   rangesearch with localization accuracy radius.
%	center_coords: n by 2 matrix holding the center x, y coordinates for
%   all trajectories (it has same row index as finalTraj, so a trajectory
%   in anchoredTraj refers to the same trajectory in both center_coords and
%   finalTraj) anchor_coords: cell array holding n by 2 the anchor center
%   coordinates for 20 nm anchor radii increments (row indices in
%   anchor_coords are the same as anchoredTraj, they both refer to the same
%   anchor) neighboringAnchors: holds overlapping anchors that are going to
%   be merged (row entries refer to the rows of anchor coords and
%   anchoredTraj)

% Output:
%   anchored_traj: rows are different anchors and row entries are the
%   trajectories that are stuck in that anchor (array in an array
%   containing vectors of row indices of finalTraj, finalTraj holds 
%   the individual frames for each traj)

    % Filter for minimum of 2 overlapping centroids
    anchored_trajs{1} = filterTraj(pre_anchored_trajs,2);
    % Find the centers of the anchors defined by minimum of 2 overlapping
    % centroids
    anchor_coords{1} = findClusterAnchorCoord(anchored_trajs{1},center_coords);

    % Merge cluster anchors here
    % For each of the anchors with radius 20n, with n = natural number,
    % check for overlaps between every anchor size
    % Merge distance is the sum of the radii of the two anchors to be merged
    merged_marker = 1;
    while merged_marker
        merged_marker = 0;
        for i = 1:length(anchor_coords)
            for j = 1:length(anchor_coords)
                % If both anchor sizes aren't empty
                if ~isempty(anchor_coords{j}) && ~isempty(anchor_coords{i})
                    % Make kd tree for each of the 20n anchor sizes
                    kd_anchors_j = KDTreeSearcher(anchor_coords{j});
                    % neighboringAnchors holds the rows of anchor_coords
                    % that are within overlap distance (row index of
                    % neighboringAnchors correlates with the row index of
                    % i, individual entries are the row indicies of j)
                    % neighboring_anchors has same number of rows as
                    % anchor_coords{j}
                    neighboring_anchors = rangesearch(kd_anchors_j,anchor_coords{i},localization_acc*(i+j));

                    % If it's a self comparison
                    if i == j
                        % Remove duplicate rows of overlapping anchors
                        neighboring_anchors = removeDuplicateRows(neighboring_anchors);
                    end

                    % Merge anchors and remove merged anchors (delete the
                    % coordinates and the list of trajectories for each
                    % merged anchor)
                    % new_anchored_traj holds the new merged anchor trajectories
                    [new_anchored_traj, anchored_trajs, anchor_coords] = mergeAnchors(neighboring_anchors, anchored_trajs, i, j, anchor_coords);

                    % If there are new anchors to be merged
                    if ~isempty(new_anchored_traj)
                        
                        if ~(sum(size(new_anchored_traj))~=0 && sum(cellfun(@isempty,new_anchored_traj)) ~= length(new_anchored_traj))
                            error('new_anchored_traj is empty')
                        end
                        
                        merged_marker = 1;
                        
                        % If starting a new anchor size array
                        if i+j > length(anchor_coords) || isempty(anchor_coords{i+j})
                            anchored_trajs{i+j} = new_anchored_traj;
                        % If adding to an existing anchor size array
                        else
                            % Add to the end
                            anchored_trajs{i+j} = cat(2,anchored_trajs{i+j}, new_anchored_traj);
                        end

                        % Remake anchor coordinates with new anchor trajectories
                        anchor_coords{i+j} = findClusterAnchorCoord(anchored_trajs{i+j}, center_coords);
                       
                        % Anchor coordinates have shifted, there are some that are 
                        % within the merge radius
                        kd_pre_anchor_coords = KDTreeSearcher(anchor_coords{i+j});
                        same_radius_overlapping_anchors = rangesearch(kd_pre_anchor_coords,anchor_coords{i+j},localization_acc*(i+j));
                        same_radius_overlapping_anchors = removeDuplicateRows(same_radius_overlapping_anchors);
                        [newAnchoredTraj2, anchored_trajs, ~] = mergeAnchors(same_radius_overlapping_anchors, anchored_trajs, i+j, i+j, anchor_coords);
                        % Add the new merged anchors at the end
                        anchored_trajs{i+j} = cat(2,anchored_trajs{i+j},newAnchoredTraj2);
                        anchor_coords{i+j} = findClusterAnchorCoord(anchored_trajs{i+j},center_coords);
                    end
                end
            end
        end
    end
end