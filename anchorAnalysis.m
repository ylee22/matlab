all_combined_final_trajs = who('combFinalTraj*');
radius_and_duration = [];
all_anchor_radii = [];
localization_acc = 30;
% cell area for 12-2-2015: 1.5*1.1*10^9;
% cell area for two color 2-19-2016: 2.5*10^8;
% cell area for EGF treatment = (128*127)^2;
cell_area = 1.5*1.1*10^9;
all_anchored_traj_length = [];
all_free_traj_length = [];
max_disp_anchored_trajs = [];
max_disp_free_trajs = [];
for movie_index=1:length(all_combined_final_trajs)
    % Clear variables, just in case
    clearvars immobile_anchor_coords immobile_anchored_spots immobile_coords cluster_anchor_coords cluster_anchored_traj combined_anchor_coords first_last_anchor_frames converted_to_trajs current_combined_final_traj finalTrajmin5
    
    % Filter by trajectory length
    current_combined_final_traj=eval(all_combined_final_trajs{movie_index});
    finalTrajmin5=minimumTrajLength(current_combined_final_traj,5);
       
    % Find immobile anchors
    [immobile_anchor_coords, immobile_anchored_spots, immobile_coords]=findImmobileAnchors(finalTrajmin5, localization_acc, cell_area);
    
    % Find cluster anchors
    [cluster_anchor_coords, cluster_anchored_traj]=findClusterAnchors(finalTrajmin5, localization_acc, cell_area);
    
    % Combine both types of anchors together
    [~, combined_anchor_coords, first_last_anchor_frames, converted_to_trajs]=combineAnchors(finalTrajmin5,cluster_anchor_coords,cluster_anchored_traj,immobile_coords,immobile_anchor_coords,immobile_anchored_spots,localization_acc, cell_area);
    
filtered_converted_to_trajs=converted_to_trajs(combined_anchor_coords(:,4)>0);
filtered_combined_anchor_coords=combined_anchor_coords(combined_anchor_coords(:,4)>0,:);

if length(filtered_converted_to_trajs) ~= length(filtered_combined_anchor_coords)
    error('rows are mismatched')
end

all_traj_length = zeros(1,length(finalTrajmin5));
for trajID = 1:length(finalTrajmin5)
    all_traj_length(trajID) = size(finalTrajmin5{trajID},1);
end

% Filter artifacts
lt100_anchor_coords = filtered_combined_anchor_coords(filtered_combined_anchor_coords(:,1)<=100,:);
lt100_trajs = filtered_converted_to_trajs(filtered_combined_anchor_coords(:,1)<=100);

% anchored and free trajectories Subtract the first element (row number in
% the original traj, sometimes DBSCAN separates into multiple anchors)
anchored_traj_rows = zeros(1,sum(cellfun(@numel,lt100_trajs))-numel(lt100_trajs));
COUNTER = 1;
for anchorID = 1:numel(lt100_trajs)
    % Unpack trajectory array        
    current_trajs = lt100_trajs{anchorID}(2:end);
    anchored_traj_rows(COUNTER:COUNTER+numel(current_trajs)-1) = current_trajs;
    COUNTER = COUNTER + numel(current_trajs);
end

if ismember(0,anchored_traj_rows)
    error('anchored_traj_rows COUNTER is off')
end

% Separate rows into anchored and non-anchored and store their lengths
% Some trajectories are stuck in multiple anchors
% May have to fix this in the future
anchored_traj_rows = unique(anchored_traj_rows);

% Find the rows that are not anchored
free_traj_rows = setdiff(1:numel(finalTrajmin5), anchored_traj_rows);

    % Find the length of all trajectories
    all_traj_length = zeros(1,length(finalTrajmin5));
    for trajID = 1:length(finalTrajmin5)
        all_traj_length(trajID) = size(finalTrajmin5{trajID},1);
    end
    
    [ anchored_frames ] = framesInAnchor( lt100_trajs, lt100_anchor_coords, finalTrajmin5, movie_index );
        
    % Store anchored and free trajectory lengths
    all_anchored_traj_length = cat(2, all_anchored_traj_length, all_traj_length(anchored_traj_rows));
    all_free_traj_length = cat(2, all_free_traj_length, all_traj_length(free_traj_rows));
    
    % Store the maximum displacement for anchored and free trajectories
    max_disp_anchored_trajs = [max_disp_anchored_trajs, maxDisplacement(finalTrajmin5(anchored_traj_rows))];
    max_disp_free_trajs = [max_disp_free_trajs, maxDisplacement(finalTrajmin5(free_traj_rows))];
    
    % Store all anchor radii
    all_anchor_radii=cat(1,all_anchor_radii,lt100_anchor_coords(:,1));
    
    % Store anchor radius and duration for the anchors with > 1 trajectory
    % (prefer at least 2 trajectories to calculate anchor duration)
    radius_and_duration = cat(1,radius_and_duration,[lt100_anchor_coords(first_last_anchor_frames(:,1),1), (first_last_anchor_frames(:,3)-first_last_anchor_frames(:,2))]);
    
    % Plot the movie
%     plotVariableAnchorSizes(finalTrajmin5, combined_anchor_coords);
        
end

% frame_interval = 0.025;
% 
% % Histogram of anchor life times (aggregate data from all the movies)
% figure
% hist(radius_and_duration(:,2)*frame_interval, 100)
% xlabel('Anchor Duration in sec')
% ylabel('Number of Anchors')
% 
% % Boxplot of anchor life times
% figure
% boxplot(radius_and_duration(:,2)*frame_interval)
% ylabel('Anchor Duration in sec')
% xlabel('Combined Anchors from 13 Movies')
% 
% % Histogram of anchor radii (aggregate data from all the movies)
% figure
% hist(all_anchor_radii, 100)
% xlabel('Anchor Radius in nm')
% ylabel('Number of Anchors')
% 
% % Boxplot of anchor radii
% figure
% boxplot(all_anchor_radii)
% ylabel('Anchor Radius in nm')
% xlabel('Combined Anchors from 13 Movies')
% 
% % Scatter plot of anchor life time and anchor size
% figure
% scatter(radius_and_duration(:,1), radius_and_duration(:,2)*frame_interval)
% xlabel('Anchor Radius in nm')
% ylabel('Anchor Duration in sec')