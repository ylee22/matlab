function [ anchor_coords, anchor_trajs ] = DispAnchorDuration( finalTrajmin5, SEARCH_RADIUS, POINT_DENSITY, LOC_ACC, threshold_dist )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

stuck_trajs = cell(1,length(finalTrajmin5));
% stuck_anchors = zeros(length(finalTrajmin5), 2);
counter = 0;

% For each trajectory
for traj = 1:length(finalTrajmin5)

    % For x min frames, need to check one less min from last to catch
    % anchors at the end
    min_frames = max(floor(size(finalTrajmin5{traj},1)/2), 3);
    origins = finalTrajmin5{traj}(1:end - min_frames + 1, 1:2);
    disp_from_origin = pdist2(origins, finalTrajmin5{traj}(:, 1:2));
    
    for start = 1:size(disp_from_origin,1)
        if sum(disp_from_origin(start, start + 1:end) <= threshold_dist) > min_frames
            counter = counter + 1;
%             [anchored_coords, ~] = anchoredFrameCoords(finalTrajmin5, traj);
%             stuck_anchors(counter, :) = mean(anchored_coords);
            stuck_trajs{counter} = traj;
            break
        end
    end

end

% stuck_anchors = stuck_anchors(1:counter, :);
stuck_trajs = stuck_trajs(1:counter);

% if size(stuck_anchors,1) ~= length(stuck_trajs)
%     error('anchors and trajs do not match')
% end

anchor_coords = [];
anchor_trajs = {};
for anchor = 1:length(stuck_trajs)
    % Find potential anchors
    [anchored_coords, ~] = anchoredFrameCoords(finalTrajmin5, stuck_trajs{anchor});
    min_points = max(floor(size(anchored_coords, 1)/2), 3);
    radius_coord_dbscanID = dbscanAnchor(anchored_coords,SEARCH_RADIUS,min_points,LOC_ACC,POINT_DENSITY);

    if ~isempty(radius_coord_dbscanID)
        % 5 columns: [radius, x, y, anchor duration in frames]
        anchor_coords = cat(1,anchor_coords,radius_coord_dbscanID);
        for anchor_idx = 1:size(radius_coord_dbscanID,1)
            % holds trajectories (finalTrajmin5 row number)
            anchor_trajs{end+1} = stuck_trajs{anchor};
        end

        if size(anchor_coords,1) ~= length(anchor_trajs)
            error('anchors and trajs do not match')
        end
    end
end

end

