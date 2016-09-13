cd /mnt/data0/yerim/Trajectory_Analysis/findDiffSizedAnchors/4.19.2016/fixed_duplicate_traj_rows/currently_analyzing

file_list = dir('*.mat');

for idx = 1:length(file_list)
    
    cd /mnt/data0/yerim/Trajectory_Analysis/findDiffSizedAnchors/4.19.2016/fixed_duplicate_traj_rows/currently_analyzing
    
    load(file_list(idx).name, 'finalTrajmin5', 'cluster_anchored_traj', 'immobile_anchored_spots', 'immobile_coords', 'cell_area', 'filtered_converted_to_trajs', 'filtered_combined_anchor_coords')

    cd /mnt/data0/yerim/Trajectory_Analysis/findDiffSizedAnchors/codes
    
    % Search radius is for dbscan
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

    threshold_dist = 100;
    % find anchors by total variation analysis
    [ anchor_coords_2, anchor_trajs_2 ] = TotalVariationAnchors( finalTrajmin5, search_radius, POINT_DENSITY, LOC_ACC, threshold_dist );

    % Merge two different types of anchors together
    [ anchor_coords, anchor_trajs ] = MergeTwoDifferentAnchorTypes( anchor_coords_1, anchor_coords_2, anchor_trajs_1, anchor_trajs_2, LOC_ACC, POINT_DENSITY, finalTrajmin5, search_radius );

    fixed_converted_to_trajs = cell(1,length(filtered_converted_to_trajs));
    for i=1:length(filtered_converted_to_trajs)
        fixed_converted_to_trajs{i}=filtered_converted_to_trajs{i}(2:end);
    end
    [anchor_coords_3, anchor_trajs_3] = MergeTwoDifferentAnchorTypes(anchor_coords, filtered_combined_anchor_coords, anchor_trajs, fixed_converted_to_trajs, LOC_ACC, POINT_DENSITY, finalTrajmin5, search_radius);
    
    cd /mnt/data0/yerim/Trajectory_Analysis/findDiffSizedAnchors/4.19.2016/fixed_duplicate_traj_rows/total_var_100_dbscan_50
    
    save(file_list(idx).name)
    
    clearvars -except file_list idx
end