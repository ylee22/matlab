function pre_anchor_coords = findClusterAnchorCoord(trajectories,center_coords)
    % Find new anchor coordinates and add them to the anchor_coords
    pre_anchor_coords = zeros(length(trajectories),2);
    % center_coords are the centroids for all trajectories
    for n = 1:length(trajectories)
        if length(trajectories{n}) <= 1
            error('one or less trajectories to define the anchor center, need minimum of two trajectories to find the average')
        end
        pre_anchor_coords(n,:) = mean(center_coords(trajectories{n},:));
    end
end

