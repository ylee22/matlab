% Find anchors by number of immobile spots per trajectory
% Search radius is for dbscan
SEARCH_RADIUS = 50;
MIN_POINTS = 3;
LOC_ACC = 25;

% Find the total number of frames/vertices
total_vertices = 0;
for traj_idx = 1:length(finalTrajmin5)
    total_vertices = total_vertices + size(finalTrajmin5{traj_idx}, 1);
end

POINT_DENSITY = total_vertices/cell_area;

% prob_immobile = immobile_vertices/total_vertices;

[ anchor_coords_1, anchor_trajs_1 ] = findClusterAnchors(finalTrajmin5, LOC_ACC, POINT_DENSITY, SEARCH_RADIUS );

[ anchor_coords_2, anchor_trajs_2, immobile_coords ] = findImmobileAnchors(finalTrajmin5, LOC_ACC, POINT_DENSITY, SEARCH_RADIUS);

% Merge two different types of anchors together
[ anchor_coords_3, anchor_trajs_3 ] = MergeTwoDifferentAnchorTypes( anchor_coords_1, anchor_coords_2, anchor_trajs_1, anchor_trajs_2, LOC_ACC, POINT_DENSITY, finalTrajmin5, SEARCH_RADIUS );


[ anchor_coords_4, anchor_trajs_4 ] = ImmobileVertexAnchors( finalTrajmin5, SEARCH_RADIUS, MIN_POINTS, POINT_DENSITY, LOC_ACC, immobile_coords, total_vertices );

THRESHOLD_DIST = 100;
% find anchors by total variation analysis
[ anchor_coords_5, anchor_trajs_5 ] = TotalVariationAnchors( finalTrajmin5, SEARCH_RADIUS, POINT_DENSITY, LOC_ACC, THRESHOLD_DIST );

% Merge two different types of anchors together
[ anchor_coords_6, anchor_trajs_6 ] = MergeTwoDifferentAnchorTypes( anchor_coords_4, anchor_coords_5, anchor_trajs_4, anchor_trajs_5, LOC_ACC, POINT_DENSITY, finalTrajmin5, SEARCH_RADIUS );

% Merge two different types of anchors together
[ final_anchor_coords, final_anchor_trajs ] = MergeTwoDifferentAnchorTypes( anchor_coords_3, anchor_coords_6, anchor_trajs_3, anchor_trajs_6, LOC_ACC, POINT_DENSITY, finalTrajmin5, SEARCH_RADIUS );
