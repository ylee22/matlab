function [ final_anchor_coords, final_anchor_trajs, merged_coords, merged_trajs ] = TotalVariationAnchors( finalTrajmin5, search_radius, POINT_DENSITY, LOC_ACC, threshold_dist, MIN_POINTS, min_fraction )
% Finds anchors by measuring the displacement from the origin (each frame,
% except for the last few) for each trajectory. If a trajectory is
% stuck, then the displacement from the origin will be less than the anchor
% size for the frames in the anchor.
%   For each trajectory, calculate the displacement from the first frame
%   until the last frame - the minimum number of frames required to be in
%   the anchor to every other frame that comes after it. If there are at
%   least n number of frames where displacement is less than threshold,
%   then this trajectory was in an anchor.

%%% IF TRYING TO SCREEN FOR ANCHORS WITH TAILS, CHANGE dbscanAnchor.m and
%%% AnchorsWithFreeComponent.m

stuck_trajs = cell(1,length(finalTrajmin5));
stuck_anchors = zeros(length(finalTrajmin5), 2);
counter = 0;

% For each trajectory, look at the displacement from each frame to detect
% anchors
% It's unfair for really long trajectories (before min_frames =
% floor(size(finalTrajmin5{traj},1)/2);)
min_frames = ceil(min(cellfun(@(x) size(x,1),finalTrajmin5))/2);
for traj = 1:length(finalTrajmin5)

    % For x min frames, need to check one less min from last to catch
    % anchors at the end
    origins = finalTrajmin5{traj}(1:end - min_frames + 1, 1:2);
    disp_from_origin = pdist2(origins, finalTrajmin5{traj}(:, 1:2));
    
    for start = 1:size(disp_from_origin,1)
        if sum(disp_from_origin(start, start + 1:end) <= threshold_dist) > min_frames
            counter = counter + 1;
            anchored = find(disp_from_origin(start, start:end) <= threshold_dist);
            stuck_anchors(counter, :) = mean(finalTrajmin5{traj}(start - 1 + anchored, 1:2));
            stuck_trajs{counter} = traj;
            break
        end
    end

end

% All of the anchors have been found
stuck_anchors = stuck_anchors(1:counter, :);
stuck_trajs = stuck_trajs(1:counter);

if size(stuck_anchors,1) ~= length(stuck_trajs)
    error('anchors and trajs do not match')
end

%% This is where individual anchors are merged

% Quick merge
[merged_coords, merged_trajs] = FastMergeOverlappingAnchors(stuck_anchors, stuck_trajs, finalTrajmin5, search_radius, LOC_ACC, POINT_DENSITY, MIN_POINTS, min_fraction);

if ~isempty(merged_coords)
    % Merge overlapping anchors and finalize anchors
    [separate_coords, separate_trajs, overlapping_anchors, overlapping_trajs ] = SlowMergeOverlappingAnchors(merged_coords, merged_trajs, finalTrajmin5, search_radius, LOC_ACC, POINT_DENSITY, MIN_POINTS, min_fraction );
    
    % Check for potential overlapping between overlapping but separate anchors
    % and the rest of the anchors
    
    if ~isempty(separate_coords) && ~isempty(overlapping_anchors)
        % Sometimes you get duplicate in 
        [~, b, ~]=intersect(separate_coords(:,1:3), overlapping_anchors(:,1:3),'rows');
        if ~isempty(b)
            separate_coords(b,:)=[];
            separate_trajs(b) = [];
        end
    end

    [anchor_coords, anchor_trajs] = MergeBetweenGroupAnchors(separate_coords, separate_trajs, overlapping_anchors, overlapping_trajs, finalTrajmin5, search_radius, LOC_ACC, POINT_DENSITY, MIN_POINTS, min_fraction );
    
    [final_anchor_coords, final_anchor_trajs] = fixEncompassingAnchors(anchor_coords, anchor_trajs);
else
    final_anchor_coords = merged_coords;
    final_anchor_trajs = merged_trajs;
end
    
end

