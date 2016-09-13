cd /mnt/data0/yerim/Trajectory_Analysis/SS_EGF_data_set/8.11.2016
file_list = dir('*.mat');

cluster_anchors = [];
immobile_anchors = [];
immobile_vertex_anchors = [];
total_variation_anchors = [];
all_anchors = [];

cluster_sizes = [];
immobile_sizes = [];
immobile_vertex_sizes = [];
total_variation_sizes = [];
all_anchor_sizes = [];

% Max distance between two consecutive frames in nm
max_dist = 200;
% Max and min duration in number of frames
max_duration = 125;
min_duration = 5;

for idx = 1:length(file_list)
    
    cd /mnt/data0/yerim/Trajectory_Analysis/SS_EGF_data_set/8.11.2016
    
    load(file_list(idx).name, 'finalTraj')
    
    cd /mnt/data0/yerim/Trajectory_Analysis/findDiffSizedAnchors/codes
    
    % Connect two frames within a distance together (if a frame was skipped)
    [combFinalTraj,~,~] = combineTraj_lessmemory(finalTraj, 2, max_dist);
    
    % Filter out by the minimum and the maximum number of frames
    finalTrajmin5 = min_max_traj_length(combFinalTraj, min_duration, max_duration);
    
    
    max_coords=zeros(length(finalTrajmin5),2);
    min_coords=zeros(length(finalTrajmin5),2);
    for i=1:length(finalTrajmin5)
        max_coords(i,:)=max(finalTrajmin5{i}(:,1:2));
        min_coords(i,:)=min(finalTrajmin5{i}(:,1:2));
    end

    cell_size = max(max_coords) - min(min_coords);
    cell_area = cell_size(1) * cell_size(2);
    
    % Find anchors by number of immobile spots per trajectory
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

    [ anchor_coords_1, anchor_trajs_1 ] = findClusterAnchors(finalTrajmin5, LOC_ACC, POINT_DENSITY, SEARCH_RADIUS );
    
    cluster_anchors = cat(1, cluster_anchors, size(anchor_coords_1, 1));
    cluster_sizes = cat(1, cluster_sizes, anchor_coords_1(:,1));
    
    [ anchor_coords_2, anchor_trajs_2, immobile_coords ] = findImmobileAnchors(finalTrajmin5, LOC_ACC, POINT_DENSITY, SEARCH_RADIUS);
    
    immobile_anchors = cat(1, immobile_anchors, size(anchor_coords_2, 1));
    immobile_sizes = cat(1, immobile_sizes, anchor_coords_2(:,1));

    % Merge two different types of anchors together
    [ anchor_coords_3, anchor_trajs_3 ] = MergeTwoDifferentAnchorTypes( anchor_coords_1, anchor_coords_2, anchor_trajs_1, anchor_trajs_2, LOC_ACC, POINT_DENSITY, finalTrajmin5, SEARCH_RADIUS );

    
    [ anchor_coords_4, anchor_trajs_4 ] = ImmobileVertexAnchors( finalTrajmin5, SEARCH_RADIUS, MIN_POINTS, POINT_DENSITY, LOC_ACC, immobile_coords, total_vertices );
    
    immobile_vertex_anchors = cat(1, immobile_vertex_anchors, size(anchor_coords_4, 1));
    immobile_vertex_sizes = cat(1, immobile_vertex_sizes, anchor_coords_4(:,1));

    THRESHOLD_DIST = 100;
    % find anchors by total variation analysis
    [ anchor_coords_5, anchor_trajs_5 ] = TotalVariationAnchors( finalTrajmin5, SEARCH_RADIUS, POINT_DENSITY, LOC_ACC, THRESHOLD_DIST );

    total_variation_anchors = cat(1, total_variation_anchors, size(anchor_coords_5, 1));
    total_variation_sizes = cat(1, total_variation_sizes, anchor_coords_5(:,1));
    
    % Merge two different types of anchors together
    [ anchor_coords_6, anchor_trajs_6 ] = MergeTwoDifferentAnchorTypes( anchor_coords_4, anchor_coords_5, anchor_trajs_4, anchor_trajs_5, LOC_ACC, POINT_DENSITY, finalTrajmin5, SEARCH_RADIUS );

    % Merge two different types of anchors together
    [ final_anchor_coords, final_anchor_trajs ] = MergeTwoDifferentAnchorTypes( anchor_coords_3, anchor_coords_6, anchor_trajs_3, anchor_trajs_6, LOC_ACC, POINT_DENSITY, finalTrajmin5, SEARCH_RADIUS );

    all_anchors = cat(1, all_anchors, size(final_anchor_coords, 1));
    all_anchor_sizes = cat(1, all_anchor_sizes, final_anchor_coords(:,1));
    
    cd /mnt/data0/yerim/Trajectory_Analysis/findDiffSizedAnchors/SS_EGF_data_set/8.11.2016
    
    save(file_list(idx).name, 'max_dist', 'max_duration', 'min_duration', 'finalTrajmin5', 'cell_size', 'cell_area', 'SEARCH_RADIUS', 'MIN_POINTS', 'LOC_ACC', 'POINT_DENSITY', 'anchor_coords_1', 'anchor_trajs_1', 'anchor_coords_2', 'anchor_trajs_2', 'anchor_coords_3', 'anchor_trajs_3', 'anchor_coords_4', 'anchor_trajs_4','anchor_coords_5', 'anchor_trajs_5', 'anchor_coords_6', 'anchor_trajs_6', 'final_anchor_coords', 'final_anchor_trajs')
    
    clearvars -except max_dist max_duration min_duration file_list idx cluster_anchors immobile_anchors immobile_vertex_anchors total_variation_anchors all_anchors cluster_sizes immobile_sizes immobile_vertex_sizes total_variation_sizes all_anchor_sizes

end