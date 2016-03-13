function [ flattened_combined_trajs, combined_coords, first_last_anchor_frames ] = combineAnchorswithCentroids( finalTraj, cluster_coords, cluster_trajs, immobile_coords, immobile_trajs, localization_acc )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% Center coordinates of all trajectories
center_coords=zeros(length(finalTraj),2);
for c=1:length(finalTraj)
    center_coords(c,:)=[mean(finalTraj{c}(:,1)),mean(finalTraj{c}(:,2))];
end

% Will merge fewer anchors into more anchors
if length(immobile_trajs) > length(cluster_trajs)
    combined_trajs = immobile_trajs;
    combined_coords = immobile_coords;
    merged_trajs = cluster_trajs;
    merged_coords = cluster_coords;
else
    combined_trajs = cluster_trajs;
    combined_coords = cluster_coords;
    merged_trajs = immobile_trajs;
    merged_coords = immobile_coords;
end

% Look for overlaps between every pair of anchor sizes
for combined_idx = 1:length(combined_trajs)
    for merged_idx = 1:length(merged_trajs)
        
        if combined_idx >= merged_idx
            if ~isempty(combined_coords{combined_idx}) && ~isempty(merged_coords{merged_idx})
                % KD tree and the search happens in the function
                % Both anchor lists are modified
                [large_merged_trajs, combined_trajs{combined_idx}, combined_coords{combined_idx}, merged_trajs{merged_idx}, merged_coords{merged_idx}] = mergeOverlappingAnchorTrajs(combined_trajs{combined_idx}, combined_coords{combined_idx}, merged_trajs{merged_idx}, merged_coords{merged_idx}, localization_acc, combined_idx);
                
                % Remake the coords using trajectory center coordinates
                large_merged_coords = findAnchorCoord(large_merged_trajs,center_coords);
                
                % Add the merged trajectories and coords
                combined_trajs{combined_idx} = cat(2,combined_trajs{combined_idx},large_merged_trajs);
                combined_coords{combined_idx} = cat(1,combined_coords{combined_idx},large_merged_coords);
            end
            
        elseif merged_idx > combined_idx
            if ~isempty(combined_coords{combined_idx}) && ~isempty(merged_coords{merged_idx})
                [large_merged_trajs, merged_trajs{merged_idx}, merged_coords{merged_idx}, combined_trajs{combined_idx}, combined_coords{combined_idx}] = mergeOverlappingAnchorTrajs(merged_trajs{merged_idx}, merged_coords{merged_idx}, combined_trajs{combined_idx}, combined_coords{combined_idx}, localization_acc, merged_idx);

                % Remake the coords using trajectory center coordinates
                large_merged_coords = findAnchorCoord(large_merged_trajs,center_coords);
                
                % Add merged trajectories and coords
                combined_trajs{merged_idx} = cat(2,combined_trajs{merged_idx},large_merged_trajs);
                combined_coords{merged_idx} = cat(1,combined_coords{merged_idx},large_merged_coords);
            end
        end
        
    end
end

% After every merging every combination between the two arrays, the left
% over anchors have no overlaps
% Add the smaller anchor array to the larger anchor array
for remaining_anchor_idx = 1:length(merged_trajs)
    combined_trajs{remaining_anchor_idx} = cat(2,combined_trajs{remaining_anchor_idx},merged_trajs{remaining_anchor_idx});
end

% Flatten combined_trajs into just a cell array instead of a nested array
flattened_combined_trajs={};
for outer_array_idx = 1:length(combined_trajs)
    if ~isempty(combined_trajs{outer_array_idx})
        flattened_combined_trajs = cat(2,flattened_combined_trajs,combined_trajs{outer_array_idx}{:});
    end
end

combined_coords = zeros(length(flattened_combined_trajs),3);
% Fix anchor coords and radius using kmeans clustering
for anchor_idx = 1:length(flattened_combined_trajs)
    combined_coords(anchor_idx,:) = anchorRadiusandCenter(finalTraj,flattened_combined_trajs,anchor_idx);
end

% Need to recheck for overlaps
for anchor=1:length(flattened_combined_trajs)
    if ~isempty(flattened_combined_trajs{anchor})
        anchor_tree = KDTreeSearcher([combined_coords(1:anchor-1,2:3);NaN,NaN;combined_coords(anchor+1:end,2:3)]);
        final_overlaps = rangesearch(anchor_tree,combined_coords(anchor,2:3),combined_coords(anchor,1));
        final_overlaps = final_overlaps{:};
        % replace, remake center and radius
        if ~isempty(final_overlaps)
            flattened_combined_trajs{anchor} = unique([flattened_combined_trajs{anchor},flattened_combined_trajs{final_overlaps}]);
            % Remake center and radius
            combined_coords(anchor,:) = anchorRadiusandCenter(finalTraj,flattened_combined_trajs,anchor);
            for i=1:length(final_overlaps)
                flattened_combined_trajs{final_overlaps(i)} = [];
                combined_coords(final_overlaps(i),:) = NaN;
            end
        end
    end
end

% Remove the anchor coordinates that's been merged
combined_coords = combined_coords(~cellfun(@isempty,flattened_combined_trajs),:);
% Get rid of empty arrays in smaller anchor trajectories
flattened_combined_trajs = filterTraj(flattened_combined_trajs,1);

% Find anchor duration
% Get the starting and the ending frame numbers for all of the trajectories in each anchor
anchor_frames = frameNumbers(flattened_combined_trajs,finalTraj);

% Get the first and last frames for all of the anchors
first_last_anchor_frames = firstLastFrame(anchor_frames);

end

