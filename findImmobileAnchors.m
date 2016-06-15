function [ anchor_coords, anchored_spots, immobile_coords ] = findImmobileAnchors( finalTraj, localization_acc, cell_area )
% Summary: finds the immobile anchors by merging immobile spots by
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
%   anchor_coords: a n by 2 matrix with x and y immobile anchor coordinates
%   anchored_spots: a cell array of immobile_coords index vectors, each entry in
%   anchored_spots refers to the to the trajectories used to define
%   corresponding row in the anchor_coords
%   INDICES OF anchored_traj AND anchor_coords REFER TO THE SAME ANCHOR!!!
%   immobile_coords: a n by 5 matrix of all adjacent frame displacements
%   less than the localization accuracy
%   [traj row number in finalTraj, 1st frame, 2nd frame, averaged x, averaged y]

    % Find all adjacent frames that traveled less than the localization
    % accuracy and put them into an n by 5 matrix
    % [traj row number in finalTraj, 1st frame, 2nd frame, averaged x,
    % averaged y]
    immobile_coords = [];
    for i = 1:length(finalTraj)
        for j = 1:size(finalTraj{i},1)-1
            if pdist2(finalTraj{i}(j,1:2), finalTraj{i}(j+1,1:2)) < localization_acc
                immobile_coords(end+1,:) = [i,j,j+1,mean(finalTraj{i}(j:j+1,1:2))];
            end
        end
    end

    % KD Tree of all the trajectory centers
    kd_center = KDTreeSearcher(immobile_coords(:,4:5));

    % Indices of trajectories in finalTraj within the localization accuracy (20 nms)
    neighboring_spots = rangesearch(kd_center,immobile_coords(:,4:5),localization_acc);

    % Remove duplicate rows of overlapping trajectories
    % Sometimes two rows are identical, so remove the latter row
    neighboring_spots = removeDuplicateRows(neighboring_spots);

    % Find anchors here
    anchored_spots = mergeImmobileSpots(neighboring_spots, localization_acc, immobile_coords(:,4:5));
    
    % Remove empty cells
    anchored_spots = anchored_spots(~cellfun(@isempty, anchored_spots));
    
    % Filter based on the minimum number of spots per anchor
    % Calculate the probability and the threshold for min spots/anchor
    anchor_coords = {};
    for anchor_radius_idx = 1:length(anchored_spots)
        if ~isempty(anchored_spots{anchor_radius_idx})
            expected_number_of_immobile_spots = (length(immobile_coords)/cell_area)*pi*(20*anchor_radius_idx)^2;
            minAnchoredSpots = 2;
            probability = 1;
            while probability > 0.05
                minAnchoredSpots = minAnchoredSpots+1;
                probability = 1 - poisscdf(minAnchoredSpots,expected_number_of_immobile_spots);
            end
            anchored_spots{anchor_radius_idx} = filterTraj(anchored_spots{anchor_radius_idx}, minAnchoredSpots);
            if ~isempty(anchored_spots{anchor_radius_idx})
                % Remake anchor coordinates
                anchor_coords{anchor_radius_idx} = findImmobileAnchorCoord(anchored_spots{anchor_radius_idx},immobile_coords(:,4:5));
            end
        end
    end
    
%     % Convert immobile spots into trajectories (same format as cluster
%     % anchor)
%     anchoredTraj = convertSpotsIntoTraj(anchoredSpots, immobile_coords);
    
end
