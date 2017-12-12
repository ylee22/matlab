function [ all_anchors, all_trajs ] = MergeBetweenGroupAnchors_old(separate_coords, separate_trajs, overlapping_coords, overlapping_trajs, finalTrajmin5, SEARCH_RADIUS, LOC_ACC, POINT_DENSITY, ABS_MIN_POINTS, min_fraction )

all_trajs = cat(2, separate_trajs, overlapping_trajs);
separate_coords = [separate_coords zeros(size(separate_coords, 1), 1)];
all_anchors = cat(1, separate_coords, overlapping_coords);
all_anchors = [all_anchors (1:size(all_anchors, 1))'];
counter = 0;

while sum(all_anchors(:, 5) > 0) > 0

    number_overlapping = sum(all_anchors(:, 5) > 0);
    
    idx = all_anchors(:, 5) > 0;
    overlapping_coords = all_anchors(idx, :);
    overlapping_trajs = all_trajs(idx);
    
    max_group = max(all_anchors(:, 5));

    curr_anchor = overlapping_coords(1, :);
    curr_trajs = overlapping_trajs{1};

    other_idx = (all_anchors(:,5) > -1) & (all_anchors(:, 5) ~= curr_anchor(5));

    other_anchors = all_anchors(other_idx, :);
    other_trajs = all_trajs(other_idx);

    if size(other_anchors, 1) ~= length(other_trajs)
        error('stuff breaking')
    elseif sum(other_idx) == 0
        % only the same group left
        break
    end
    
    % distance between current anchor and the rest of the anchors
    dist = pdist2(curr_anchor(2:3), other_anchors(:, 2:3));
    closest = find(dist==min(dist));
    
    while isequal(curr_trajs, other_trajs{closest})
        % get rid of the duplicate 0
        all_anchors(other_anchors(closest, end), :) = NaN;
        all_trajs{other_anchors(closest, end)} = [];
        dist(closest) = max(dist);
        % fine next closest
        closest = find(dist==min(dist));
    end
    
    % if one is encompassing the other
    if pdist2(curr_anchor(2:3), other_anchors(closest, 2:3)) < max(curr_anchor(1),other_anchors(closest, 1))
        % merge free into group: have to check for actual number of members
        % because groups get broken apart if they get remade (see next
        % condition)
        if curr_anchor(5) > 0 && sum(all_anchors(:, 5) == curr_anchor(5)) > 1 && (other_anchors(closest, 5) == 0 || sum(all_anchors(:, 5) == other_anchors(closest, 5)) == 1)
            % add smaller anchor traj to the larger
            all_trajs{curr_anchor(end)} = cat(2, all_trajs{curr_anchor(end)}, all_trajs{other_anchors(closest, end)});
            
            % delete the old coords and trajs
            all_anchors(other_anchors(closest, end), :) = NaN;
            all_trajs{other_anchors(closest, end)} = [];

            if size(all_anchors, 1) ~= length(all_trajs)
                error('final coords and trajs do not match')
            end
        elseif (curr_anchor(5) == 0 || sum(all_anchors(:, 5) == curr_anchor(5)) == 1) && other_anchors(closest, 5) > 0 && sum(all_anchors(:, 5) == other_anchors(closest, 5)) > 1
            % add smaller anchor traj to the larger
            all_trajs{other_anchors(closest, end)} = cat(2, all_trajs{other_anchors(closest, end)}, all_trajs{curr_anchor(end)});
            
            % delete the old coords and trajs
            all_anchors(curr_anchor(end), :) = NaN;
            all_trajs{curr_anchor(end)} = [];

            if size(all_anchors, 1) ~= length(all_trajs)
                error('final coords and trajs do not match')
            end
        % if both are free or both are in groups, merge smaller into the bigger
        % free + free = 0, group + group = all new group
        elseif curr_anchor(1) > other_anchors(closest, 1)
            % if they're both in groups, then change group IDs for all members
            if curr_anchor(5) + other_anchors(closest, 5) > 0
                % make a new group
                max_group = max_group + 1;
                all_anchors(all_anchors(:,5) == curr_anchor(5), 5) = max_group;
                all_anchors(all_anchors(:,5) == other_anchors(closest, 5), 5) = max_group;
            end
            
            % add smaller anchor traj to the larger
            all_trajs{curr_anchor(end)} = cat(2, all_trajs{curr_anchor(end)}, all_trajs{other_anchors(closest, end)});
            
            % delete the old coords and trajs
            all_anchors(other_anchors(closest, end), :) = NaN;
            all_trajs{other_anchors(closest, end)} = [];

            if size(all_anchors, 1) ~= length(all_trajs)
                error('final coords and trajs do not match')
            end
        else
            % if they're both in groups, then change group IDs for all members
            if curr_anchor(5) + other_anchors(closest, 5) > 0
                % make a new group
                max_group = max_group + 1;
                all_anchors(all_anchors(:,5) == curr_anchor(5), 5) = max_group;
                all_anchors(all_anchors(:,5) == other_anchors(closest, 5), 5) = max_group;
            end
            
            % add smaller anchor traj to the larger
            all_trajs{other_anchors(closest, end)} = cat(2, all_trajs{other_anchors(closest, end)}, all_trajs{curr_anchor(end)});
            
            % delete the old coords and trajs
            all_anchors(curr_anchor(end), :) = NaN;
            all_trajs{curr_anchor(end)} = [];

            if size(all_anchors, 1) ~= length(all_trajs)
                error('final coords and trajs do not match')
            end
        end
    % if they are overlapping, then merge them
    elseif curr_anchor(1) + other_anchors(closest, 1) > dist(closest)

        % find which trajectories are involved
        combined_trajs = unique([curr_trajs other_trajs{closest}]);

        % traj_coords: cell array of 1 x number of trajs with number of
        % frames x 2 matrix
        trajs_coords = {};
        [trajs_coords{1:length(combined_trajs)}] = deal(finalTrajmin5{combined_trajs});
        trajs_coords = cellfun(@(x) x(:,1:2), trajs_coords, 'UniformOutput', false);

        [anchor_coords, anchor_trajs] = dbscanAnchor(SEARCH_RADIUS, LOC_ACC, POINT_DENSITY, trajs_coords, combined_trajs, ABS_MIN_POINTS, min_fraction);
        
        % check to see if one is actually encompassed in the other
        if numel(anchor_trajs) > 1
            [r, c] = find(triu(squareform(pdist(anchor_coords(:,2:3)))) == min(pdist(anchor_coords(:,2:3))));

            if min(pdist(anchor_coords(:,2:3))) < max(anchor_coords([r, c], 1))
                min_fraction2 = 4;
                [anchor_coords, anchor_trajs] = dbscanAnchor(SEARCH_RADIUS, LOC_ACC, POINT_DENSITY, trajs_coords, combined_trajs, ABS_MIN_POINTS, min_fraction2);
            end
        end

        % if it's the same, don't run it next time
        if isempty(anchor_coords)
            all_anchors(curr_anchor(end), 5) = 0;

        % if input is exactly the same as output
        elseif isequal(cellfun(@sort, anchor_trajs, 'UniformOutput', false), {sort(curr_trajs), sort(other_trajs{closest})}) || isequal(cellfun(@sort, anchor_trajs, 'UniformOutput', false), {sort(other_trajs{closest}), sort(curr_trajs)})
            all_anchors(curr_anchor(end), 5) = 0;

        % if it's 2 different anchors
        elseif size(anchor_coords, 1) > 1
            % make a new group
            max_group = max_group + 1;

            last_idx = size(all_anchors, 1);
            all_anchors = cat(1, all_anchors, [anchor_coords repmat(max_group, numel(anchor_trajs), 1) [last_idx + 1:last_idx + numel(anchor_trajs)]']);
            all_trajs = cat(2, all_trajs, anchor_trajs);

            % delete the old coords and trajs
            all_anchors(other_anchors(closest, end), :) = NaN;
            all_trajs{other_anchors(closest, end)} = [];
            all_anchors(curr_anchor(end), :) = NaN;
            all_trajs{curr_anchor(end)} = [];

            if size(all_anchors, 1) ~= length(all_trajs)
                error('final coords and trajs do not match')
            end

        % add it to this list will check for overlaps
        elseif size(anchor_coords, 1) == 1 && other_anchors(closest, 5) == 0
            max_group = max_group + 1;
            last_idx = size(all_anchors, 1);
            all_anchors = cat(1, all_anchors, [anchor_coords max_group last_idx + 1]);
            all_trajs = cat(2, all_trajs, anchor_trajs);

            % delete the old coords and trajs
            all_anchors(other_anchors(closest, end), :) = NaN;
            all_trajs{other_anchors(closest, end)} = [];
            all_anchors(curr_anchor(end), :) = NaN;
            all_trajs{curr_anchor(end)} = [];

            if size(all_anchors, 1) ~= length(all_trajs)
                error('final coords and trajs do not match')
            end

        % all the involved trajectories get a new group
        elseif size(anchor_coords, 1) == 1 && other_anchors(closest, 5) > 0
            max_group = max_group + 1;
            % all involved groups get the same group ID
            all_anchors(all_anchors(:,5) == curr_anchor(5), 5) = max_group;
            all_anchors(all_anchors(:,5) == other_anchors(closest, 5), 5) = max_group;

            last_idx = size(all_anchors, 1);
            all_anchors = cat(1, all_anchors, [anchor_coords max_group last_idx + 1]);
            all_trajs = cat(2, all_trajs, anchor_trajs);

            % delete the old coords and trajs
            all_anchors(other_anchors(closest, end), :) = NaN;
            all_trajs{other_anchors(closest, end)} = [];
            all_anchors(curr_anchor(end), :) = NaN;
            all_trajs{curr_anchor(end)} = [];

            if size(all_anchors, 1) ~= length(all_trajs)
                error('final coords and trajs do not match')
            end

        % if nothing was found, don't run the overlap anchor next time
        else
            error('what else is there?')

        end

    % if there is no overlapping anchor
    else
        all_anchors(curr_anchor(end), 5) = -1;

    end
    
    % number of overlapping anchors should be decreasing not increasing
    if sum(all_anchors(:, 5) > 0) > number_overlapping
        counter = counter + 1;
        if counter > 3
            error('stuck in forever loop')
        end
    else
        counter = 0;
    end

end

% filter out the deleted trajs
% Remove the anchor coordinates that's been merged
all_anchors = all_anchors(~cellfun(@isempty, all_trajs), :);
all_anchors = all_anchors(:, 1:4);
% Remove empty trajs
all_trajs = filterTraj(all_trajs, 1);

end

