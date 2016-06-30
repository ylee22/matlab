function [ anchor_coords, anchor_trajs ] = MergeTwoDifferentAnchorTypes( anchor_coords_1, anchor_coords_2, anchor_trajs_1, anchor_trajs_2, LOC_ACC, POINT_DENSITY, finalTrajmin5 )
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here

% Make one of them into a kd tree to compare to
tree_1 = KDTreeSearcher(anchor_coords_1(:,2:3));

% Search for same anchors (probably_same_anchors has same number of rows as
% anchor coords 2 and the values indicate index in anchor coords 1)
overlapping_anchors = rangesearch(tree_1, anchor_coords_2(:,2:3), LOC_ACC);

% Can't remove rows because the rows contain the index information for
% anchor coords 2

temp_new_coords = zeros(length(overlapping_anchors), 4);
temp_trajs = cell(1,length(temp_new_coords));

counter = 0;
% Combine anchors
% overlapping_pre_anchors are indices of new_anchor_trajs, the traj ID
% is stored in new_anchor_trajs. This is looping through anchor coords 2.
for idx = 1:length(overlapping_anchors)
    if ~isempty(overlapping_anchors{idx}) && ~isempty([anchor_trajs_1{overlapping_anchors{idx}}]) && ~isempty(anchor_trajs_2{idx})
    % Remake center
    counter = counter + 1;
    % Estimated radius here for now
    temp_new_coords(counter, 1) = max([anchor_coords_1(overlapping_anchors{idx}, 1); anchor_coords_2(idx, 1)]);
    temp_new_coords(counter, 2:3) = mean([anchor_coords_1(overlapping_anchors{idx}, 2:3); anchor_coords_2(idx, 2:3)]);
    temp_trajs{counter} = unique([anchor_trajs_1{overlapping_anchors{idx}} anchor_trajs_2{idx}]);
    % Delete the merged trajs
    anchor_trajs_2{idx} = [];
        for removed = 1:length(overlapping_anchors{idx})
            anchor_trajs_1{overlapping_anchors{idx}(removed)} = [];
        end
    end
end
temp_new_coords = temp_new_coords(1:counter, :);
temp_trajs = temp_trajs(1:counter);

% Filter at the end to remove deleted anchors
anchor_coords_1 = anchor_coords_1(~cellfun(@isempty, anchor_trajs_1), :);
anchor_coords_2 = anchor_coords_2(~cellfun(@isempty, anchor_trajs_2), :);
anchor_trajs_1 = filterTraj(anchor_trajs_1, 1);
anchor_trajs_2 = filterTraj(anchor_trajs_2, 1);

% Add new anchors and trajs to the end
new_anchor_coords = [temp_new_coords; anchor_coords_1; anchor_coords_2];
new_anchor_trajs = cat(2,temp_trajs, anchor_trajs_1, anchor_trajs_2);

search_radius = 50;
% min_points = 5;

% Merge slower
[ anchor_coords, anchor_trajs ] = SlowMergeOverlappingAnchors( new_anchor_coords, new_anchor_trajs, finalTrajmin5, search_radius, LOC_ACC, POINT_DENSITY );

end