function [ anchor_coords_2, anchor_trajs_2 ] = TotalVariationAnchors( finalTrajmin5, search_radius, POINT_DENSITY, LOC_ACC, threshold_dist )
% Finds anchors based on total variation analysis, which measures the
% displacement from the origin for each trajectory. If a trajectory is
% stuck, then the displacement from the origin will be less than the anchor
% size for the frames in the anchor.
%   For each trajectory, calculate the displacement from the first frame
%   until the last frame - the minimum number of frames required to be in
%   the anchor to every other frame that comes after it. If there are at
%   least n number of frames where displacement is less than threshold,
%   then this trajectory was in an anchor.

stuck_trajs = cell(1,length(finalTrajmin5));
stuck_anchors = zeros(length(finalTrajmin5), 2);
counter = 0;
total_vertices = 0;
% threshold_dist = 50;

% For each trajectory
for traj = 1:length(finalTrajmin5)
    % Find the total number of points for the overall point density
    total_vertices = total_vertices + size(finalTrajmin5{traj}, 1);

    % For x min frames, need to check one less min from from last to catch
    % anchors at the end
    min_frames = floor(size(finalTrajmin5{traj},1)/2);
    origins = finalTrajmin5{traj}(1:end - min_frames + 1, 1:2);
    disp_from_origin = pdist2(origins, finalTrajmin5{traj}(:, 1:2));
    
    for start = 1:size(disp_from_origin,1)
        if sum(disp_from_origin(start, start + 1:end) <= threshold_dist) > min_frames
            counter = counter + 1;
            [anchored_coords, ~] = anchoredFrameCoords(finalTrajmin5, traj);
            stuck_anchors(counter, :) = mean(anchored_coords);
            stuck_trajs{counter} = traj;
            break
        end
    end

end

stuck_anchors = stuck_anchors(1:counter, :);
stuck_trajs = stuck_trajs(1:counter);

if size(stuck_anchors,1) ~= length(stuck_trajs)
    error('anchors and trajs do not match')
end

% search_radius = 50;
% min_points = 3;
% POINT_DENSITY = total_vertices/cell_area;
% LOC_ACC = 25;

% Quick merge
[merged_coords, merged_trajs] = FastMergeOverlappingAnchors(stuck_anchors, stuck_trajs, finalTrajmin5, search_radius, LOC_ACC, POINT_DENSITY);

% Merge overlapping anchors and finalize anchors
[anchor_coords_2, anchor_trajs_2] = SlowMergeOverlappingAnchors(merged_coords, merged_trajs, finalTrajmin5, search_radius, LOC_ACC, POINT_DENSITY );

end

