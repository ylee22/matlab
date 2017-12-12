function [ final_anchor, final_trajs ] = dbscanAnchor( search_radius, LOC_ACC, GLOBAL_DENSITY, combined_coords, anchored_trajs, ABS_MIN_POINTS, min_fraction )
% make anchored coords from combined_coords from failed trajs
% find anchors with dbscan
% find failed trajs

failed_trajs = [1:numel(anchored_trajs); anchored_trajs]';
final_anchor = [];
final_trajs = [];

counter = 0;

while ~isempty(failed_trajs)
    
    counter = counter + 1;
    
    if counter > 100
        error('stuck in while loop')
    end
    
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
%     area = pi*max(pdist2(mean(anchored_coords), anchored_coords))^2;
%     density = size(anchored_coords, 1)/area;
%     expected_number_of_points = poissinv(0.95, ceil(density*pi*search_radius^2));
%     min_points = max(min(floor(size(anchored_coords, 1)/min_fraction), expected_number_of_points), ABS_MIN_POINTS);
    min_points = min(max(floor(size(anchored_coords, 1)/min_fraction), ABS_MIN_POINTS), 100);
    
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
                traj_center_inside = pdist2(radius_and_coords(anchor, 2:3), mean(curr_coords)) <= radius_and_coords(anchor, 1);
                % if an anchored traj center isn't inside the anchor and
                % doesn't spend minimum number of frames inside, it's not
                % anchored
                if sum(inside) < ABS_MIN_POINTS && ~(sum(inside) > 2 && traj_center_inside)
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
    if size(radius_and_coords, 1) == 1 && size(failed_trajs, 1) == size(temp_failed_trajs, 1)
        failed_trajs = [];
    % multiple anchors found and none of the trajectories used to define
    % the anchor pass
    elseif size(radius_and_coords, 1) > 1 && size(failed_trajs, 1) == size(temp_failed_trajs, 1)
        search_radius = search_radius + 1;
    else
        failed_trajs = temp_failed_trajs;
        final_anchor = [final_anchor; radius_and_coords(~cellfun(@isempty, temp_final_trajs),:)];
        final_trajs = [final_trajs temp_final_trajs(~cellfun(@isempty, temp_final_trajs))];
    end
    
end

end
