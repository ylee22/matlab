function [ radius_and_coords ] = dbscanAnchor( anchored_coords, search_radius, min_points, LOC_ACC, GLOBAL_DENSITY )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

% DBSCAN to find clusters
[IDX, ~] = dbscan(anchored_coords,search_radius,min_points);

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
        for anchor = 1:max(IDX)
            anchors(anchor,:) = [mean(anchored_coords(IDX==anchor,1)) mean(anchored_coords(IDX==anchor,2))];
            radii(anchor) = max(pdist2(anchors(anchor,:),anchored_coords(IDX==anchor,:)));
        end
        
        % Upper triangle with distances between anchor centers
        dist_matrix = triu(pdist2(anchors,anchors));
        
        % Loop through every combination
        for idx1 = 1:size(anchors,1)
            for idx2 = idx1+1:size(anchors,1)
                if dist_matrix(idx1,idx2) <= max((radii(idx1) + radii(idx2))*1.25, LOC_ACC)
                    OVERLAP = 1;
                    search_radius = search_radius + 1;
                    % Redo DBSCAN with larger search_radius
                    [IDX, ~] = dbscan(anchored_coords,search_radius,min_points);
                end
            end
        end
    end
end

% Define anchor center for each cluster

% % If DBSCAN doesn't find anything
% anchored_radius = max(pdist(anchored_coords))/2;

% % If I wanted to save anchors that DBSCAN couldn't find
% if max(IDX) == 0
%     radius_and_coords = [anchored_radius, mean(anchored_coords), 0];

% Save only the anchors that were found by DBSCAN
if max(IDX) > 0
    radius_and_coords = zeros(max(IDX),4);
    for i=1:max(IDX)
        % Find anchor center
        x_y_anchor_coord = mean(anchored_coords(IDX==i,:));
        % Define anchor radius
        radius = max(pdist2(x_y_anchor_coord,anchored_coords(IDX==i,:)));
%         radius_and_coords(i,:) = [radius, x_y_anchor_coord, i];
        
        % Check to make sure that it's more dense than expected
        expected_number_of_points = ceil(GLOBAL_DENSITY*pi*radius^2);
        if 1-poisscdf(size(anchored_coords,1), expected_number_of_points) < 0.05
            
            % Save to a variable
            radius_and_coords(i,:) = [radius, x_y_anchor_coord, i];

        end
        
    end
else
    radius_and_coords = [];
end

end
