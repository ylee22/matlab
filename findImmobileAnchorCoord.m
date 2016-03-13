function pre_anchor_coords = findImmobileAnchorCoord(immobileSpots,index,immobile_coords)
    % Find new anchor coordinates and add them to the anchor_coords
    pre_anchor_coords=zeros(length(immobileSpots{index}),2);
    % center_coords are the centroids for all trajectories
    for n=1:length(immobileSpots{index})
        pre_anchor_coords(n,:)=[mean(immobile_coords(immobileSpots{index}{n},4)),mean(immobile_coords(immobileSpots{index}{n},5))];
    end
end

