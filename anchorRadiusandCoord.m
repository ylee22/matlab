function [ radius_and_coords, spot_to_traj ] = anchorRadiusandCoord(finalTraj,immobile_spot_coords,trajs,LOC_ACC,GLOBAL_DENSITY)
% Summary: This function takes the parameters that were used to find an
% anchor (either trajectories or immobile spots or both) and uses DBSCAN to
% define anchor center and the radius.
% Inputs:
%   findTraj: the connected and filtered (re-connecting segmented
%   trajectories and filtered often times by the trajectory length) vbSPT
%   format output from Tao's Single Molecule Trajectory package. It's a
%   cell array with each row containing a matrix of trajectory information.
%   immobile_spot_coords: the slice of the immobile_coords with the spots
%   used to find the anchor
%   trajs: trajectory indices in finalTraj that were used to find the
%   anchor
%   LOC_ACC: a positive integer in nms to define the localization accuracy
%   of the movie. Used to define the search radius and merging anchors.
%   GLOBAL_DENSITY: a positive number for the density of all of the
%   coordinates in this system (total number of coordinates/area occupied
%   by the cell(s) in the movie)
% Outputs:
%   radius_and_coords: n by 4 matrix with [radius, anchor x coord, anchor y
%   coord, cluster index number from DBSCAN]
%   spot_to_traj: spots (immobile_coord indices) converted to trajectories
%   (finalTraj indices)

% if immobile_coords is not empty and the spots are not cell, then immobile
% only, if immobile_coords is empty, then cluster only, if immobile_coords
% is not empty and current_trajs_spots is a cell, then both
% Immobile first before cluster, need to convert to traj

% If both
if ~isempty(immobile_spot_coords) && ~isempty(trajs)
    % Convert to trajectories
    spot_to_traj = unique(immobile_spot_coords(:,1))';
    traj_list = unique([trajs,spot_to_traj]);
    [anchored_coords, search_radius] = anchoredFrameCoords(finalTraj, traj_list);

    % Find anchor center and radius here
    % Determine the inputs to DBSCAN
    % search radius is the median of all of the step sizes taken by the
    % anchored trajectories
    search_radius = max(median(search_radius),LOC_ACC);
    
    % If DBSCAN doesn't find anything
    anchored_radius = max(pdist(anchored_coords))/2;

    % immobile_coords is the average between the two consecutive frames
    % with distance less than the localization accuracy. Need to find the
    % original coordinates used to find immobile_coords. These points will
    % determine the minimum point to define a cluster and the search radius
    % for DBSCAN. Sometimes there is a redundant spot (1 & 2, 2 & 3 = 1, 2, 3)
    min_points = 0;
    for traj_idx = 1:numel(spot_to_traj)
        min_points = min_points + numel(unique(immobile_spot_coords(immobile_spot_coords(:,1)==spot_to_traj(traj_idx),2:3)));
    end
    min_points = min(min_points - 1, floor(size(anchored_coords,1)/2) - 1);

    % Use poisson distribution for the minimum points to define an anchor
    expected_number_of_points = GLOBAL_DENSITY*pi*search_radius^2;

    probability = 1;
    while probability > 0.05 && min_points < size(anchored_coords,1)/2;
        min_points = min_points + 1;
        probability = 1 - poisscdf(min_points,expected_number_of_points);
    end
% If only immobile
elseif ~isempty(immobile_spot_coords)
    % Convert to trajectories
    spot_to_traj = unique(immobile_spot_coords(:,1))';
    [anchored_coords, ~] = anchoredFrameCoords(finalTraj, spot_to_traj);

    % immobile_coords is the average between the two consecutive frames
    % with distance less than the localization accuracy. Need to find the
    % original coordinates used to find immobile_coords. These points will
    % determine the minimum point to define a cluster and the search radius
    % for DBSCAN.
    spot_coords = zeros(size(immobile_spot_coords,1)*2,2);
    COUNTER = 1;
    for traj_idx = 1:numel(spot_to_traj)
        finalTraj_spot_idx = unique(immobile_spot_coords(immobile_spot_coords(:,1)==spot_to_traj(traj_idx),2:3));
        spot_coords(COUNTER:COUNTER+numel(finalTraj_spot_idx)-1,:) = finalTraj{spot_to_traj(traj_idx)}(finalTraj_spot_idx,1:2);
        COUNTER = COUNTER + numel(finalTraj_spot_idx);
    end
    % Sometimes there is a redundant spot (1 & 2, 2 & 3 = 1, 2, 3)
    spot_coords = spot_coords(1:COUNTER - 1, :);
    
    % If there are two distinct clusters, max(pdist(spot_coords)) is very
    % very large, use median spot distance instead (median spot distance
    % should still be accurate even if there are two separate clusteres).
    % Use localization error instead if the immobile spots are too close
    % together.
    spot_distance = zeros(1, size(spot_coords,1) - 1);
    for row = 1:size(spot_coords,1) - 1
        spot_distance(row) = pdist(spot_coords(row:row+1,:));
    end
    search_radius = max(median(spot_distance),LOC_ACC);
    
    % If DBSCAN doesn't find anything
    anchored_radius = max(pdist(anchored_coords))/2;

    % Assume that there are two anchors here and set the min points to the
    % number of points in larger of the two clusters (if there is actually
    % only 1 cluster, then the smaller cluster will be false)
    kmeans_clusters = kmeans(spot_coords,2);
    min_points = max(max(sum(kmeans_clusters==1), sum(kmeans_clusters==2)), 3);
%     min_points = max(ceil(max(sum(kmeans_clusters==1), sum(kmeans_clusters==2))/2), 3);
%     min_points = min(COUNTER - 1, floor(size(anchored_coords,1)/2));
    
% If cluster only
elseif ~isempty(trajs)
    spot_to_traj = [];
    [anchored_coords, search_radius] = anchoredFrameCoords(finalTraj, trajs);

    % Find anchor center and radius here
    % Determine the inputs to DBSCAN
    % search radius is the median of all of the step sizes taken by the
    % anchored trajectories
    search_radius = max(median(search_radius),LOC_ACC);
    
    % If DBSCAN doesn't find anything
    anchored_radius = max(pdist(anchored_coords))/2;

    % Use poisson distribution for the minimum points to define an anchor
    expected_number_of_points = GLOBAL_DENSITY*pi*search_radius^2;
    min_points = 2;

    probability = 1;
    while probability > 0.05 && min_points < length(anchored_coords);
        min_points = min_points + 1;
        probability = 1 - poisscdf(min_points,expected_number_of_points);
    end

end

% DBSCAN to find clusters
[IDX, ~] = DBSCAN_with_comments(anchored_coords,search_radius,min_points);

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
            anchors(anchor,:) = mean(anchored_coords(IDX==anchor,:));
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
                    [IDX, ~] = DBSCAN_with_comments(anchored_coords,search_radius,min_points);
                end
            end
        end
    end
end

% Define anchor center for each cluster

% If I wanted to save anchors that DBSCAN couldn't find
if max(IDX) == 0
    radius_and_coords = [anchored_radius, mean(anchored_coords), 0];

% Save only the anchors that were found by DBSCAN
elseif max(IDX) > 0
    radius_and_coords = zeros(max(IDX),4);
    for i=1:max(IDX)
        % Find anchor center
        x_y_anchor_coord = mean(anchored_coords(IDX==i,:));
        % Define anchor radius
        radius = max(pdist2(x_y_anchor_coord,anchored_coords(IDX==i,:)));
        % Save to a variable
        radius_and_coords(i,:) = [radius, x_y_anchor_coord, i];
    end
else
    radius_and_coords = [];
end

end
