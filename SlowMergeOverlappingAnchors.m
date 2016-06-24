function [ anchor_coords, anchor_trajs ] = SlowMergeOverlappingAnchors( anchor_coords, anchor_trajs, finalTrajmin5, search_radius, min_points, LOC_ACC, GLOBAL_DENSITY )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

% 6. Now that anchor radii and centers have been somewhat finalized,
% recheck for overlaps. FLATTENED_TRAJS_SPOTS DOES NOT MATCH
% LARGER_ANCHOR_COORDS. LARGER_ANCHOR_COORDS IS MATCHED WITH TRAJS.
% I can't make a kd tree for all of them because each anchor is going to
% have a different search radius (anchor radius)

DUPLICATE_MARKER = 1;
while DUPLICATE_MARKER
    DUPLICATE_MARKER = 0;
    anchor_tree = KDTreeSearcher(anchor_coords(:,2:3));
    % A n by 2 list of two closest anchors
    overlaps = knnsearch(anchor_tree, anchor_coords(:,2:3), 'K', 2);
    
    % Remove duplicates
    for duplicate = 1:length(overlaps)
        overlapping_pair = sort(overlaps(overlaps(duplicate,:),:), 2);
        if overlapping_pair(1,:) == overlapping_pair(2,:)
            overlaps(duplicate,:) = -1;
        end
    end
    
    overlaps = overlaps(overlaps(:,1)>0,:);
    
    % Look for overlaps
    overlap_idx = zeros(1,size(overlaps,1));
    counter = 0;
    for anchor = 1:length(overlaps)
        if pdist(anchor_coords(overlaps(anchor,:),2:3)) == 0
            anchor_coords(overlaps(anchor, 1),:) = NaN;
            anchor_trajs{overlaps(anchor,1)} = [];
        elseif pdist(anchor_coords(overlaps(anchor,:),2:3)) <= sum(anchor_coords(overlaps(anchor,:),1))
            counter = counter + 1;
            overlap_idx(counter) = anchor;
        end
    end
    
    overlap_idx = overlap_idx(1:counter);
    
    size(overlap_idx)
    
    % Remove duplicate rows, if there are any
    % If there were no overlaps, stop the while loop
    if isempty(overlap_idx)
        overlaps = [];
        DUPLICATE_MARKER = 0;
    else
        overlaps = overlaps(overlap_idx, :);
        DUPLICATE_MARKER = 1;
    end

    % Merge trajectory spots and get the new combined trajectories
    for i = 1:size(overlaps,1)
        % Merge trajectories
        % Remove merged trajectories
        % Remake radius and centers

        % If there are empty trajectories, that means DUPLICATE_MARKER = 1,
        % these were merged earlier in the for loop
        if isempty(anchor_trajs{overlaps(i,1)}) || isempty(anchor_trajs{overlaps(i,2)})
            continue

        else
            
            % Combine trajectories here
            combined_trajs = unique([anchor_trajs{overlaps(i,:)}]);
           
            % Mark old coordinates and trajs for deletion
            anchor_coords(overlaps(i,:),:) = NaN;
            anchor_trajs{overlaps(i,1)} = [];
            anchor_trajs{overlaps(i,2)} = [];
            
            % Remake and add to the end
            [anchored_coords, ~] = anchoredFrameCoords(finalTrajmin5, combined_trajs);
            
            radius_coord_dbscanID = dbscanAnchor(anchored_coords, search_radius, min_points, LOC_ACC, GLOBAL_DENSITY);
            % 5 columns: [radius, x, y, dbscan cluster ID]
            anchor_coords = cat(1, anchor_coords, radius_coord_dbscanID);
            
            for idx = 1:size(radius_coord_dbscanID, 1)
                % holds trajectories (finalTrajmin5 row number)
                anchor_trajs{end+1} = combined_trajs;
            end
            
            if size(anchor_coords,1) ~= length(anchor_trajs)
                error('coords and trajs do not match')
            end
             
        end
    end
    
    % Remove the anchor coordinates that's been merged
    anchor_coords = anchor_coords(~cellfun(@isempty,anchor_trajs),:);
    % Remove empty trajs
    anchor_trajs = filterTraj(anchor_trajs,1);

end

end

