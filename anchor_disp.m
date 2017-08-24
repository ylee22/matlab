function [ anchor_dist ] = anchor_disp( anchor_trajs, anchor_coords, finalTrajmin5 )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% find anchor with multiple trajs
mult_idx = cellfun(@(x) numel(x)>1, anchor_trajs);

mult_anchors = anchor_coords(mult_idx,:);
mult_trajs = anchor_trajs(mult_idx);


% for each multi traj anchor
% arrange by frame number
% find distance over time
anchor_dist = cell(1, numel(mult_trajs));
for i = 1:numel(mult_trajs)
    % one anchor (1.26.2017, ss_rkd_20_dox_w2_3b, at mult_trajs{132}) has
    % duplicate anchored traj somehow
    mult_trajs{i} = unique(mult_trajs{i});
    
    centers = zeros(numel(mult_trajs{i}), 2);
    for j = 1:numel(mult_trajs{i})
        traj_coords = finalTrajmin5{mult_trajs{i}(j)}(:, 1:2);
        [idx, ~] = dbscan(traj_coords, 50, 5);
        cluster = 1;
        
        if max(idx)==2
            % find the idx where it's inside the anchor
            inside1 = pdist2(traj_coords(idx==1, :), mult_anchors(i, 2:3)) <= mult_anchors(i, 1);
            inside2 = pdist2(traj_coords(idx==2, :), mult_anchors(i, 2:3)) <= mult_anchors(i, 1);
            if sum(inside1) > sum(inside2)
                cluster = 1;
            else
                cluster = 2;
            end
        elseif max(idx) == 0
%             inside = pdist2(traj_coords, mult_anchors(i, 2:3)) <= mult_anchors(i, 1);
            cluster = 0;
        end
        
        centers(j, :) = mean(traj_coords(idx == cluster,:));
    end
    
    dist = pdist(centers);
    
    if sum(isnan(centers)) > 0
        error('NaN values')
    end
    
    if numel(dist) == 1
        anchor_dist{i} = [mult_trajs{i}' centers [0; dist]];
    else
        anchor_dist{i} = [mult_trajs{i}' centers [0; dist(1:numel(mult_trajs{i})-1)']];
    end
end

end

