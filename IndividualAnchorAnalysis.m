[combFinalTraj,~,~] = combineTraj_faster(finalTraj,2,200);
finalTrajmin5 = minimumTrajLength(combFinalTraj,5);

localization_acc = 25;

max_coords=zeros(length(finalTrajmin5),2);
min_coords=zeros(length(finalTrajmin5),2);
for i=1:length(finalTrajmin5)
    max_coords(i,:)=max(finalTrajmin5{i}(:,1:2));
    min_coords(i,:)=min(finalTrajmin5{i}(:,1:2));
end

cell_size=max(max_coords)-min(min_coords);
cell_area = cell_size(1)*cell_size(2);

% Find immobile anchors
[immobile_anchor_coords, immobile_anchored_spots, immobile_coords] = findImmobileAnchors(finalTrajmin5, localization_acc, cell_area);

% Check to make sure that the number of anchor coords match the number of
% anchored spots (should have 1 to 1 mapping between coords and spots)
if sum(cellfun(@length,immobile_anchor_coords) == 2)
    count = 0;
    for row = 1:length(immobile_anchor_coords)
        count = count + size(immobile_anchor_coords{row},1);
    end
    if count ~= sum(cellfun(@length,immobile_anchored_spots))
        error('immobile anchor and spots do not match')
    end
elseif sum(cellfun(@length,immobile_anchor_coords)) ~= sum(cellfun(@length,immobile_anchored_spots))
    error ('immobile anchor and spots do not match')
end

% Find cluster anchors
[cluster_anchor_coords, cluster_anchored_traj] = findClusterAnchors(finalTrajmin5, localization_acc, cell_area);

% Check to make sure that the number of anchor coords match the number of
% anchored trajs (should have 1 to 1 mapping between coords and spots)
if sum(cellfun(@length,cluster_anchor_coords) == 2)
    count = 0;
    for row = 1:length(cluster_anchor_coords)
        count = count + size(cluster_anchor_coords{row},1);
    end
    if count ~= sum(cellfun(@length,cluster_anchored_traj))
        error('cluster anchor and trajs do not match')
    end
elseif sum(cellfun(@length,cluster_anchor_coords)) ~= sum(cellfun(@length,cluster_anchored_traj))
    error('cluster anchor and trajs do not match')
end

% Combine both types of anchors together
[combined_anchor_coords, converted_to_trajs]=combineAnchors(finalTrajmin5,cluster_anchor_coords,cluster_anchored_traj,immobile_coords,immobile_anchor_coords,immobile_anchored_spots,localization_acc*1.5, cell_area);

filtered_converted_to_trajs=converted_to_trajs(combined_anchor_coords(:,4)>0);
filtered_combined_anchor_coords=combined_anchor_coords(combined_anchor_coords(:,4)>0,:);

if length(filtered_converted_to_trajs) ~= length(filtered_combined_anchor_coords)
    error('rows are mismatched')
end

all_traj_length = zeros(1,length(finalTrajmin5));
for trajID = 1:length(finalTrajmin5)
    all_traj_length(trajID) = size(finalTrajmin5{trajID},1);
end

% Filter artifacts
lt100_anchor_coords = filtered_combined_anchor_coords(filtered_combined_anchor_coords(:,1)<=100,:);
lt100_trajs = filtered_converted_to_trajs(filtered_combined_anchor_coords(:,1)<=100);

% anchored and free trajectories Subtract the first element (row number in
% the original traj, sometimes DBSCAN separates into multiple anchors)
anchored_traj_rows = zeros(1,sum(cellfun(@numel,lt100_trajs))-numel(lt100_trajs));
COUNTER = 1;
for anchorID = 1:numel(lt100_trajs)
    % Unpack trajectory array        
    current_trajs = lt100_trajs{anchorID}(2:end);
    anchored_traj_rows(COUNTER:COUNTER+numel(current_trajs)-1) = current_trajs;
    COUNTER = COUNTER + numel(current_trajs);
end

if ismember(0,anchored_traj_rows)
    error('anchored_traj_rows COUNTER is off')
end

% Separate rows into anchored and non-anchored and store their lengths
% Some trajectories are stuck in multiple anchors
% May have to fix this in the future
anchored_traj_rows = unique(anchored_traj_rows);

% Find the rows that are not anchored
free_traj_rows = setdiff(1:numel(finalTrajmin5), anchored_traj_rows);
