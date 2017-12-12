function [ passed_trajs ] = findPassedTrajs( finalTrajmin5, anchor_coords, anchored_trajs )
% Find if any trajectories went through the anchored region without being
% anchored

% hold all the trajs that didn't get anchored
passed_trajs = [];

% reduce trajs into points with the traj id to identify them
% points = [traj id, x, y]
points = zeros(sum(cellfun(@(x) size(x,1), finalTrajmin5)), 3);
c = 1;
for i = 1:numel(finalTrajmin5)
    curr_traj = finalTrajmin5{i};
    points(c:(c + size(curr_traj, 1) - 1), :) = [ones(size(curr_traj, 1), 1)*i, curr_traj(:,1:2)];
    c = c + size(curr_traj, 1);
end

% set max distance to check from the center of the circle, this is half of
% the max cut off distance for the maximum travel allowed in a single frame
max_dist = 250;

% loop through each anchor spot and see if there was a non-anchored traj
% that went through it
for i = 1:size(anchor_coords, 1)
    % temporary holder for case 1 and case 2 outputs
    case1 = [];
    
    % case 1: a point is found within the circle (easy)
    % point is within a circle if distance between the points and the
    % center of the circle is < radius
    curr_anchor = anchor_coords(i, :);
    dist = pdist2(points(:,2:3), curr_anchor(2:3));
    
    inside_trajs = unique(points(dist < curr_anchor(1), 1));
    inside_trajs = setdiff(inside_trajs, anchored_trajs{i});
    
    % non-anchored trajs are the ones that weren't anchored
    if ~isempty(inside_trajs)
        % put back the trajs that are anchored but were missed somehow in
        % the main detection algorithm
        for l = 1:numel(inside_trajs)
            frames_inside = sum(dist(points(:,1) == inside_trajs(l)) < curr_anchor(1));
            % if a trajectory spent more than half the life inside, then add it to
            % anchored list
            if frames_inside/size(finalTrajmin5{inside_trajs(l)}, 1) > .5
                anchored_trajs{i} = unique([anchored_trajs{i}, inside_trajs(l)]);
            % otherwise, it is not anchored
            else
                case1(end + 1) = inside_trajs(l);
            end
        end
                
    end
    
    % case 2: a trajectory went through the circle (harder) use linecirc
    % coordinates in points are in order
    % filter to points nearby (based on hypothesized max travel dist per frame)
    % at least 2 consecutive points have to be nearby
    close_points = points(dist < max_dist, :);
    close_trajs = setdiff(unique(close_points(:,1)), [anchored_trajs{i}'; inside_trajs]);

    case2 = [];
    % for each of the line segments in close_trajs
    for j = 1:numel(close_trajs)
        % 1. at least 2 consecutive points have to be close by the anchor to
        % have the potential to draw a line through the circle
        curr_points = close_points(close_points(:,1)==close_trajs(j), :);
        [~, a, ~] = intersect(finalTrajmin5{close_trajs(j)}(:,1:2),curr_points(:, 2:3), 'rows', 'stable');
        % just the first point in the consecutive point pair
        first_pair = diff(a) == 1;
        if sum(first_pair) > 0
            first_pair = find(first_pair==1);
            for k = 1:numel(first_pair)
                xy = curr_points(first_pair(k):first_pair(k)+1, 2:3);
                % use polyfit to get line
                m = (xy(1,2)-xy(2,2))/(xy(1,1)-xy(2,1));
                b = xy(1,2) - m*xy(1,1);
                % fill 100 values between the two points
                x = linspace(xy(1,1), xy(2,1));
                y = m.*x + b;
                % determine if any are in the circle
                dist = pdist2([x', y'], curr_anchor(2:3));
                if sum(dist < curr_anchor(1)) > 0
                    case2(end + 1) = close_trajs(j);
                    break
                end
            end
        end
    end
    
    total = unique([case1'; case2']);
    if ~isempty(total)
        % passed_trajs = [anchor_coord id, traj id]
        passed_trajs = cat(1, passed_trajs, [ones(numel(total), 1)*i, total]);
    end
end

end

