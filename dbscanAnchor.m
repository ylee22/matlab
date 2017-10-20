function [ final_anchor, final_trajs ] = dbscanAnchor( search_radius, LOC_ACC, GLOBAL_DENSITY, combined_coords, anchored_trajs, ABS_MIN_POINTS, min_fraction )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

% make anchored coords from combined_coords from failed trajs
% find anchors with dbscan
% find failed trajs

failed_trajs = [1:numel(anchored_trajs); anchored_trajs]';
final_anchor = [];
final_trajs = [];

while ~isempty(failed_trajs)
    failed_trajs
    
    % find the anchored coords
    if size(failed_trajs, 1) == 1
        anchored_coords = combined_coords{failed_trajs(1, 1)};
    else
        anchored_coords = zeros(sum(cellfun(@(x) size(x, 1), combined_coords(failed_trajs(:, 1)))), 2);
        c = 1;
        for traj = 1:size(failed_trajs, 1)
            curr_traj = failed_trajs(traj, 1);
            anchored_coords(c:c + size(combined_coords{curr_traj}, 1) - 1, :) = combined_coords{curr_traj};
            c = c + size(combined_coords{curr_traj}, 1);
        end
    end
    
    % find min points here
    min_points = max(floor(size(anchored_coords, 1)/min_fraction), ABS_MIN_POINTS);
    
    % DBSCAN to find clusters/anchors
    [IDX, ~] = dbscan(anchored_coords, search_radius, min_points);

    % Check for overlaps if DBSCAN finds multiple clusters within one anchor
    if max(IDX) > 1
        [ IDX ] = merge_dbscan_overlaps( IDX, anchored_coords, LOC_ACC, search_radius, min_points );
    end

    % Filter here for trajectories with mobile portion
    % IDX = AnchorsWithFreeComponent(IDX, 2, anchored_coords);

    % Save only the anchors that were found by DBSCAN
    if max(IDX) > 0
        [ radius_and_coords ] = finalize_anchor( IDX, anchored_coords, GLOBAL_DENSITY );
        temp_search_radius = search_radius;
        while max(IDX) > 0 && isempty(radius_and_coords) && temp_search_radius > 40
            temp_search_radius = temp_search_radius - 1;
            % DBSCAN to find clusters/anchors
            [IDX, ~] = dbscan(anchored_coords, temp_search_radius, min_points);
            
            % Check for overlaps if DBSCAN finds multiple clusters within one anchor
            if max(IDX) > 1
                [ IDX ] = merge_dbscan_overlaps( IDX, anchored_coords, LOC_ACC, temp_search_radius, min_points );
            end

            [ radius_and_coords ] = finalize_anchor( IDX, anchored_coords, GLOBAL_DENSITY );

        end
    else
        radius_and_coords = [];
    end
    
    temp_final_trajs = cell(1, size(radius_and_coords,1));
    [temp_final_trajs{:}] = deal(failed_trajs(:,2)');
    temp_failed_trajs = [];
    
    % find failed trajs or find 2 separate anchors
    if size(failed_trajs, 1) > 1 && ~isempty(radius_and_coords)
        % for each anchored trajectory, find if it is included in any
        % anchor, remove from the one that's not included
        for i = 1:size(failed_trajs, 1)
            removed_counter = 0;
            for anchor = 1:size(radius_and_coords, 1)
                curr_coords = combined_coords{failed_trajs(i, 1)};
                inside = pdist2(radius_and_coords(anchor, 2:3), curr_coords) <= radius_and_coords(anchor, 1);
%                 if sum(inside) < min(floor(min_points/2), ceil(size(curr_coords, 1)/2))
                if sum(inside) < ABS_MIN_POINTS
                    % if a trajectory is not in the anchor, remove it
                    temp_final_trajs{anchor} = temp_final_trajs{anchor}(temp_final_trajs{anchor} ~= failed_trajs(i, 2));
                    removed_counter = removed_counter + 1;
                end
            end
            
            if removed_counter == size(radius_and_coords, 1)
                % if anchored trajectory isn't included in any anchor,keep
                % track of which trajectories failed
                temp_failed_trajs = [temp_failed_trajs; failed_trajs(i, :)];
            end
        end
    end

    % if an anchor was found but all of the trajectories don't have enough
    % points inside the anchor, it results in an infinite loop
    if ~isempty(radius_and_coords) && size(failed_trajs, 1) == size(temp_failed_trajs, 1)
        final_anchor = [final_anchor; radius_and_coords];
        final_trajs = [final_trajs failed_trajs(:,2)'];
        failed_trajs = [];
    else
        failed_trajs = temp_failed_trajs;
        final_anchor = [final_anchor; radius_and_coords];
        final_trajs = [final_trajs temp_final_trajs];
    end
    
end

end