% Get the starting and the ending frame numbers for all of the trajectories in each anchor
function anchor_frames = frameNumbers(anchored_trajectories, allTraj)
anchor_frames=cell(1,sum(cellfun(@length,anchored_trajectories)>1));
frame_idx=0;
for a=1:length(anchored_trajectories)
    % Screen for anchors with more than one trajectory
    if length(anchored_trajectories{a})>1
        frame_idx=frame_idx+1;
        firstandlast=zeros(length(anchored_trajectories{a}),2);
        for b=1:length(anchored_trajectories{a})
            firstandlast(b,:)=allTraj{anchored_trajectories{a}(b)}(1,6:7);
        end
        anchor_frames{frame_idx}=firstandlast;
    end
end
end

% Find the first and the last frame for each anchor
function first_last_frames = firstLastFrame(anchor_frames)
first_last_frames=zeros(length(anchor_frames),2);
for q=1:length(anchor_frames)
    first_last_frames(q,:)=[min(anchor_frames{q}(:)),max(anchor_frames{q}(:))];
end
end

function radius_and_coords = anchorRadiusandCenter(finalTraj,flattened_combined_trajs,anchor_idx)
% Put all x, y frame coordinates into an n by 2 matrix
    anchored_coords = finalTraj{flattened_combined_trajs{anchor_idx}(1)}(:,1:2);
    for anchors = 2:length(flattened_combined_trajs{anchor_idx})
        anchored_coords = cat(1,anchored_coords,finalTraj{flattened_combined_trajs{anchor_idx}(anchors)}(:,1:2));
    end
    % Use kmeans to find two clusters
    [kcluster_idx, kcluster_coords] = kmeans(anchored_coords,2);
    % Find the center coord for a single cluster
    average_coords = mean(anchored_coords);
    % Find the distance from all of the points to the anchor coords
    sum_dist = sum([pdist2(anchored_coords,kcluster_coords(1,:)),pdist2(anchored_coords,kcluster_coords(2,:)),pdist2(anchored_coords,average_coords)]);
    final_anchor_idx = find(sum_dist==min(sum_dist));
    % Find which of the 3 anchor coords fits the data the best
    % If all the frames are nicely clustered, the center becomes the
    % average of all the frames stuck in the anchor
    % If there are outliars, then one of the kcluster_coords fits
    % better
    if final_anchor_idx==1
        diameter = min(max(anchored_coords(kcluster_idx==1,1))-min(anchored_coords(kcluster_idx==1,1)),max(anchored_coords(kcluster_idx==1,2))-min(anchored_coords(kcluster_idx==1,2)));
        radius_and_coords = [diameter/2,kcluster_coords(1,:)];
    % If there are outliars, define the center as the mean of the
    % bigger cluster
    elseif final_anchor_idx==2
        diameter = min(max(anchored_coords(kcluster_idx==2,1))-min(anchored_coords(kcluster_idx==2,1)),max(anchored_coords(kcluster_idx==2,2))-min(anchored_coords(kcluster_idx==2,2)));
        radius_and_coords = [diameter/2,kcluster_coords(2,:)];
    elseif final_anchor_idx==3
        diameter = min(max(anchored_coords(:,1))-min(anchored_coords(:,1)),max(anchored_coords(:,2))-min(anchored_coords(:,2)));
        radius_and_coords = [diameter/2,average_coords];
    end
%             figure
%             plot(anchored_coords(:,1),anchored_coords(:,2))
%             hold on;
%             scatter(combined_coords(anchor_idx,2),combined_coords(anchor_idx,3))
%             ang=0:0.01:2*pi;
%             anchor_radius=combined_coords(anchor_idx,1);
%             xp=anchor_radius*cos(ang);
%             yp=anchor_radius*sin(ang);
%             plot(combined_coords(anchor_idx,2)+xp,combined_coords(anchor_idx,3)+yp,'LineWidth',2,'Color','k');
%             axis image
end

function [combined_trajs, larger_anchor_trajs, larger_anchor_coords, smaller_anchor_trajs, smaller_anchor_coords] = mergeOverlappingAnchorTrajs(larger_anchor_trajs, larger_anchor_coords, smaller_anchor_trajs, smaller_anchor_coords, localization_acc, larger_anchor_size)
% Combines anchored trajectories to the larger array and removes combined
% anchor coordinates and trajectories
% Will generate new anchor coordinates after this function is called
combined_trajs={};
kd_tree = KDTreeSearcher(smaller_anchor_coords);
overlappingAnchors = rangesearch(kd_tree,larger_anchor_coords,localization_acc*larger_anchor_size*1.5);
% Can't use the mergeAnchors function because need to add trajectories to
% the new combined trajs even if there aren't any overlaps from KDTree
for larger_anchor_idx = 1:length(larger_anchor_trajs)
    % If there are overlapping smaller anchors
    if ~isempty(overlappingAnchors{larger_anchor_idx})
        smallerAnchors = overlappingAnchors{larger_anchor_idx};
        % Hold combined trajectories in the combined_trajs variable
        combined_trajs{end+1} = unique([smaller_anchor_trajs{smallerAnchors},larger_anchor_trajs{larger_anchor_idx}]);
        larger_anchor_trajs{larger_anchor_idx} = [];
        % Remove smaller anchor trajectories
        for smaller_idx = 1:length(smallerAnchors)
            smaller_anchor_trajs{smallerAnchors(smaller_idx)} = [];
        end
    end
end

% Remove the anchor coordinates that's been merged
smaller_anchor_coords = smaller_anchor_coords(~cellfun(@isempty,smaller_anchor_trajs),:);
larger_anchor_coords = larger_anchor_coords(~cellfun(@isempty,larger_anchor_trajs),:);
% Get rid of empty arrays in smaller anchor trajectories
smaller_anchor_trajs = filterTraj(smaller_anchor_trajs,1);
larger_anchor_trajs = filterTraj(larger_anchor_trajs,1);
        
end