all_RAS_combFinalTrajs = who('combFinalTrajRAS*');
all_RAF_combFinalTrajs = who('combFinalTrajRAF*');
localization_acc = 20;
cell_area = 2.5*10^8;

for movie_index = 1:length(all_RAS_combFinalTrajs)
    % Select the current RAS movie
    current_RAS_Traj = eval(all_RAS_combFinalTrajs{movie_index});

    % First, find anchor coordinates from the RAS trajectories, then plot
    % the RAF trajectories on top of the anchors

    % Find immobile anchors
    [immobile_anchor_coords, immobile_anchored_spots, immobile_coords]=findImmobileAnchors(current_RAS_Traj, localization_acc, cell_area);

    % Find cluster anchors
    [cluster_anchor_coords, cluster_anchored_traj]=findDiffSizedAnchors(current_RAS_Traj, localization_acc, cell_area);

    % Combine both types of anchors together
    [~, combined_anchor_coords, first_last_anchor_frames, converted_to_trajs]=combineAnchors(current_RAS_Traj,cluster_anchor_coords,cluster_anchored_traj,immobile_coords,immobile_anchor_coords,immobile_anchored_spots,localization_acc);

    % Select the current RAF movie
    current_RAF_Traj = eval(all_RAF_combFinalTrajs{movie_index});
    
    % Plot the anchors and the corresponding RAF trajectories
    
    % ROTATE RAS TRAJS/ANCHORS 90 DEGREES TO THE RIGHT!!!
    % Find the center rotation point
    % Need to know the size of the frame 
    % Currently 128 by 128 pixels, 127 nm per pixel
    x_center = 128*127/2;
    y_center = 128*127/2;
    center = repmat([x_center; y_center], 1, length(combined_anchor_coords));
    
    % Define the rotation
    theta = -pi/2;
    
    % Shift the coordinates so that the center is the origin
    shifted_anchor_coords = combined_anchor_coords(:,2:3)' - center;
    
    % Rotation matrix
    R = [cos(theta) -sin(theta); sin(theta) cos(theta)];
    
    % Rotate by 90 degrees to the right and shift the coordinates back
    rotated_anchor_coords = R*shifted_anchor_coords + center;
    
    combined_anchor_coords(:,2:3) = rotated_anchor_coords';
    
    plotAnchorsandRAFs(combined_anchor_coords, current_RAF_Traj)
end