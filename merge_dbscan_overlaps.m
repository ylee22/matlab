function [ IDX ] = merge_dbscan_overlaps( IDX, anchored_coords, LOC_ACC, search_radius, min_points )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% Check for overlaps if DBSCAN finds multiple clusters within one anchor
if max(IDX) > 1
    OVERLAP = 1;
    % During the while loop, number of anchors can go down to 1. Need to
    % recheck for minimum of 2 clusters here. If there is only one cluster,
    % dist_matrix will be 0 and trying to index into dist_matrix will cause
    % an index error.
    while OVERLAP && max(IDX) > 1
        OVERLAP = 0;
        anchors = zeros(max(IDX),2);
        radii = zeros(max(IDX),1);
        % Find anchor locations and radii
        for anchor = 1:max(IDX)
            anchors(anchor,:) = [mean(anchored_coords(IDX==anchor,1)) mean(anchored_coords(IDX==anchor,2))];
            radii(anchor) = max(pdist2(anchors(anchor,:),anchored_coords(IDX==anchor,:)));
        end
        
        % Upper triangle with distances between anchor centers
        dist_matrix = triu(pdist2(anchors,anchors));
        
        % Loop through every combination
        for idx1 = 1:size(anchors,1)
            for idx2 = idx1+1:size(anchors,1)
                if dist_matrix(idx1,idx2) <= max((radii(idx1) + radii(idx2)), LOC_ACC)
                    OVERLAP = 1;
                    % if multiple anchors are overlapping, redo dbscan with
                    % a larger search radius
                    search_radius = search_radius + 1;
                    [IDX, ~] = dbscan(anchored_coords,search_radius,min_points);
                end
            end
        end
    end
    
    % Most trajectories with more than 1 anchor doesn't look like anchors
    % Throw away trajectories that have adjacent points in two different
    % anchors IDX = [1 2 1 2 1 2 1]
    if max(IDX) > 1
        first_anchor = find(IDX == 1);
        second_anchor = find(IDX == 2);
        while sum(IDX(min(first_anchor):max(first_anchor)) == 2) > 1 && sum(IDX(min(second_anchor):max(second_anchor)) == 1) > 1
            % if there are dubious multiple anchors, redo dbscan with
            % increasing number of min points until it either finds 0 or
            % just 1 anchor
            min_points = min_points + 1;
            [IDX, ~] = dbscan(anchored_coords,search_radius,min_points);
            first_anchor = find(IDX == 1);
            second_anchor = find(IDX == 2);
        end
    end
    
end

end

