function [ single_anchor_coords, single_anchor_trajs ] = SingleTrajAnchors( finalTrajmin5, search_radius, global_density, loc_acc, threshold_dist, min_points, min_fraction )
% THIS FUNCTION DOES NOT MERGE BUT FINDS ANCHORS FOR INDIVIDUAL
% TRAJECTORIES

stuck_trajs = zeros(1,length(finalTrajmin5));
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
            stuck_trajs(counter) = traj;
            break
        end
    end

end

% All of the anchors have been found
% stuck_anchors = stuck_anchors(1:counter, :);
stuck_trajs = stuck_trajs(1:counter);

counter = 0;
single_anchor_coords = zeros(numel(stuck_trajs), 4);
single_anchor_trajs = zeros(1, numel(stuck_trajs));
% Pass each stuck trajectory to dbscan
for traj = 1:numel(stuck_trajs)
    
    trajs_coords = {finalTrajmin5{stuck_trajs(traj)}(:,1:2)};
    
    [radius_coord, traj_id] = dbscanAnchor(search_radius, loc_acc, global_density, trajs_coords, stuck_trajs(traj), min_points, min_fraction);
    
    % store anchor info
    if numel(traj_id) > 1
        counter = counter + 1;
        single_anchor_coords(counter:counter + numel(traj_id) - 1, :) = radius_coord;
        single_anchor_trajs(counter:counter + numel(traj_id) - 1) = traj_id{:};
    elseif numel(traj_id) == 1
        counter = counter + 1;
        single_anchor_coords(counter, :) = radius_coord;
        single_anchor_trajs(counter) = traj_id{:};
    end
end

single_anchor_coords = single_anchor_coords(1:counter, :);
single_anchor_trajs= single_anchor_trajs(1:counter);

end

