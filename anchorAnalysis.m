all_combFinalTrajs = who('combFinalTraj*');
radius_and_duration = [];
all_anchor_radii = [];
localization_acc = 20;
% cell area for 12-2-2015: 1.5*1.1*10^9;
% cell area for two color 2-19-2016: 2.5*10^8;
% cell area for EGF treatment = (128*127)^2;
cell_area = (128*127)^2;
all_anchored_traj_length = [];
all_free_traj_length = [];
outside_anchor_trajs = [];
for movie_index=1:length(all_combFinalTrajs)
    % Filter by trajectory length
    current_combFinalTraj=eval(all_combFinalTrajs{movie_index});
    finalTrajmin5=minimumTrajLength(current_combFinalTraj,5);
    
    % Find immobile anchors
    [immobile_anchor_coords, immobile_anchored_spots, immobile_coords]=findImmobileAnchors(finalTrajmin5, localization_acc, cell_area);
    
    % Find cluster anchors
    [cluster_anchor_coords, cluster_anchored_traj]=findClusterAnchors(finalTrajmin5, localization_acc, cell_area);
    
    % Combine both types of anchors together
    [~, combined_anchor_coords, first_last_anchor_frames, converted_to_trajs]=combineAnchors(finalTrajmin5,cluster_anchor_coords,cluster_anchored_traj,immobile_coords,immobile_anchor_coords,immobile_anchored_spots,localization_acc, cell_area);
    
    % Find the length of all trajectories
    all_traj_length = zeros(1,length(finalTrajmin5));
    for trajID = 1:length(finalTrajmin5)
        all_traj_length(trajID) = size(finalTrajmin5{trajID},1);
    end
    
    % Find which trajectories start and finish outside of anchors
    % Find the anchored trajectorie rows
    anchored_traj_rows = zeros(1,sum(cellfun(@numel,converted_to_trajs))-numel(converted_to_trajs));
    COUNTER = 1;
    for anchorID = 1:numel(converted_to_trajs)
                
        current_trajs = converted_to_trajs{anchorID}(2:end);
        % Unpack trajectory array
        anchored_traj_rows(COUNTER:COUNTER+numel(current_trajs)-1) = current_trajs;
        COUNTER = COUNTER + numel(current_trajs);
        
%         radius = combined_anchor_coords(anchorID, 1);
%         anchor_coords = combined_anchor_coords(anchorID, 2:3);
%         
%         % Plot
%         figure
%         plotTrajectories(finalTrajmin5(current_trajs))
%         ang=0:0.01:2*pi;
%         hold on;
%         plot(anchor_coords(1,1)+radius*cos(ang),anchor_coords(1,2)+radius*sin(ang),'r')        
%         
%         % Find the number of consecutive frames anchored traj spends
%         % within their anchor
%         for traj_idx = 1:numel(current_trajs)
%             traj = current_trajs(traj_idx);
%             traj_x_y = finalTrajmin5{traj}(:, 1:2);
% 
%             % Trajectory needs to start and finish outside of an anchor
%             % Check the first and the last frame of the trajectory to see
%             % if it's outside of the anchor boundary
%             if (traj_x_y(1,1)<(anchor_coords(1)-radius) || traj_x_y(1,1)>(anchor_coords(1)+radius) || traj_x_y(1,2)<(anchor_coords(2)-radius) || traj_x_y(1,2)>(anchor_coords(2)+radius)) && (traj_x_y(end,1)<(anchor_coords(1)-radius) || traj_x_y(end,1)>(anchor_coords(1)+radius) || traj_x_y(end,2)<(anchor_coords(2)-radius) || traj_x_y(end,2)>(anchor_coords(2)+radius))
%                 % Find the duration that it stayed within the anchor
%                 frame_idx = 1;
%                 first_frame = 0;
%                 while frame_idx && frame_idx <= size(traj_x_y,1)
%                     % Find the first frame where it enters the anchor: x
%                     % and y coordinates must be within the anchor boundary
%                     if traj_x_y(frame_idx,1)>=(anchor_coords(1)-radius) && traj_x_y(frame_idx,1)<=(anchor_coords(1)+radius) && traj_x_y(frame_idx,2)>=(anchor_coords(2)-radius) && traj_x_y(frame_idx,2)<=(anchor_coords(2)+radius)
%                         first_frame = frame_idx;
%                         consec_frames = first_frame + 1;
%                         % Count the number of frames it stays within the
%                         % anchor
%                         while traj_x_y(consec_frames,1)>=(anchor_coords(1)-radius) && traj_x_y(consec_frames,1)<=(anchor_coords(1)+radius) && traj_x_y(consec_frames,2)>=(anchor_coords(2)-radius) && traj_x_y(consec_frames,2)<=(anchor_coords(2)+radius)
%                             consec_frames = consec_frames + 1;
%                         end
%                         last_frame = consec_frames - 1;
%                     % Continue searching
%                     else
%                         frame_idx = frame_idx + 1;
%                     end
%                     
%                     % If the anchored frames have been found
%                     if first_frame > 0
%                         % Skip cases where the trajectory didn't stay in the anchor
%                         if first_frame == last_frame
%                             % Go on to the next frame and keep searching
%                             frame_idx = frame_idx + 1;
%                             % Reset the first_frame
%                             first_frame = 0;
%                         % If duration > 1
%                         else
%                             % [last frame in anchor, first frame in anchor, trajectory ID (finalTrajmin5 row), anchor ID, movie ID]
%                             % Problem with this method is that it doesn't account for
%                             % cases where the trajectory goes back inside an anchor
%                             % after leaving
%                             outside_anchor_trajs = cat(1,outside_anchor_trajs,[first_frame, last_frame, traj, anchorID, movie_index]);
%                             % Break the while loop
%                             frame_idx = 0;
%                         end
%                     end
%                 end
%             
%                 % Plot the trajectory, frames stuck in anchor and anchor
%                 hold on;
%                 plot(traj_x_y(:,1),traj_x_y(:,2))
%                 if first_frame > 0
%                     hold on;
%                     scatter(traj_x_y(first_frame:last_frame,1),traj_x_y(first_frame:last_frame,2))
%                 end
%                 axis image
%             end
%         end
    end
    
    % Separate rows into anchored and non-anchored and store their lengths
    % Some trajectories are stuck in multiple anchors
    % May have to fix this in the future
    anchored_traj_rows = unique(anchored_traj_rows);
    
    % Find the rows that are not anchored
    non_anchored_traj_rows = setdiff([1:numel(finalTrajmin5)], anchored_traj_rows);
    
    % Store anchored and free trajectory lengths
    all_anchored_traj_length = cat(2, all_anchored_traj_length, all_traj_length(anchored_traj_rows));
    all_free_traj_length = cat(2, all_free_traj_length, all_traj_length(non_anchored_traj_rows));
    
    % Store all anchor radii
    all_anchor_radii=cat(1,all_anchor_radii,combined_anchor_coords(:,1));
    
    % Store anchor radius and duration for the anchors with > 1 trajectory
    % (prefer at least 2 trajectories to calculate anchor duration)
    radius_and_duration = cat(1,radius_and_duration,[combined_anchor_coords(first_last_anchor_frames(:,1),1), (first_last_anchor_frames(:,3)-first_last_anchor_frames(:,2))]);
    
    % Plot the movie
    plotVariableAnchorSizes(finalTrajmin5, combined_anchor_coords);
        
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