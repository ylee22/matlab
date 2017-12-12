function [ final_anchor, final_trajs, overlapping_anchors, overlapping_trajs ] = SlowMergeOverlappingAnchors( final_anchor, final_trajs, finalTrajmin5, SEARCH_RADIUS, LOC_ACC, POINT_DENSITY, ABS_MIN_POINTS, min_fraction )
% 6. Now that anchor radii and centers have been somewhat finalized,
% recheck for overlaps. FLATTENED_TRAJS_SPOTS DOES NOT MATCH
% LARGER_ANCHOR_COORDS. LARGER_ANCHOR_COORDS IS MATCHED WITH TRAJS.
% I can't make a kd tree for all of them because each anchor is going to
% have a different search radius (anchor radius)

% There has to be at least 2 anchors to see if they overlap
% Need 2 different lists, one for anchors that will get checked for
% overlaps and another list for holding onto 2 separate but overlapping
% anchors as defined by dbscan
overlapping_anchors = [];
overlapping_trajs = [];
DUPLICATE_MARKER = 1;
overlay_group = 0;
while DUPLICATE_MARKER && numel(final_trajs) > 1
    anchor_tree = KDTreeSearcher(final_anchor(:, 2:3));
    % A n by 2 list of two closest anchors
    overlaps = knnsearch(anchor_tree, final_anchor(:,2:3), 'K', 2);
    
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
    for anchor = 1:size(overlaps, 1)
        % this is duplicate
        if pdist(final_anchor(overlaps(anchor, :), 2:3)) == 0
            final_anchor(overlaps(anchor, 1), :) = NaN;
            final_trajs{overlaps(anchor, 1)} = [];
        % if it is overlapping, add to the overlap_idx
        elseif pdist(final_anchor(overlaps(anchor, :), 2:3)) <= sum(final_anchor(overlaps(anchor, :), 1))
            counter = counter + 1;
            overlap_idx(counter) = anchor;
        end
    end
    
    overlap_idx = overlap_idx(1:counter);
    
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
    for i = 1:size(overlaps, 1)

        % If there are empty trajectories, that means DUPLICATE_MARKER = 1,
        % these were merged earlier in the for loop
        if isempty(final_trajs{overlaps(i, 1)}) || isempty(final_trajs{overlaps(i, 2)})
            continue

        else
            
            % Combine trajectories here
            combined_trajs = unique([final_trajs{overlaps(i, :)}]);
           
            % Mark old coordinates and trajs for deletion
            final_anchor(overlaps(i,:),:) = NaN;
            final_trajs{overlaps(i,1)} = [];
            final_trajs{overlaps(i,2)} = [];
            
            % Remake and add to the end
            % traj_coords: cell array of 1 x number of trajs with number of
            % frames x 2 matrix
            trajs_coords = {};
            [trajs_coords{1:length(combined_trajs)}] = deal(finalTrajmin5{combined_trajs});
            trajs_coords = cellfun(@(x) x(:,1:2), trajs_coords, 'UniformOutput', false);
            
            [anchor_coords, anchor_trajs] = dbscanAnchor(SEARCH_RADIUS, LOC_ACC, POINT_DENSITY, trajs_coords, combined_trajs, ABS_MIN_POINTS, min_fraction);
            
            % if didn't find the first time
            if isempty(anchor_coords)
                min_fraction2 = 3;
                [anchor_coords, anchor_trajs] = dbscanAnchor(SEARCH_RADIUS, LOC_ACC, POINT_DENSITY, trajs_coords, combined_trajs, ABS_MIN_POINTS, min_fraction2);
            end
            
             % check to see if one is actually encompassed in the other
            if size(anchor_coords, 1) > 1
                [r, c] = find(triu(squareform(pdist(anchor_coords(:,2:3)))) == min(pdist(anchor_coords(:,2:3))));

                if min(pdist(anchor_coords(:,2:3))) < max(anchor_coords([r, c], 1))
                    min_fraction2 = 4;
                    [anchor_coords, anchor_trajs] = dbscanAnchor(SEARCH_RADIUS, LOC_ACC, POINT_DENSITY, trajs_coords, combined_trajs, ABS_MIN_POINTS, min_fraction2);
                end
            end
            
            % add it to this list will check for overlaps
            if size(anchor_coords, 1) == 1
                % 4 columns: [radius, x, y, sum(all points in anchor)]
                final_anchor = cat(1, final_anchor, anchor_coords);

                % holds trajectories (finalTrajmin5 row number)
                final_trajs = cat(2, final_trajs, anchor_trajs);
                
            % add it to this list to not check for overlaps (infinite while
            % loop with dbscan separating 2 overlapping anchors)
            elseif size(anchor_coords, 1) > 1
                
                % last column indicates the overlap group (need it for next
                % merge function)
                overlay_group = overlay_group + 1;
                overlapping_anchors = cat(1, overlapping_anchors, [anchor_coords repmat(overlay_group, numel(anchor_trajs), 1)]);
                overlapping_trajs = cat(2, overlapping_trajs, anchor_trajs);
                
            end
            
            if size(final_anchor, 1) ~= length(final_trajs)
                error('final coords and trajs do not match')
                
            elseif size(overlapping_anchors, 1) ~= length(overlapping_trajs)
                error('overlapping coords and trajs do not match')
            end
             
        end
    end
    
    % Remove the anchor coordinates that's been merged
    final_anchor = final_anchor(~cellfun(@isempty, final_trajs), :);
    % Remove empty trajs
    final_trajs = filterTraj(final_trajs, 1);

    % if overlaps are increasing, that means forever loop
    
end

end

