function pre_anchor_coords = findImmobileAnchorCoord(clustered_immobile_spots,immobile_x_y_coords)
    % Find new anchor coordinates and add them to the anchor_coords
    pre_anchor_coords=zeros(length(clustered_immobile_spots),2);
    % center_coords are the centroids for all trajectories
    for anchor_idx=1:length(clustered_immobile_spots)
        if length(clustered_immobile_spots{anchor_idx}) <= 1
            error('one or less spots to define anchor center, need minimum of two spots to find the average')
        end
        pre_anchor_coords(anchor_idx,:) = mean(immobile_x_y_coords(clustered_immobile_spots{anchor_idx},:));
    end
end

