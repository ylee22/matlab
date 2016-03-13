function anchoredTraj=findAnchors(pre_anchoredTraj, localization_acc, center_coords)
    % anchoredTraj: rows are different anchors and row entries are the
    % trajectories that are stuck in that anchor (array in an array
    % containing vectors of row indices of finalTraj, finalTraj holds 
    % the individual frames for each traj)
    % center_coords: n by 2 matrix holding the center x, y coordinates for
    % all trajectories (it has same row index as finalTraj, so a trajectory in
    % anchoredTraj refers to the same trajectory in both center_coords and finalTraj)
    % anchor_coords: cell array holding n by 2 the anchor center coordinates for
    % 20 nm anchor radii increments (row indices in anchor_coords are the same
    % as anchoredTraj, they both refer to the same anchor)
    % neighboringAnchors: holds overlapping anchors that are going to be merged
    % (row entries refer to the rows of anchor coords and anchoredTraj)

    % Find anchor coordinates for 20 nm circles (localization accuracy)
    anchoredTraj{1}=filterTraj(pre_anchoredTraj,2);
    anchor_coords{1}=findAnchorCoord(anchoredTraj{1},center_coords);

    merged_marker=1;
    % For each of the anchors with radius 20n, let n be a natural number
    while merged_marker
        merged_marker=0;
        for i=1:length(anchor_coords)
            for j=1:length(anchor_coords)
                % If both anchor sizes aren't empty
                if ~isempty(anchor_coords{j}) && ~isempty(anchor_coords{i})
                    % Make kd tree for each of the 20n anchor sizes
                    kd_anchors_j=KDTreeSearcher(anchor_coords{j});
                    % Find anchors to be merged (merge distance is the sum of the
                    % radii of the two anchors to be merged)
                    % neighboringAnchors holds the rows of anchor_coords that
                    % are within overlap distance (row index of neighboringAnchors
                    % correlates with the row index of i, individual entries are
                    % the row indicies of j)
                    % neighboringAnchors has same number of rows as anchor_coords{j}
                    neighboringAnchors=rangesearch(kd_anchors_j,anchor_coords{i},localization_acc*(i+j));

                    % If it's a self comparison
                    if i==j
                        % Remove duplicate rows of overlapping anchors
                        neighboringAnchors = removeDuplicateRows(neighboringAnchors);
                    end

                    % Merge anchor trajectories and remove merged anchor trajectories
                    % newAnchoredTraj holds the new merged anchor trajectories
                    [newAnchoredTraj, anchoredTraj, anchor_coords]=mergeAnchors(neighboringAnchors, anchoredTraj, i, j, anchor_coords);

                    % If there are new anchors to be merged
                    if sum(size(newAnchoredTraj))~=0 && sum(cellfun(@isempty,newAnchoredTraj))~=length(newAnchoredTraj)
                    merged_marker=1;
                        
                        % If starting a new anchor size array
                        if i+j > length(anchor_coords) || isempty(anchor_coords{i+j})
                            anchoredTraj{i+j}=newAnchoredTraj;
                        % If adding to an existing anchor size array
                        else
                            % Add to the end
                            anchoredTraj{i+j}=cat(2,anchoredTraj{i+j},newAnchoredTraj);
                        end

                        % Remake anchor coordinates with new anchor trajectories
                        anchor_coords{i+j}=findAnchorCoord(anchoredTraj{i+j},center_coords);
                       
                        % Anchor coordinates have shifted, there are some that are 
                        % within the merge radius
                        kd_pre_anchor_coords=KDTreeSearcher(anchor_coords{i+j});
                        same_radius_overlapping_anchors=rangesearch(kd_pre_anchor_coords,anchor_coords{i+j},localization_acc*(i+j));
                        same_radius_overlapping_anchors=removeDuplicateRows(same_radius_overlapping_anchors);
                        [newAnchoredTraj2, anchoredTraj, ~]=mergeAnchors(same_radius_overlapping_anchors, anchoredTraj, i+j, i+j, anchor_coords);
                        % Add the new merged anchors at the end
                        anchoredTraj{i+j}=cat(2,anchoredTraj{i+j},newAnchoredTraj2);
                        anchor_coords{i+j}=findAnchorCoord(anchoredTraj{i+j},center_coords);
                    end
                end
            end
        end
    end
end