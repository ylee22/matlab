function [ radius_and_coords, spot_to_traj ] = anchorRadiusandCoord(finalTraj,immobile_spot_coords,trajs,LOC_ACC,GLOBAL_DENSITY)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

% if immobile_coords is not empty and the spots are not cell, then immobile
% only, if immobile_coords is empty, then cluster only, if immobile_coords
% is not empty and current_trajs_spots is a cell, then both
% Immobile first before cluster, need to convert to traj

% If both
if ~isempty(immobile_spot_coords) && ~isempty(trajs)
    % Convert to trajectories
    spot_to_traj = unique(immobile_spot_coords(:,1))';
    traj_list = cat(2,trajs,spot_to_traj);
    [anchored_coords, search_radius] = anchoredFrameCoords(finalTraj, traj_list);

    % Find anchor center and radius here
    % Determine the inputs to DBSCAN
    % search radius is the median of all of the step sizes taken by the
    % anchored trajectories
    search_radius = median(search_radius);
    % Use poisson distribution for the minimum points to define an anchor
    anchored_radius = max(pdist(anchored_coords))/2;
%     expected_number_of_points = length(anchored_coords)/(pi*anchored_radius^2)*pi*search_radius^2;
%     min_points = ceil(length(anchored_coords)/100);

    expected_number_of_points = GLOBAL_DENSITY*pi*search_radius^2;
    min_points = 2;

    probability = 1;
    while probability > 0.05 && min_points < length(anchored_coords);
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
    counter = 1;
    for traj_idx = 1:numel(spot_to_traj)
        finalTraj_spots_idx = unique(immobile_spot_coords(immobile_spot_coords(:,1)==spot_to_traj(traj_idx),2:3));
        spot_coords(counter:counter+numel(finalTraj_spots_idx)-1,:) = finalTraj{spot_to_traj(traj_idx)}(finalTraj_spots_idx,1:2);
        counter = counter + numel(finalTraj_spots_idx);
    end
    % Sometimes there is a redundant spot (1 & 2, 2 & 3 = 1, 2, 3)
    spot_coords = spot_coords(1:counter-1,:);
    
    % Farthest distance between two immobile spots to approximate search
    % radius. Use localization error instead if the immobile spots are too
    % close together
    search_radius = max(max(pdist(spot_coords)),LOC_ACC);
    
    % If DBSCAN doesn't find anything
    anchored_radius = search_radius;

    % The cluster has to have at minimum the number of immobile spots that were
    % found before
    min_points = counter - 1;
    
% If cluster only
elseif ~isempty(trajs)
    spot_to_traj = [];
    [anchored_coords, search_radius] = anchoredFrameCoords(finalTraj, trajs);

    % Find anchor center and radius here
    % Determine the inputs to DBSCAN
    % search radius is the median of all of the step sizes taken by the
    % anchored trajectories
    search_radius = median(search_radius);
    % Use poisson distribution for the minimum points to define an anchor
    anchored_radius = max(pdist(anchored_coords))/2;
%     expected_number_of_points = length(anchored_coords)/(pi*anchored_radius^2)*pi*search_radius^2;
%     min_points = ceil(length(anchored_coords)/100);

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
                if dist_matrix(idx1,idx2) <= max((radii(idx1) + radii(idx2))*1.2, LOC_ACC)
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
if max(IDX) == 0
    radius_and_coords = [anchored_radius, mean(anchored_coords), 0];
else
    radius_and_coords = zeros(max(IDX),4);
    for i=1:max(IDX)
        % Find anchor center
        x_y_anchor_coord = mean(anchored_coords(IDX==i,:));
        % Define anchor radius
        radius = max(pdist2(x_y_anchor_coord,anchored_coords(IDX==i,:)));
        % Save to a variable
        radius_and_coords(i,:) = [radius, x_y_anchor_coord, i];
    end
end

end

function [traj_coords, frame_displacement] = anchoredFrameCoords(finalTrajCoords, finalTrajIdx)
% Returns a n by 2 matrix of just x, y coordinates of all of the anchored
% trajectories
traj_coords = finalTrajCoords{finalTrajIdx(1)}(:,1:2);
frame_displacement = dispAdjFrames({traj_coords});
for trajs = 2:length(finalTrajIdx)
    traj_coords = cat(1, traj_coords, finalTrajCoords{finalTrajIdx(trajs)}(:,1:2));
    frame_displacement = cat(2, frame_displacement, dispAdjFrames({traj_coords}));
end
end