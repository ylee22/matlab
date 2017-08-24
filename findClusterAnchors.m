function [ slow_cluster_coords, slow_cluster_trajs ] = findClusterAnchors( finalTrajmin5, LOC_ACC, POINT_DENSITY, SEARCH_RADIUS, MIN_POINTS )
% Summary: finds the cluster anchors by merging trajectory centroids by
% localization accuracy radius circles

% Inputs:
%   finalTraj: output from Tao's SMT that's been modified (segmented 
%   trajectories reconnected and filtered for minimum length). 
%   Cell array with each entry referring to a unique trajectory. 
%   Each entry (trajectory) is an n by 7 matrix:
%       1. x coordinate in nms (converted to nms from Tao's SMT)
%       2. y coordinate in nms (converted to nms from Tao's SMT)
%       3. the starting index in cordata.coords_smt (referring to the output from wfiread, the .coor file)
%       4. the index number in finalTraj
%       5. frame number
%       6. starting frame number
%       7. ending frame number
%   localization_acc: localization accuracy of each particle (defines the 
%   radius to merge trajectory centroids)
%   cell_area: area covered by cells (used to calculate deviation from 
%   complete spatial randomness)

% Outputs:
%   anchor_coords: a n by 2 matrix with x and y cluster anchor coordinates
%   anchored_traj: a cell array of finalTraj index vectors, each entry in
%   anchored_traj refers to the to the trajectories used to define
%   corresponding row in the anchor_coords
%   INDICES OF anchored_traj AND anchor_coords REFER TO THE SAME ANCHOR!!!

    % Find center coordinates of all trajectories
    % center_coords: n by 2 matrix with x and y coords of traj centroids
    center_coords=zeros(length(finalTrajmin5),2);
    for c=1:length(finalTrajmin5)
        center_coords(c,:)=[mean(finalTrajmin5{c}(:,1)),mean(finalTrajmin5{c}(:,2))];
    end

    % KD Tree of all the trajectory centers
    kd_center=KDTreeSearcher(center_coords);

    % Trajectories (indices of finalTraj) within the localization accuracy (20 nms)
    % neighboring_traj: cell array of vectors containing overlapping trajs
    neighboring_traj=rangesearch(kd_center,center_coords,LOC_ACC);

    % Remove duplicate rows of overlapping trajectories, e.g. [1 2] = [2 1]
    % Sometimes two rows are identical, so remove the latter row
    neighboring_traj = removeDuplicateRows(neighboring_traj);
    
    pre_anchor_trajs = filterTraj(neighboring_traj, 2);
    pre_anchor_coords = findClusterAnchorCoord(pre_anchor_trajs, center_coords);
    
    [fast_cluster_coords, fast_cluster_trajs] = FastMergeOverlappingAnchors(pre_anchor_coords,pre_anchor_trajs,finalTrajmin5,SEARCH_RADIUS,LOC_ACC,POINT_DENSITY, MIN_POINTS);
    [slow_cluster_coords, slow_cluster_trajs] = SlowMergeOverlappingAnchors(fast_cluster_coords,fast_cluster_trajs,finalTrajmin5,SEARCH_RADIUS,LOC_ACC,POINT_DENSITY, MIN_POINTS);

    % Find anchors here
%     anchored_traj = mergeClusterAnchors(neighboring_traj, localization_acc, center_coords);
    
    % Remove empty cells
%     anchored_traj = anchored_traj(~cellfun(@isempty, anchored_traj));
    
    % Filter based on the minimum number of trajectories per anchor
    % Calculate the probability and the threshold for min traj/anchor
%     anchor_coords = {};
%     for anchor_radius_idx = 1:length(anchored_traj)
%         if ~isempty(anchored_traj{anchor_radius_idx})
%             traj_density = (length(finalTrajmin5)/cell_area)*pi*(20*anchor_radius_idx)^2;
%             minAnchoredTraj = 2;
%             probability = 1;
%             while probability > 0.05
%                 minAnchoredTraj = minAnchoredTraj + 1;
%                 probability = 1-poisscdf(minAnchoredTraj,traj_density);
%             end
%             anchored_traj{anchor_radius_idx} = filterTraj(anchored_traj{anchor_radius_idx}, minAnchoredTraj);
%             if ~isempty(anchored_traj{anchor_radius_idx})
%                 % Remake anchor coordinates
%                 anchor_coords{anchor_radius_idx} = findClusterAnchorCoord(anchored_traj{anchor_radius_idx}, center_coords);
%             end
%         end
%     end
    
end