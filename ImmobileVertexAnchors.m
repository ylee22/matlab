function [ anchor_coords_1, anchor_trajs_1 ] = ImmobileVertexAnchors( finalTrajmin5, search_radius, min_points, POINT_DENSITY, LOC_ACC, immobile_coords, total_vertices )
%UNTITLED8 Summary of this function goes here
%   Detailed explanation goes here

% Find the number of frames involved in immobile steps
immobile_vertices = 0;
immobile_traj_frames = sortrows(immobile_coords(:,1:3));
traj_start = 1;
current_traj = immobile_traj_frames(traj_start, 1);
% For each trajectory, find the number of immobile frames and total frames
% 3 columnes: [finalTrajmin5 row, number of vertices less than localization
% accuracy, total number of vertices, search radius]
traj_spots_and_length = [];
for spot_idx = 1:length(immobile_traj_frames)
    if immobile_traj_frames(spot_idx, 1) ~= current_traj
        traj_end = spot_idx - 1;
        immobile_vertices = immobile_vertices + numel(unique(immobile_traj_frames(traj_start:traj_end, 2:3)));
        
        % Find immobile spot coordinates
        rows = unique(immobile_traj_frames(traj_start:traj_end, 2:3));
        spot_coords = finalTrajmin5{current_traj}(rows,1:2);
        
        % If there are two distinct clusters, max(pdist(spot_coords)) is very
        % very large, use median spot distance instead (median spot distance
        % should still be accurate even if there are two separate clusteres).
        % Use localization error instead if the immobile spots are too close
        % together.
        spot_distance = zeros(1, size(spot_coords,1) - 1);
        for row = 1:size(spot_coords,1) - 1
            spot_distance(row) = pdist(spot_coords(row:row+1,:));
        end
        
        traj_spots_and_length(end + 1, :) = [current_traj, numel(rows), finalTrajmin5{current_traj}(1, 7) - finalTrajmin5{current_traj}(1, 6) + 1];
        
        traj_start = spot_idx;
        current_traj = immobile_traj_frames(traj_start, 1);
    end
    
    % To fix the problem of the last row being skipped (last row is added
    % here)
    if spot_idx == length(immobile_traj_frames)
        traj_end = spot_idx;
        immobile_vertices = immobile_vertices + numel(unique(immobile_traj_frames(traj_start:traj_end, 2:3)));
        
        % Find immobile spot coordinates
        rows = unique(immobile_traj_frames(traj_start:traj_end, 2:3));
        spot_coords = finalTrajmin5{current_traj}(rows,1:2);
        
        % If there are two distinct clusters, max(pdist(spot_coords)) is very
        % very large, use median spot distance instead (median spot distance
        % should still be accurate even if there are two separate clusteres).
        % Use localization error instead if the immobile spots are too close
        % together.
        spot_distance = zeros(1, size(spot_coords,1) - 1);
        for row = 1:size(spot_coords,1) - 1
            spot_distance(row) = pdist(spot_coords(row:row+1,:));
        end
        
        traj_spots_and_length(end + 1, :) = [current_traj numel(rows), finalTrajmin5{current_traj}(1, 7) - finalTrajmin5{current_traj}(1, 6) + 1];
    end
end

% Find the probability of each frame being immobile
prob_immobile = immobile_vertices/total_vertices;
% prob_immobile = 0.0710;

% Threshold probability for number of immobile spots based on length
% Expected number of immobile vertices in each trajectory based on the
% overall probability is prob_immobile*number of frames in trajectory
% Use poisson distribution to calculate the probability of finding x number
% of immobile vertices in trajectory of given length y
slow_anchors = zeros(size(traj_spots_and_length,1), 2);
slow_trajs = cell(1, size(traj_spots_and_length,1));
counter = 0;
for idx = 1:length(traj_spots_and_length)
    if traj_spots_and_length(idx,2)>=min_points && 1-poisscdf(traj_spots_and_length(idx,2),prob_immobile*traj_spots_and_length(idx,3)) < 0.05
        
        counter = counter + 1;
        % Find potential anchors
        [anchored_coords, ~] = anchoredFrameCoords(finalTrajmin5, traj_spots_and_length(idx, 1));
        slow_anchors(counter, :) = mean(anchored_coords);
        slow_trajs{counter} = traj_spots_and_length(idx,1);

    end
end

slow_anchors = slow_anchors(1:counter,:);
slow_trajs = slow_trajs(1:counter);

if size(slow_anchors,1) ~= length(slow_trajs)
    error('anchors and trajs do not match')
end

% Quick merge
[merged_coords, merged_trajs] = FastMergeOverlappingAnchors(slow_anchors, slow_trajs, finalTrajmin5, search_radius, LOC_ACC, POINT_DENSITY);

% Merge overlapping anchors and finalize anchors
[anchor_coords_1, anchor_trajs_1] = SlowMergeOverlappingAnchors(merged_coords, merged_trajs, finalTrajmin5, search_radius, LOC_ACC, POINT_DENSITY );

end

