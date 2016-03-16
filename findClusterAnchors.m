function [ anchor_coords, anchored_traj ] = findClusterAnchors( finalTraj, localization_acc, cell_area )
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
    center_coords=zeros(length(finalTraj),2);
    for c=1:length(finalTraj)
        center_coords(c,:)=[mean(finalTraj{c}(:,1)),mean(finalTraj{c}(:,2))];
    end

    % KD Tree of all the trajectory centers
    kd_center=KDTreeSearcher(center_coords);

    % Trajectories (indices of finalTraj) within the localization accuracy (20 nms)
    % neighboring_traj: cell array of vectors containing overlapping trajs
    neighboring_traj=rangesearch(kd_center,center_coords,localization_acc);

    % Remove duplicate rows of overlapping trajectories, e.g. [1 2] = [2 1]
    % Sometimes two rows are identical, so remove the latter row
    neighboring_traj = removeDuplicateRows(neighboring_traj);

    % Find anchors here
    anchored_traj = mergeClusterAnchors(neighboring_traj, localization_acc, center_coords);
    
    % Filter based on the minimum number of trajectories per anchor
    % Calculate the probability and the threshold for min traj/anchor
    anchor_coords = {};
    for anchor_radius_idx = 1:length(anchored_traj)
        if ~isempty(anchored_traj{anchor_radius_idx})
            traj_density = (length(finalTraj)/cell_area)*pi*(20*anchor_radius_idx)^2;
            minAnchoredTraj = 2;
            probability = 1;
            while probability > 0.05
                minAnchoredTraj = minAnchoredTraj+1;
                probability = 1-poisscdf(minAnchoredTraj,traj_density);
            end
            anchored_traj{anchor_radius_idx} = filterTraj(anchored_traj{anchor_radius_idx}, minAnchoredTraj);
            if ~isempty(anchored_traj{anchor_radius_idx})
                % Remake anchor coordinates
                anchor_coords{anchor_radius_idx} = findClusterAnchorCoord(anchored_traj{anchor_radius_idx}, center_coords);
            end
        end
    end
    
end