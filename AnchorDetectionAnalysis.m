simulated_length_5 = minimumTrajLength(recorded_trajectories, 5);
cell_area = cell_width^2;

finalTrajmin5 = cell(1, length(simulated_length_5));
for i = 1:length(simulated_length_5)
    % 1: x, 2: y, 3-4: filler, 5: frame number, 6: starting frame number,
    % 7: ending frame number
    start_frame = simulated_length_5{i}(1, end);
    end_frame = simulated_length_5{i}(end, end);
    traj_length = size(simulated_length_5{i}, 1);
    finalTrajmin5{i} = [simulated_length_5{i}(:, 1:2), zeros(traj_length, 2), simulated_length_5{i}(:, 5), repmat([start_frame, end_frame],traj_length,1)];
end

% immobile_coords = [];
% for i = 1:length(finalTrajmin5)
%     for j = 1:size(finalTrajmin5{i},1)-1
%         if pdist2(finalTrajmin5{i}(j,1:2), finalTrajmin5{i}(j+1,1:2)) < LOC_ACC
%             immobile_coords(end+1,:) = [i,j,j+1,mean(finalTrajmin5{i}(j:j+1,1:2))];
%         end
%     end
% end
% 
% % Find immobile anchors
% [immobile_anchor_coords, immobile_anchored_spots, immobile_coords] = findImmobileAnchors(finalTrajmin5, LOC_ACC, cell_area);
% 
% % Check to make sure that the number of anchor coords match the number of
% % anchored spots (should have 1 to 1 mapping between coords and spots)
% if sum(cellfun(@length,immobile_anchor_coords) == 2)
%     count = 0;
%     for row = 1:length(immobile_anchor_coords)
%         count = count + size(immobile_anchor_coords{row},1);
%     end
%     if count ~= sum(cellfun(@length,immobile_anchored_spots))
%         error('immobile anchor and spots do not match')
%     end
% elseif sum(cellfun(@length,immobile_anchor_coords)) ~= sum(cellfun(@length,immobile_anchored_spots))
%     error ('immobile anchor and spots do not match')
% end
% 
% % Find cluster anchors
% [cluster_anchor_coords, cluster_anchored_traj] = findClusterAnchors(finalTrajmin5, LOC_ACC, cell_area);
% 
% % Check to make sure that the number of anchor coords match the number of
% % anchored trajs (should have 1 to 1 mapping between coords and spots)
% if sum(cellfun(@length,cluster_anchor_coords) == 2)
%     count = 0;
%     for row = 1:length(cluster_anchor_coords)
%         count = count + size(cluster_anchor_coords{row},1);
%     end
%     if count ~= sum(cellfun(@length,cluster_anchored_traj))
%         error('cluster anchor and trajs do not match')
%     end
% elseif sum(cellfun(@length,cluster_anchor_coords)) ~= sum(cellfun(@length,cluster_anchored_traj))
%     error('cluster anchor and trajs do not match')
% end
% 
% % Combine both types of anchors together
% [combined_anchor_coords, converted_to_trajs] = combineAnchors(finalTrajmin5,cluster_anchor_coords,cluster_anchored_traj,immobile_coords,immobile_anchor_coords,immobile_anchored_spots,LOC_ACC*1.5, cell_area);
% 
% if sum(combined_anchor_coords(:,4)==0) > 0
%     error('anchors that failed dbscan are being added')
% end
% 
% if length(converted_to_trajs) ~= length(combined_anchor_coords)
%     error('rows are mismatched')
% end

% Search radius is for dbscan
SEARCH_RADIUS = 50;
MIN_POINTS = 3;
LOC_ACC = 20;

% Find the total number of frames/vertices
total_vertices = 0;
for traj_idx = 1:length(finalTrajmin5)
    total_vertices = total_vertices + size(finalTrajmin5{traj_idx}, 1);
end

POINT_DENSITY = total_vertices/cell_area;

% prob_immobile = immobile_vertices/total_vertices;

[ anchor_coords_1, anchor_trajs_1 ] = findClusterAnchors( finalTrajmin5, LOC_ACC, POINT_DENSITY, SEARCH_RADIUS, MIN_POINTS );

[ anchor_coords_2, anchor_trajs_2, immobile_coords ] = findImmobileAnchors( finalTrajmin5, LOC_ACC, POINT_DENSITY, SEARCH_RADIUS, MIN_POINTS );

% % Merge two different types of anchors together
% [ anchor_coords_3, anchor_trajs_3 ] = MergeTwoDifferentAnchorTypes( anchor_coords_1, anchor_coords_2, anchor_trajs_1, anchor_trajs_2, LOC_ACC, POINT_DENSITY, finalTrajmin5, SEARCH_RADIUS );


[ anchor_coords_4, anchor_trajs_4 ] = ImmobileVertexAnchors( finalTrajmin5, search_radius, min_points, POINT_DENSITY, LOC_ACC, immobile_coords, total_vertices );

THRESHOLD_DIST = 100;
% find anchors by total variation analysis
[ anchor_coords_5, anchor_trajs_5 ] = TotalVariationAnchors( finalTrajmin5, search_radius, POINT_DENSITY, LOC_ACC, threshold_dist, MIN_POINTS );

% % Merge two different types of anchors together
% [ anchor_coords_6, anchor_trajs_6 ] = MergeTwoDifferentAnchorTypes( anchor_coords_4, anchor_coords_5, anchor_trajs_4, anchor_trajs_5, LOC_ACC, POINT_DENSITY, finalTrajmin5, SEARCH_RADIUS );
% 
% % Merge two different types of anchors together
% [ final_anchor_coords, final_anchor_trajs ] = MergeTwoDifferentAnchorTypes( anchor_coords_3, anchor_coords_6, anchor_trajs_3, anchor_trajs_6, LOC_ACC, POINT_DENSITY, finalTrajmin5, SEARCH_RADIUS );

% fixed_converted_to_trajs = cell(1,length(converted_to_trajs));
% for i=1:length(converted_to_trajs)
%     fixed_converted_to_trajs{i} = converted_to_trajs{i}(2:end);
% end
% [anchor_coords_3, anchor_trajs_3] = MergeTwoDifferentAnchorTypes(anchor_coords,combined_anchor_coords,anchor_trajs,fixed_converted_to_trajs,LOC_ACC, POINT_DENSITY, finalTrajmin5, search_radius);
