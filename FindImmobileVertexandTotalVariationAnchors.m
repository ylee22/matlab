% Find anchors by number of immobile spots per trajectory
search_radius = 50;
min_points = 3;
LOC_ACC = 25;

% Find the total number of frames/vertices
total_vertices = 0;
for traj_idx = 1:length(finalTrajmin5)
    total_vertices = total_vertices + size(finalTrajmin5{traj_idx}, 1);
end

POINT_DENSITY = total_vertices/cell_area;

% prob_immobile = immobile_vertices/total_vertices;

[ anchor_coords_1, anchor_trajs_1 ] = ImmobileVertexAnchors( finalTrajmin5, search_radius, min_points, POINT_DENSITY, LOC_ACC, immobile_coords, total_vertices );

threshold_dist = 50;
% find anchors by total variation analysis
[ anchor_coords_2, anchor_trajs_2 ] = TotalVariationAnchors( finalTrajmin5, search_radius, POINT_DENSITY, LOC_ACC, threshold_dist );

% Merge two different types of anchors together
[ anchor_coords, anchor_trajs ] = MergeTwoDifferentAnchorTypes( anchor_coords_1, anchor_coords_2, anchor_trajs_1, anchor_trajs_2, LOC_ACC, POINT_DENSITY, finalTrajmin5 );