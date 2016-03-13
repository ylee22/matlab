all_combFinalTrajs = who('combFinalTraj*');
radius_and_duration = [];
all_anchor_radii = [];
localization_acc = 20;
% cell area for 12-2-2015: 1.5*1.1*10^9
% cell area for two color 2-19-2016: 2.5*10^8;
cell_area = (128*127)^2;
all_anchored_traj_length = [];
all_free_traj_length = [];
for movie_index=1:length(all_combFinalTrajs)
    % Filter by trajectory length
    current_combFinalTraj=eval(all_combFinalTrajs{movie_index});
    finalTrajmin5=minimumTrajLength(current_combFinalTraj,5);
    
    % Find immobile anchors
    [immobile_anchor_coords, immobile_anchored_spots, immobile_coords]=findImmobileAnchors(finalTrajmin5, localization_acc, cell_area);
    
    % Find cluster anchors
    [cluster_anchor_coords, cluster_anchored_traj]=findDiffSizedAnchors(finalTrajmin5, localization_acc, cell_area);
    
    % Combine both types of anchors together
    [~, combined_anchor_coords, first_last_anchor_frames, converted_to_trajs]=combineAnchors(finalTrajmin5,cluster_anchor_coords,cluster_anchored_traj,immobile_coords,immobile_anchor_coords,immobile_anchored_spots,localization_acc);

    % Find the length of all trajectories
    all_traj_length = zeros(1,length(finalTrajmin5));
    for trajID = 1:length(finalTrajmin5)
        all_traj_length(trajID) = size(finalTrajmin5{trajID},1);
    end
    
    % Find the anchored trajectorie rows
    anchored_traj_rows = [];
    outside_anchor_trajs = [];
    for anchorID = 1:length(converted_to_trajs)
        % Unpack trajectory array
        anchored_traj_rows = cat(2, anchored_traj_rows, converted_to_trajs{anchorID});
        
        % Find the number of consecutive frames anchored traj spends
        % within their anchor
        for traj = 1:length(converted_to_trajs{anchorID})
            current_traj = converted_to_trajs{anchorID}(traj);
            radius = combined_anchor_coords(anchorID,1);
            anchor_coords = combined_anchor_coords(anchorID,2:3);
            all_x_y = finalTrajmin5{current_traj}(:,1:2);
            % Trajectory needs to start and finish outside of an anchor
            if ((all_x_y(1,1)<(anchor_coords(1)-radius) || all_x_y(1,1)>(anchor_coords(1)+radius)) || (all_x_y(1,2)<(anchor_coords(2)-radius) || all_x_y(1,2)>(anchor_coords(2)+radius))) && ((all_x_y(end,1)<(anchor_coords(1)-radius) || all_x_y(end,1)>(anchor_coords(1)+radius)) || (all_x_y(end,2)<(anchor_coords(2)-radius) || all_x_y(end,2)>(anchor_coords(2)+radius)))
                % Need to know the anchor radius and position as well as
                % the row number on finalTrajmin5
                outside_anchor_trajs = cat(1,outside_anchor_trajs,[combined_anchor_coords(anchorID,:) current_traj, anchorID]);
            end
        end
        
    end
    
    % Some trajectories are stuck in multiple anchors
    % May have to fix this in the future
    anchored_traj_rows = unique(anchored_traj_rows);
    
    % Find the rows that are not anchored
    non_anchored_traj_rows = setdiff([1:length(finalTrajmin5)], anchored_traj_rows);
    
    % Store anchored and free trajectory lengths
    all_anchored_traj_length = cat(2, all_anchored_traj_length, all_traj_length(anchored_traj_rows));
    all_free_traj_length = cat(2, all_free_traj_length, all_traj_length(non_anchored_traj_rows));
    
    % Store all anchor radii
    all_anchor_radii=cat(1,all_anchor_radii,combined_anchor_coords(:,1));
    
    % Store anchor radius and duration for the anchors with > 1 trajectory
    % (prefer at least 2 trajectories to calculate anchor duration)
    radius_and_duration = cat(1,radius_and_duration,[combined_anchor_coords(first_last_anchor_frames(:,1),1), (first_last_anchor_frames(:,3)-first_last_anchor_frames(:,2))]);
    
%     % Plot the movie
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

% makeAnchorPlots(new_first_last_frames, 20)