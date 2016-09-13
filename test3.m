frames_in_anchor = [];
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
                        frames_in_anchor(end+1,:) = [anchored_frames(max_idx,:), traj, anchorID];
                    end
                end
            end
        end
    end
    
    % Separate rows into anchored and non-anchored and store their lengths
    % Some trajectories are stuck in multiple anchors
    % May have to fix this in the future
    anchored_traj_rows = unique(anchored_traj_rows);
    
    % Find the rows that are not anchored
    non_anchored_traj_rows = setdiff([1:numel(finalTrajmin5)], anchored_traj_rows);