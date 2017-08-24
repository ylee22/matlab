function [ filtered_idx ] = AnchorsWithFreeComponent( cluster_idx, min_outside, anchored_coords )
% After finding anchors with DBSCAN (gets called in dbscanAnchor)
% Check for trajectories that have both free and immobile states
% anchored coordinates may be from multiple trajectories

% %%% FOR ANCHORS DEFINED BY TRAJECTORIES WITH 1 TAIL:
% filtered_idx = 0;
% % Check if there is only one anchor
% if max(cluster_idx) == 1 && sum(cluster_idx == 0) >= min_outside
%     % Minimum x consecutive frames outside of the anchor either before or
%     % after the anchor
%     anchored_idx = find(cluster_idx ~= 0);
%     
%     % Find center of anchor
%     center = mean(anchored_coords(cluster_idx==1,:));
%     
%     % Check the number of frames before entering anchor & make sure that
%     % it's not in the anchor
%     if min(anchored_idx) > min_outside && ~ismember(0, pdist2(center, anchored_coords(1:min_outside, :)) > 100)
%         filtered_idx = cluster_idx;
%     % Check the number of frames after leaving anchor & make sure that it's
%     % not in the anchor
%     elseif numel(cluster_idx) - max(anchored_idx) >= min_outside && ~ismember(0, pdist2(center, anchored_coords(end - min_outside + 1:end, :)) > 100)
%         filtered_idx = cluster_idx;
%     end
% 
% 
% % If there are multiple anchors
% % elseif max(cluster_idx) > 1 && sum(cluster_idx ~= 1) >= min_outside && ismember(0, cluster_idx)
% %     anchored_idx = find(cluster_idx == 1);
% %     
% %     % Find center of anchor
% %     center = mean(anchored_coords(cluster_idx == 1, :));
% %     
% %     if min(anchored_idx) > min_outside && ~ismember(0, pdist2(center, anchored_coords(1:min_outside, :)) > 100)
% %         filtered_idx = cluster_idx;
% %     elseif numel(cluster_idx) - max(anchored_idx) >= min_outside && ~ismember(0, pdist2(center, anchored_coords(end - min_outside + 1:end, :)) > 100)
% %         filtered_idx = cluster_idx;
% %     end
%     
% 
% end

    
%%% FOR ANCHORS DEFINED BY TRAJECTORIES WITH TWO TAILS
filtered_idx = 0;
% Check if there is only one anchor
if max(cluster_idx) == 1 && sum(cluster_idx == 0) >= min_outside
    % Minimum x consecutive frames outside of the anchor either before or
    % after the anchor
    anchored_idx = find(cluster_idx ~= 0);
    
    % Find center of anchor
    center = mean(anchored_coords(cluster_idx==1,:));
    
    % FOR ANCHORS LOCATED IN MIDDLE OF THE TRAJECTORY
    % Filter by both ends
    if (min(anchored_idx) > min_outside && ~ismember(0, pdist2(center, anchored_coords(1:min_outside, :)) > 100)) && (numel(cluster_idx) - max(anchored_idx) >= min_outside && ~ismember(0, pdist2(center, anchored_coords(end - min_outside + 1:end, :)) > 100))
        filtered_idx = cluster_idx;
    end

% If there is more than one anchor, that's fine
elseif max(cluster_idx) > 1 && sum(cluster_idx ~= 1) >= min_outside
    anchored_idx = find(cluster_idx == 1);
    
    % Find center of anchor
    center = mean(anchored_coords(cluster_idx==1,:));
    
    if (min(anchored_idx) > min_outside && ~ismember(0, pdist2(center, anchored_coords(1:min_outside, :)) > 100)) && (numel(cluster_idx) - max(anchored_idx) >= min_outside && ~ismember(0, pdist2(center, anchored_coords(end - min_outside + 1:end, :)) > 100))
        filtered_idx = cluster_idx;
    end
end

end

