function [ first_last_anchor_frames ] = anchorDuration( finalTraj, trajs )

% THIS FUNCTION USED TO BE THE LAST STEP IN combineAnchors.m

% 7. Find anchor duration for anchors with more than one anchored
% trajectory

% Find anchor duration. Get the starting and the ending frame numbers for
% all of the trajectories in each anchor
anchor_frames = frameNumbers(trajs, finalTraj);

% Get the first and last frames for all of the anchors
first_last_anchor_frames = firstLastFrame(anchor_frames);
end

% Get the starting and the ending frame numbers for all of the trajectories in each anchor
function anchor_frames = frameNumbers(anchored_trajectories, allTraj)
    anchor_frames = cell(1,sum(cellfun(@length, anchored_trajectories) > 2));
    frame_idx = 0;
    for a = 1:numel(anchored_trajectories)
        % Screen for anchors with more than one trajectory, the first element
        % is a marker for flattened_trajs_spots
        if numel(anchored_trajectories{a}) > 2
            frame_idx = frame_idx + 1;
            % 3 columns: anchor row ID, first, last
            % The first element is negative (the corresponding index in flattened_trajs_spots)
            firstandlast = zeros(numel(anchored_trajectories{a}) - 1, 3);
            for b = 2:numel(anchored_trajectories{a})
                firstandlast(b-1,:) = [a, allTraj{anchored_trajectories{a}(b)}(1,6:7)];
            end
            anchor_frames{frame_idx} = firstandlast;
        end
    end
end


% Find the first and the last frame for each anchor
function first_last_frames = firstLastFrame(anchor_frames)
    % OUTPUT: 3 columns: anchor row ID on filtered_combined_anchor_coords
    % list, first, and last frame number for each anchor
    first_last_frames = zeros(length(anchor_frames), 3);
    for q = 1:length(anchor_frames)
        first_last_frames(q,:)=[anchor_frames{q}(1,1), min(anchor_frames{q}(:,2)), max(anchor_frames{q}(:,3))];
    end
end

