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
frames_in_anchor = [];
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
        % Unpack trajectory array        
        current_trajs = converted_to_trajs{anchorID}(2:end);
        anchored_traj_rows(COUNTER:COUNTER+numel(current_trajs)-1) = current_trajs;
        COUNTER = COUNTER + numel(current_trajs);
        
        radius = combined_anchor_coords(anchorID, 1);
        anchor_coords = combined_anchor_coords(anchorID, 2:3);     
        
        % Find the number of consecutive frames anchored traj spends
        % within their anchor
        for traj_idx = 1:numel(current_trajs)
            
            anchored_frames = [];
            
            traj = current_trajs(traj_idx);
            traj_x_y = finalTrajmin5{traj}(:, 1:2);

            % Trajectory needs to start and finish outside of an anchor
            % Check the first and the last frame of the trajectory to see
            % if it's outside of the anchor boundary
            if (traj_x_y(1,1)<(anchor_coords(1)-radius) || traj_x_y(1,1)>(anchor_coords(1)+radius) || traj_x_y(1,2)<(anchor_coords(2)-radius) || traj_x_y(1,2)>(anchor_coords(2)+radius)) && (traj_x_y(end,1)<(anchor_coords(1)-radius) || traj_x_y(end,1)>(anchor_coords(1)+radius) || traj_x_y(end,2)<(anchor_coords(2)-radius) || traj_x_y(end,2)>(anchor_coords(2)+radius))
                % Find the duration that it stayed within the anchor
                frame_idx = 1;
                first_frame = 0;
                while frame_idx <= size(traj_x_y,1)
                    % Find the first frame where it enters the anchor: x
                    % and y coordinates must be within the anchor boundary
                    if traj_x_y(frame_idx,1)>=(anchor_coords(1)-radius) && traj_x_y(frame_idx,1)<=(anchor_coords(1)+radius) && traj_x_y(frame_idx,2)>=(anchor_coords(2)-radius) && traj_x_y(frame_idx,2)<=(anchor_coords(2)+radius)
                        first_frame = frame_idx;
                        consec_frames = first_frame + 1;
                        % Count the number of frames it stays within the
                        % anchor
                        while traj_x_y(consec_frames,1)>=(anchor_coords(1)-radius) && traj_x_y(consec_frames,1)<=(anchor_coords(1)+radius) && traj_x_y(consec_frames,2)>=(anchor_coords(2)-radius) && traj_x_y(consec_frames,2)<=(anchor_coords(2)+radius)
                            consec_frames = consec_frames + 1;
                        end
                        last_frame = consec_frames - 1;
                    % Continue searching
                    else
                        frame_idx = frame_idx + 1;
                    end
                    
                    % If the anchored frames have been found
                    if first_frame > 0
                        anchored_frames(end+1,:) = [first_frame, last_frame];
                        frame_idx = last_frame + 1;
                        first_frame = 0;
                    end
                end
                
                if size(anchored_frames,1)>2
                    % Find places where it only left for one frame and came
                    % back and piece it together
                    idx = find(anchored_frames(2:end,1)-anchored_frames(1:end-1,2)==2);
                    anchored_frames(idx,2) = anchored_frames(idx+1,2);
                    % I have to loop through it backwards because the
                    % longest will be at the front of the list
                    for i = 0:numel(idx)-2
                        if idx(end-i)-idx(end-i-1) == 1
                            anchored_frames(idx(end-i-1),2) = anchored_frames(idx(end-i),2);
                        end
                    end
                    [~, max_idx] = max(anchored_frames(:,2)-anchored_frames(:,1));
                    % If the trajectory stayed in the anchor for more than
                    % 1 frame
                    if anchored_frames(max_idx,2)-anchored_frames(max_idx,1) > 1
                        % [first frame in anchor, last frame in anchor, trajectory ID (finalTrajmin5 row), anchor ID, movie ID]
                        frames_in_anchor(end+1,:) = [anchored_frames(max_idx,:), traj, anchorID, movie_index];
                    end
                end
            end
        end
    end
    
    if ismember(0,anchored_traj_rows)
        error('anchored_traj_rows COUNTER is off')
    end
    
    % Separate rows into anchored and non-anchored and store their lengths
    % Some trajectories are stuck in multiple anchors
    % May have to fix this in the future
    anchored_traj_rows = unique(anchored_traj_rows);
    
    % Find the rows that are not anchored
    free_traj_rows = setdiff([1:numel(finalTrajmin5)], anchored_traj_rows);
    
    % Store anchored and free trajectory lengths
    all_anchored_traj_length = cat(2, all_anchored_traj_length, all_traj_length(anchored_traj_rows));
    all_free_traj_length = cat(2, all_free_traj_length, all_traj_length(free_traj_rows));
    
    % Store the maximum displacement for anchored and free trajectories
    max_disp_anchored_trajs = [max_disp_anchored_trajs, maxDisplacement(finalTrajmin5(anchored_traj_rows))];
    max_disp_free_trajs = [max_disp_free_trajs, maxDisplacement(finalTrajmin5(free_traj_rows))];
    
    % Store all anchor radii
    all_anchor_radii=cat(1,all_anchor_radii,combined_anchor_coords(:,1));
    
    % Store anchor radius and duration for the anchors with > 1 trajectory
    % (prefer at least 2 trajectories to calculate anchor duration)
    radius_and_duration = cat(1,radius_and_duration,[combined_anchor_coords(first_last_anchor_frames(:,1),1), (first_last_anchor_frames(:,3)-first_last_anchor_frames(:,2))]);
    
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