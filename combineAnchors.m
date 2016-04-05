function [ flattened_trajs_spots, larger_anchor_coords, first_last_anchor_frames, trajs ] = combineAnchors( finalTraj, cluster_anchor_coords, cluster_trajs, immobile_coords, immobile_anchor_coords, immobile_spots, LOC_ACC, CELL_AREA )
% Summary: This function combines the cluster and immobile anchors
% together, returns the finalized anchor (radius, center, duration) and the
% trajectories and or the immobile spots used to define the anchor

% Inputs:
%   finalTraj: output from Tao's SMT that's been modified (segmented 
%   trajectories reconnected and filtered for minimum length). 
%   Cell array with each entry referring to a unique trajectory. 
%   Each entry (trajectory) is an n by 7 matrix:
%       1. x coordinate in nms (converted to nms from Tao's SMT)
%       2. y coordinate in nms (converted to nms from Tao's SMT)
%       3. the starting index in cordata.coords_smt (referring to the output from wfiread, the .coor file)
%       4. the index number in finalTraj
%       5. frame number
%       6. starting frame number
%       7. ending frame number

%   cluster_anchor_coords: cell array with each index, i, representing search
%   radius of 20i nms. Under each index is a n by 2 matrix with x and y 
%   cluster anchor center coordinates

%   cluster_trajs: cell array with vectors referring to the finalTraj
%   index. Each vector in cluster_trajs was used to define the respective 
%   index (anchor) in cluster_anchor_coords

%   immobile_coords: n by 5 matrix of all consecutive frame displacement
%   (frame i to i+1) less than the localization accuracy
%   [traj row number in finalTraj, 1st frame, 2nd frame, averaged x, averaged y]

%   immobile_anchor_coords: cell array with each index, i, representing search
%   radius of 20i nms. Under each index is a n by 2 matrix with x and y
%   immobile anchor center coordinates

%   immobile_spots: cell array with vectors referring to the
%   immobile_coords index. Each vector in immobile_spots was used to define
%   the respective index (anchor) in immobile_anchor_coords

%   localization_acc: localization accuracy of the movie

% Problem: a single trajectory can be stuck in multiple anchors
% Fix this problem by using trajectories and center coord for cluster
% anchors, and spots and immobile coord for immobile clusters
% {{[-1: trajectories],[-2: spots]}}
% The larger anchor trajs will have to be redone with -1 in front


% 1. Assign cluster set and immobile set to larger_trajs,
% larger_anchor_coords, larger_coords and smaller_trajs,
% smaller_anchor_coords, smaller_coords
% Will merge fewer anchors into more anchors
if length(immobile_spots) > length(cluster_trajs)
    
    % Need to mark traj vs spots
    % -1 refers to larger set, -2 refers to smaller set
    larger_trajs = cell(1,length(immobile_spots));
    for size_idx = 1:length(immobile_spots)
        for spot_row = 1:length(immobile_spots{size_idx})
            larger_trajs{size_idx}{spot_row} = [-1 immobile_spots{size_idx}{spot_row}];
        end
    end

    larger_anchor_coords = immobile_anchor_coords;
    larger_coords = immobile_coords(:,4:5);
    
    smaller_trajs = cell(1,length(cluster_trajs));
    for radius_idx = 1:length(cluster_trajs)
        for traj_row = 1:length(cluster_trajs{radius_idx})
            smaller_trajs{radius_idx}{traj_row} = [-2 cluster_trajs{radius_idx}{traj_row}];
        end
    end
    
    smaller_anchor_coords = cluster_anchor_coords;
    smaller_coords = finalTraj;
else
    
    larger_trajs = cell(1,length(cluster_trajs));
    for size_idx = 1:length(cluster_trajs)
        for traj_row = 1:length(cluster_trajs{size_idx})
            larger_trajs{size_idx}{traj_row}=[-1 cluster_trajs{size_idx}{traj_row}];
        end
    end
    
    larger_anchor_coords = cluster_anchor_coords;
    larger_coords = finalTraj;
    
    smaller_trajs = cell(1,length(immobile_spots));
    for radius_idx = 1:length(immobile_spots)
        for spot_row = 1:length(immobile_spots{radius_idx})
            smaller_trajs{radius_idx}{spot_row} = [-2 immobile_spots{radius_idx}{spot_row}];
        end
    end
    
    smaller_anchor_coords = immobile_anchor_coords;
    smaller_coords = immobile_coords(:,4:5);
end


% 2. Look for overlaps between every pair of anchor sizes of the larger set
% and the smaller set. There shouldn't be any overlaps within each sets,
% that should have been covered in the findImmobileAnchors and
% findClusterAnchors. The trajs and anchor_coords should have the same
% number of anchors (same length).
for combined_idx = 1:length(larger_trajs)
    for merged_idx = 1:length(smaller_trajs)
        
        if combined_idx >= merged_idx
            if ~isempty(larger_anchor_coords{combined_idx}) && ~isempty(smaller_anchor_coords{merged_idx})
                % KD tree and the search happens in the function
                % Both anchor lists are modified
                [merged_trajs, larger_trajs{combined_idx}, larger_anchor_coords{combined_idx}, smaller_trajs{merged_idx}, smaller_anchor_coords{merged_idx}] = mergeOverlappingAnchorTrajs(larger_trajs{combined_idx}, larger_anchor_coords{combined_idx}, smaller_trajs{merged_idx}, smaller_anchor_coords{merged_idx}, LOC_ACC*(combined_idx + merged_idx)*1.1);
                
                % Remake the coords using trajectory center coordinates
                large_merged_coords = findAnchorCenter(merged_trajs,larger_coords,smaller_coords);
                
                % Add the merged trajectories and coords
                larger_trajs{combined_idx} = cat(2,larger_trajs{combined_idx},merged_trajs);
                larger_anchor_coords{combined_idx} = cat(1,larger_anchor_coords{combined_idx},large_merged_coords);
            end
            
        elseif merged_idx > combined_idx
            if ~isempty(larger_anchor_coords{combined_idx}) && ~isempty(smaller_anchor_coords{merged_idx})
                [merged_trajs, smaller_trajs{merged_idx}, smaller_anchor_coords{merged_idx}, larger_trajs{combined_idx}, larger_anchor_coords{combined_idx}] = mergeOverlappingAnchorTrajs(smaller_trajs{merged_idx}, smaller_anchor_coords{merged_idx}, larger_trajs{combined_idx}, larger_anchor_coords{combined_idx}, LOC_ACC*(combined_idx + merged_idx)*1.1);

                % Remake the coords using trajectory center coordinates
                large_merged_coords = findAnchorCenter(merged_trajs,larger_coords,smaller_coords);
                
                % Add merged trajectories and coords
                larger_trajs{merged_idx} = cat(2,larger_trajs{merged_idx},merged_trajs);
                larger_anchor_coords{merged_idx} = cat(1,larger_anchor_coords{merged_idx},large_merged_coords);
            end
        end
        
    end
end


% 3. After every merging every combination between the two sets, the left
% over anchors in the smaller have no overlaps.
% Add the smaller anchor array to the end of the larger anchor array
for remaining_anchor_idx = 1:length(smaller_trajs)
    if ~isempty(smaller_trajs{remaining_anchor_idx})

        if ~isempty(larger_trajs{remaining_anchor_idx}) && ~iscell(larger_trajs{remaining_anchor_idx})
            error('Trajectory array has a non-empty vector instead of a cell aray')
        end
        
        larger_trajs{remaining_anchor_idx} = cat(2,larger_trajs{remaining_anchor_idx},smaller_trajs{remaining_anchor_idx});
    end
end


% 4. Flatten combined_trajs into just a cell array instead of a nested
% array. It will loose anchor radius information but it will be remade with
% DBSCAN. If an anchor has both trajs and spots, it will be a cell array,
% otherwise it will just be a vector
flattened_trajs_spots = cell(1,sum(cellfun(@length,larger_trajs)));
flattened_counter = 0;
for outer_idx = 1:length(larger_trajs)
    if ~isempty(larger_trajs{outer_idx})
        for inner_idx = 1:length(larger_trajs{outer_idx})
            flattened_counter = flattened_counter + 1;
            flattened_trajs_spots{flattened_counter} = larger_trajs{outer_idx}{inner_idx};
        end
    end
end


% 5. Redefine anchor center and radius using the list of trajectories and
% spots from above. Need to convert immobile spots/immobile coord indices
% into trajectories/finalTraj row indices. 
% Clear out larger_anchor_coords variable. Will be storing anchor 
% information here.
TOTAL_NUMBER_OF_POINTS = 0;
for row_idx = 1:length(finalTraj)
    TOTAL_NUMBER_OF_POINTS = TOTAL_NUMBER_OF_POINTS + size(finalTraj{row_idx},1);
end
GLOBAL_DENSITY = TOTAL_NUMBER_OF_POINTS/CELL_AREA;

larger_anchor_coords = zeros(2*length(flattened_trajs_spots),4);
trajs = cell(1,2*length(flattened_trajs_spots));
COUNTER = 1;
% Fix anchor coords and radius using DBSCAN
for anchor_idx = 1:length(flattened_trajs_spots)
    % larger_coords is finalTraj, so -1 (1st) is cluster and -2 (2nd) is
    % immobile
    if iscell(larger_coords)
        % If both
        if iscell(flattened_trajs_spots{anchor_idx})
            [anchor_properties, converted_to_traj] = anchorRadiusandCoord(larger_coords,immobile_coords(flattened_trajs_spots{anchor_idx}{2}(2:end),:),flattened_trajs_spots{anchor_idx}{1}(2:end),LOC_ACC,GLOBAL_DENSITY);
            % Sometimes DBSCAN gives multiple anchors, resulting in
            % mismatched rows between flattened_trajs_spots and
            % larger_anchor_coords/trajs. The first element in trajs,
            % indicated in negative, is the matching row number in
            % flattened_trajs_spots.
            for z = 1:size(anchor_properties,1)
                larger_anchor_coords(COUNTER,:) = anchor_properties(z,:);
                trajs{COUNTER} = cat(2,[-anchor_idx, flattened_trajs_spots{anchor_idx}{1}(2:end)], converted_to_traj);
                COUNTER = COUNTER + 1;
            end
        % If cluster only
        elseif flattened_trajs_spots{anchor_idx}(1) == -1
            [anchor_properties, ~] = anchorRadiusandCoord(larger_coords,[],flattened_trajs_spots{anchor_idx}(2:end),LOC_ACC,GLOBAL_DENSITY);
            for z = 1:size(anchor_properties,1)
                larger_anchor_coords(COUNTER,:) = anchor_properties(z,:);
                trajs{COUNTER} = [-anchor_idx, flattened_trajs_spots{anchor_idx}(2:end)];
                COUNTER = COUNTER + 1;
            end
        % If immobile only
        elseif flattened_trajs_spots{anchor_idx}(1) == -2
            % Immobile anchor radius and coordinates
            [anchor_properties, converted_to_traj] = anchorRadiusandCoord(larger_coords,immobile_coords(flattened_trajs_spots{anchor_idx}(2:end),:),[],LOC_ACC,GLOBAL_DENSITY);
            for z = 1:size(anchor_properties,1)
                larger_anchor_coords(COUNTER,:) = anchor_properties(z,:);
                trajs{COUNTER} = [-anchor_idx, converted_to_traj];
                COUNTER = COUNTER + 1;
            end
        end
        
    % smaller_coords is finalTraj, so -1 (1st) is immobile and -2 (2nd) is
    % cluster
    else
        % If larger_coords is finalTraj and this anchor is immobile only
        if iscell(flattened_trajs_spots{anchor_idx})
            [anchor_properties, converted_to_traj] = anchorRadiusandCoord(smaller_coords,immobile_coords(flattened_trajs_spots{anchor_idx}{1}(2:end),:),flattened_trajs_spots{anchor_idx}{2}(2:end),LOC_ACC,GLOBAL_DENSITY);
            for z = 1:size(anchor_properties,1)
                larger_anchor_coords(COUNTER,:) = anchor_properties(z,:);
                trajs{COUNTER} = cat(2,[-anchor_idx, flattened_trajs_spots{anchor_idx}{2}(2:end)], converted_to_traj);
                COUNTER = COUNTER + 1;
            end
        % If immobile only
        elseif flattened_trajs_spots{anchor_idx}(1) == -1
            [anchor_properties, converted_to_traj] = anchorRadiusandCoord(smaller_coords,immobile_coords(flattened_trajs_spots{anchor_idx}(2:end),:),[],LOC_ACC,GLOBAL_DENSITY);
            for z = 1:size(anchor_properties,1)
                larger_anchor_coords(COUNTER,:) = anchor_properties(z,:);
                trajs{COUNTER} = [-anchor_idx, converted_to_traj];
                COUNTER = COUNTER + 1;
            end
        % If cluster only
        elseif flattened_trajs_spots{anchor_idx}(1) == -2
            [anchor_properties, ~] = anchorRadiusandCoord(smaller_coords,[],flattened_trajs_spots{anchor_idx}(2:end),LOC_ACC,GLOBAL_DENSITY);
            for z = 1:size(anchor_properties,1)
                larger_anchor_coords(COUNTER,:) = anchor_properties(z,:);
                trajs{COUNTER} = [-anchor_idx, flattened_trajs_spots{anchor_idx}(2:end)];
                COUNTER = COUNTER + 1;
            end
        end
    end
        
end

% Get rid of empty, unused rows
larger_anchor_coords = larger_anchor_coords(1:COUNTER-1,:);
trajs = trajs(1:COUNTER-1);


% 6. Now that anchor radii and centers have been somewhat finalized,
% recheck for overlaps. FLATTENED_TRAJS_SPOTS DOES NOT MATCH
% LARGER_ANCHOR_COORDS. LARGER_ANCHOR_COORDS IS MATCHED WITH TRAJS.
% I can't make a kd tree for all of them because each anchor is going to
% have a different search radius (anchor radius)

DUPLICATE_MARKER = 1;
while DUPLICATE_MARKER
    DUPLICATE_MARKER = 0;
    anchor_tree = KDTreeSearcher(larger_anchor_coords(:,2:3));
    % A n by 2 list of two closest anchors
    overlaps = knnsearch(anchor_tree, larger_anchor_coords(:,2:3), 'K', 2);
    overlap_idx = [];
    for anchor = 1:length(overlaps)
        % If the anchor pair is within the first anchor's radius, keep the
        % index in the overlap_idx list
        if pdist2(larger_anchor_coords(overlaps(anchor,1),2:3),larger_anchor_coords(overlaps(anchor,2),2:3)) <= larger_anchor_coords(overlaps(anchor,1),1) + larger_anchor_coords(overlaps(anchor,2),1)
            overlap_idx(end+1) = anchor;
        end
    end
    
    % Mark duplicate rows for removal
    % For every index of overlapping pairs of anchors
    for duplicate_idx = 1:numel(overlap_idx)       
        % If the second overlapping anchor is also in the overlap index
        % list and the second anchor's first anchor is the same as the
        % second's first anchor
        if ismember(overlaps(overlap_idx(duplicate_idx),2), overlap_idx) && overlaps(overlaps(overlap_idx(duplicate_idx),2),2) == overlaps(overlap_idx(duplicate_idx),1)
            % Mark for removal
            overlap_idx(duplicate_idx) = -1;
        end
    end

    % Remove duplicate rows, if there are any
    if sum(overlap_idx > 0) > 0
        overlaps = overlaps(overlap_idx(overlap_idx>0), :);
        DUPLICATE_MARKER = 1;
    % If there were no overlaps, stop the while loop
    elseif isempty(overlap_idx)
        overlaps = [];
        DUPLICATE_MARKER = 0;
    end

    % Merge trajectory spots and get the new combined trajectories
    for i = 1:size(overlaps,1)

        % If there are empty trajectories, that means DUPLICATE_MARKER = 1
        if isempty(trajs{overlaps(i,1)}) || isempty(trajs{overlaps(i,2)})
            continue

        else
        
            % The merged anchor index for flattened_trajs_spots
            current_anchor = -trajs{overlaps(i,1)}(1);
            merged_anchor = -trajs{overlaps(i,2)}(1);
            flattened_trajs_spots{current_anchor} = combineTrajsandSpots(flattened_trajs_spots{current_anchor},flattened_trajs_spots{merged_anchor});
            
            % Sometimes, one anchor that was split into two by the first
            % DBSCAN overlaps after one of the anchors increased in side
            % after merging with a different anchor
            if current_anchor ~= merged_anchor
                flattened_trajs_spots{merged_anchor} = [];               
            end

            % Combine trajectories here
            combined_trajs = unique([trajs{overlaps(i,1)}, trajs{overlaps(i,2)}(2:end)]);

            % Remove trajectories and anchor coordinates associated with
            % both current and merged rows of flattened_trajs_spots, since
            % current and merged will both be remade in the next DBSCAN run
            [larger_anchor_coords, trajs] = removeRedundantTrajsandCoords(overlaps(i,1), trajs, larger_anchor_coords);
            [larger_anchor_coords, trajs] = removeRedundantTrajsandCoords(overlaps(i,2), trajs, larger_anchor_coords);
            
            % Mark old coordinates and trajs for deletion
            larger_anchor_coords(overlaps(i,:),:) = NaN;
            trajs{overlaps(i,1)} = [];
            trajs{overlaps(i,2)} = [];        

            if iscell(larger_coords)
                % Replace, remake center and radius
                if iscell(flattened_trajs_spots{current_anchor})
                    % Both
                    [anchor_properties, ~] = anchorRadiusandCoord(larger_coords,immobile_coords(flattened_trajs_spots{current_anchor}{2}(2:end),:),flattened_trajs_spots{current_anchor}{1}(2:end),LOC_ACC,GLOBAL_DENSITY);
                    for z = 1:size(anchor_properties,1)
                        larger_anchor_coords(end+1,:) = anchor_properties(z,:);
                        % Filter out for duplicated trajs (can happen with immobile spots)
                        trajs{end+1} = combined_trajs;
                    end
                elseif ~iscell(flattened_trajs_spots{current_anchor}) && flattened_trajs_spots{current_anchor}(1) == -2
                    % Immobile
                    [anchor_properties, ~] = anchorRadiusandCoord(larger_coords,immobile_coords(flattened_trajs_spots{current_anchor}(2:end),:),[],LOC_ACC,GLOBAL_DENSITY);
                    for z = 1:size(anchor_properties,1)
                        larger_anchor_coords(end+1,:) = anchor_properties(z,:);
                        % Filter out for duplicated trajs (can happen with immobile spots)
                        trajs{end+1} = combined_trajs;
                    end
                else
                    % Cluster
                    [anchor_properties, ~] = anchorRadiusandCoord(larger_coords,[],flattened_trajs_spots{current_anchor}(2:end),LOC_ACC,GLOBAL_DENSITY);
                    for z = 1:size(anchor_properties,1)
                        larger_anchor_coords(end+1,:) = anchor_properties(z,:);
                        % Filter out for duplicated trajs (can happen with immobile spots)
                        trajs{end+1} = combined_trajs;
                    end
                end
            else
                if iscell(flattened_trajs_spots{current_anchor})
                    % Both
                    [anchor_properties, ~] = anchorRadiusandCoord(smaller_coords,immobile_coords(flattened_trajs_spots{current_anchor}{1}(2:end),:),flattened_trajs_spots{current_anchor}{2}(2:end),LOC_ACC,GLOBAL_DENSITY);
                    for z = 1:size(anchor_properties,1)
                        larger_anchor_coords(end+1,:) = anchor_properties(z,:);
                        % Filter out for duplicated trajs (can happen with immobile spots)
                        trajs{end+1} = combined_trajs;
                    end
                elseif ~iscell(flattened_trajs_spots{current_anchor}) && flattened_trajs_spots{current_anchor}(1) == -1
                    % Immobile
                    [anchor_properties, ~] = anchorRadiusandCoord(smaller_coords,immobile_coords(flattened_trajs_spots{current_anchor}(2:end),:),[],LOC_ACC,GLOBAL_DENSITY);
                    for z = 1:size(anchor_properties,1)
                        larger_anchor_coords(end+1,:) = anchor_properties(z,:);
                        % Filter out for duplicated trajs (can happen with immobile spots)
                        trajs{end+1} = combined_trajs;
                    end
                else
                    % Cluster
                    [anchor_properties, ~] = anchorRadiusandCoord(smaller_coords,[],flattened_trajs_spots{current_anchor}(2:end),LOC_ACC,GLOBAL_DENSITY);
                    for z = 1:size(anchor_properties,1)
                        larger_anchor_coords(end+1,:) = anchor_properties(z,:);
                        % Filter out for duplicated trajs (can happen with immobile spots)
                        trajs{end+1} = combined_trajs;
                    end
                end
            end        
        end
    end
end

% Remove the anchor coordinates that's been merged
larger_anchor_coords = larger_anchor_coords(~cellfun(@isempty,trajs),:);
% Remove empty trajs
trajs = filterTraj(trajs,2);
% Get rid of empty arrays
flattened_trajs_spots = filterTraj(flattened_trajs_spots,1);

% Freak out if length of trajs doesn't match larger_anchor_coords
if numel(trajs) ~= length(larger_anchor_coords)
    error('trajectory cell does not match combined anchor coords list')
end


% 7. Find anchor duration for anchors with more than one anchored
% trajectory

% Find anchor duration. Get the starting and the ending frame numbers for
% all of the trajectories in each anchor
anchor_frames = frameNumbers(trajs, finalTraj);

% Get the first and last frames for all of the anchors
first_last_anchor_frames = firstLastFrame(anchor_frames);

end

% NEED TO FIX TO ALLOW OUT OF BOUNDS ON ONLY ONE SIDE NOT BOTH
function [larger_anchor_coords, trajs] = removeRedundantTrajsandCoords(row_idx, trajs, larger_anchor_coords)
    WINDOW = 1;
    REPEAT = 1;
    % sometimes the array is empty (trajs{row_idx-/+WINDOW}, so can't index into it
    while REPEAT
        REPEAT = 0;
        % Check lower bound
        if row_idx - WINDOW > 0 && ~isempty(trajs{row_idx - WINDOW})
            % Anchors from the same source are added next to each other
            if trajs{row_idx - WINDOW}(1) == trajs{row_idx}(1)
                larger_anchor_coords(row_idx - WINDOW,:) = NaN;
                trajs{row_idx - WINDOW} = [];
                REPEAT = 1;
            end
        end
        
        % Check upper bound
        if row_idx + WINDOW <= numel(trajs) && ~isempty(trajs{row_idx + WINDOW})
            if trajs{row_idx + WINDOW}(1) == trajs{row_idx}(1)
                larger_anchor_coords(row_idx + WINDOW,:) = NaN;
                trajs{row_idx + WINDOW} = [];
                REPEAT = 1;
            end
        end
        
        WINDOW = WINDOW + 1;
    end
    
end


function combined_trajs_and_spots = combineTrajsandSpots(trajs_and_spots1, trajs_and_spots2)
    if iscell(trajs_and_spots1)
        if iscell(trajs_and_spots2)
            combined_trajs_and_spots = {unique([trajs_and_spots1{1}, trajs_and_spots2{1}(2:end)]), unique([trajs_and_spots1{2}, trajs_and_spots2{2}(2:end)])};
        elseif trajs_and_spots2(1) == -1
            combined_trajs_and_spots = {unique([trajs_and_spots1{1}, trajs_and_spots2(2:end)]), trajs_and_spots1{2}};
        elseif trajs_and_spots2(1) == -2
            combined_trajs_and_spots = {trajs_and_spots1{1}, unique([trajs_and_spots1{2}, trajs_and_spots2(2:end)])};
        else
            error('Marker does not exist')
        end

    elseif trajs_and_spots1(1) == -1
        if iscell(trajs_and_spots2)
            combined_trajs_and_spots = {unique([trajs_and_spots2{1}, trajs_and_spots1(2:end)]), trajs_and_spots2{2}};
        elseif trajs_and_spots2(1) == -1
            combined_trajs_and_spots = unique([trajs_and_spots1, trajs_and_spots2(2:end)]);
        elseif trajs_and_spots2(1) == -2
            combined_trajs_and_spots = {trajs_and_spots1, trajs_and_spots2};
        else
            error('Marker does not exist')
        end

    elseif trajs_and_spots1(1) == -2
        if iscell(trajs_and_spots2)
            combined_trajs_and_spots = {trajs_and_spots2{1}, unique([trajs_and_spots2{2}, trajs_and_spots1(2:end)])};
        elseif trajs_and_spots2(1) == -1
            combined_trajs_and_spots = {trajs_and_spots2, trajs_and_spots1};
        elseif trajs_and_spots2(1) == -2
            combined_trajs_and_spots = unique([trajs_and_spots1, trajs_and_spots2(2:end)]);
        else
            error('Marker does not exist')
        end

    else
        error('Marker does not exist')
    end

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
            % 3 columns: anchor row ID, first, last The first element is
            % negative (the corresponding index in flattened_trajs_spots)
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
    first_last_frames = zeros(length(anchor_frames), 3);
    for q = 1:length(anchor_frames)
        first_last_frames(q,:)=[anchor_frames{q}(1,1), min(anchor_frames{q}(:,2)), max(anchor_frames{q}(:,3))];
    end
end


function [combined_trajs, larger_anchor_trajs, larger_anchor_coords, smaller_anchor_trajs, smaller_anchor_coords] = mergeOverlappingAnchorTrajs(larger_anchor_trajs, larger_anchor_coords, smaller_anchor_trajs, smaller_anchor_coords, SEARCH_RADIUS)
% Combines anchored trajectories to the larger array and removes combined
% anchor coordinates and trajectories
% Will generate new anchor coordinates after this function is called
    combined_trajs = {};
    kd_tree = KDTreeSearcher(smaller_anchor_coords);
    overlapping_anchors = rangesearch(kd_tree,larger_anchor_coords,SEARCH_RADIUS);

    for larger_anchor_idx = 1:length(larger_anchor_trajs)
        % If there are overlapping smaller anchors
        if ~isempty(overlapping_anchors{larger_anchor_idx})
            smaller_anchors = overlapping_anchors{larger_anchor_idx};

            % Hold combined trajectories in the combined_trajs variable
            % LARGER AND SMALLER HERE DOESN'T MEAN THE ONE THAT'S
            % GETTING MERGED AND THE ARRAY THAT'S GOING TO REMAIN

            for small_idx = 1:length(smaller_anchors)
                if ~isempty(smaller_anchor_trajs{smaller_anchors(small_idx)})
                    combined_trajs_and_spots = combineTrajsandSpots(larger_anchor_trajs{larger_anchor_idx},smaller_anchor_trajs{smaller_anchors(small_idx)});
                    combined_trajs{end+1} = combined_trajs_and_spots;
                    % Remove smaller anchor trajs/spots
                    smaller_anchor_trajs{smaller_anchors(small_idx)} = [];
                end
            end

            % Remove larger anchor trajs/spots
            larger_anchor_trajs{larger_anchor_idx} = [];
        end
    end

    % Remove the anchor coordinates that's been merged
    smaller_anchor_coords = smaller_anchor_coords(~cellfun(@isempty,smaller_anchor_trajs),:);
    larger_anchor_coords = larger_anchor_coords(~cellfun(@isempty,larger_anchor_trajs),:);
    % Get rid of empty arrays in smaller anchor trajectories
    smaller_anchor_trajs = filterTraj(smaller_anchor_trajs,1);
    larger_anchor_trajs = filterTraj(larger_anchor_trajs,1);
        
end


function pre_anchor_coords = findAnchorCenter(trajsandspots,larger_coords,smaller_coords)
    % Find new anchor coordinates and add them to the anchor_coords
    pre_anchor_coords=zeros(length(trajsandspots),2);
    % center_coords are the centroids for all trajectories
    for n=1:length(trajsandspots)
        
        if trajsandspots{n}{1}(1) ~= -1 || trajsandspots{n}{2}(1) ~= -2
            error('Marker error')
        end
        
        larger = trajsandspots{n}{1}(2:end);
        smaller = trajsandspots{n}{2}(2:end);
        
        if iscell(larger_coords)
            traj_coords = anchoredFrameCoords(larger_coords, larger);
            x_coords = [traj_coords(:,1);smaller_coords(smaller,1)];
            y_coords = [traj_coords(:,2);smaller_coords(smaller,2)];
        else
            traj_coords = anchoredFrameCoords(smaller_coords, smaller);
            x_coords = [larger_coords(larger,1);traj_coords(:,1)];
            y_coords = [larger_coords(larger,2);traj_coords(:,2)];
        end
        
        pre_anchor_coords(n,:)=[mean(x_coords),mean(y_coords)];
    end
end