function [ flattened_trajs_spots, larger_anchor_coords, first_last_anchor_frames, trajs ] = combineAnchors( finalTraj, cluster_anchor_coords, cluster_trajs, immobile_coords, immobile_anchor_coords, immobile_spots, localization_acc )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% Problem: a single trajectory can be stuck in multiple anchors
% Fix this problem by using trajectories and center coord for cluster
% anchors, and spots and immobile coord for immobile clusters
% {{[-1: trajectories],[-2: spots]}}
% The larger anchor trajs will have to be redone with -1 in front

% Will merge fewer anchors into more anchors
if length(immobile_spots) > length(cluster_trajs)
    
    % Need to mark traj vs spots
    % -1 refers to larger set, -2 refers to smaller set
    larger_trajs = cell(1,length(immobile_spots));
    for size_idx = 1:length(immobile_spots)
        for spot_row = 1:length(immobile_spots{size_idx})
            larger_trajs{size_idx}{spot_row} = [-1 immobile_spots{size_idx}{spot_row}];
        end
    end

    larger_anchor_coords = immobile_anchor_coords;
    larger_coords = immobile_coords(:,4:5);
    
    smaller_trajs = cell(1,length(cluster_trajs));
    for radius_idx = 1:length(cluster_trajs)
        for traj_row = 1:length(cluster_trajs{radius_idx})
            smaller_trajs{radius_idx}{traj_row} = [-2 cluster_trajs{radius_idx}{traj_row}];
        end
    end
    
    smaller_anchor_coords = cluster_anchor_coords;
    smaller_coords = finalTraj;
else
    
    larger_trajs = cell(1,length(cluster_trajs));
    for size_idx = 1:length(cluster_trajs)
        for traj_row = 1:length(cluster_trajs{size_idx})
            larger_trajs{size_idx}{traj_row}=[-1 cluster_trajs{size_idx}{traj_row}];
        end
    end
    
    larger_anchor_coords = cluster_anchor_coords;
    larger_coords = finalTraj;
    
    smaller_trajs = cell(1,length(immobile_spots));
    for radius_idx = 1:length(immobile_spots)
        for spot_row = 1:length(immobile_spots{radius_idx})
            smaller_trajs{radius_idx}{spot_row} = [-2 immobile_spots{radius_idx}{spot_row}];
        end
    end
    
    smaller_anchor_coords = immobile_anchor_coords;
    smaller_coords = immobile_coords(:,4:5);
end

% Look for overlaps between every pair of anchor sizes
for combined_idx = 1:length(larger_trajs)
    for merged_idx = 1:length(smaller_trajs)
        
        if combined_idx >= merged_idx
            if ~isempty(larger_anchor_coords{combined_idx}) && ~isempty(smaller_anchor_coords{merged_idx})
                % KD tree and the search happens in the function
                % Both anchor lists are modified
                [merged_trajs, larger_trajs{combined_idx}, larger_anchor_coords{combined_idx}, smaller_trajs{merged_idx}, smaller_anchor_coords{merged_idx}] = mergeOverlappingAnchorTrajs(larger_trajs{combined_idx}, larger_anchor_coords{combined_idx}, smaller_trajs{merged_idx}, smaller_anchor_coords{merged_idx}, localization_acc, combined_idx);
                
                % Remake the coords using trajectory center coordinates
                large_merged_coords = findAnchorCenter(merged_trajs,larger_coords,smaller_coords);
                
                % Add the merged trajectories and coords
                larger_trajs{combined_idx} = cat(2,larger_trajs{combined_idx},merged_trajs);
                larger_anchor_coords{combined_idx} = cat(1,larger_anchor_coords{combined_idx},large_merged_coords);
            end
            
        elseif merged_idx > combined_idx
            if ~isempty(larger_anchor_coords{combined_idx}) && ~isempty(smaller_anchor_coords{merged_idx})
                [merged_trajs, smaller_trajs{merged_idx}, smaller_anchor_coords{merged_idx}, larger_trajs{combined_idx}, larger_anchor_coords{combined_idx}] = mergeOverlappingAnchorTrajs(smaller_trajs{merged_idx}, smaller_anchor_coords{merged_idx}, larger_trajs{combined_idx}, larger_anchor_coords{combined_idx}, localization_acc, merged_idx);

                % Remake the coords using trajectory center coordinates
                large_merged_coords = findAnchorCenter(merged_trajs,larger_coords,smaller_coords);
                
                % Add merged trajectories and coords
                larger_trajs{merged_idx} = cat(2,larger_trajs{merged_idx},merged_trajs);
                larger_anchor_coords{merged_idx} = cat(1,larger_anchor_coords{merged_idx},large_merged_coords);
            end
        end
        
    end
end

% After every merging every combination between the two arrays, the left
% over anchors have no overlaps
% Add the smaller anchor array to the larger anchor array
for remaining_anchor_idx = 1:length(smaller_trajs)
    if ~isempty(smaller_trajs{remaining_anchor_idx})
        for row = 1:length(smaller_trajs{remaining_anchor_idx})
            if isempty(larger_trajs{remaining_anchor_idx}) && ~iscell(larger_trajs{remaining_anchor_idx})
                larger_trajs{remaining_anchor_idx}={};
            elseif ~isempty(larger_trajs{remaining_anchor_idx}) && ~iscell(larger_trajs{remaining_anchor_idx})
                error('Trajectory array has a non-empty vector instead of a cell aray')
            end
            larger_trajs{remaining_anchor_idx} = cat(2,larger_trajs{remaining_anchor_idx}, smaller_trajs{remaining_anchor_idx}{row});
        end
    end
end

% Flatten combined_trajs into just a cell array instead of a nested array
% If an anchor has both trajs and spots, it will be a cell array, otherwise
% it will just be a vector
flattened_trajs_spots = cell(1,sum(cellfun(@length,larger_trajs)));
flattened_counter = 0;
for outer_idx = 1:length(larger_trajs)
    if ~isempty(larger_trajs{outer_idx})
        for inner_idx = 1:length(larger_trajs{outer_idx})
            flattened_counter = flattened_counter + 1;
            flattened_trajs_spots{flattened_counter} = larger_trajs{outer_idx}{inner_idx};
        end
    end
end

larger_anchor_coords = zeros(length(flattened_trajs_spots),3);
% Fix anchor coords and radius using kmeans clustering
for anchor_idx = 1:length(flattened_trajs_spots)
    % If the anchor is defined by only immobile spots, then make the anchor
    % include ALL of the immobile spots (max of x or y diff)
    if iscell(larger_coords) && ~iscell(flattened_trajs_spots{anchor_idx}) && flattened_trajs_spots{anchor_idx}(1) == -2
        % Immobile anchor radius and coordinates
        larger_anchor_coords(anchor_idx,:) = immobileAnchorRadiusandCoord(smaller_coords, flattened_trajs_spots{anchor_idx}(2:end));
    elseif iscell(smaller_coords) && ~iscell(flattened_trajs_spots{anchor_idx}) && flattened_trajs_spots{anchor_idx}(1) == -1
        % Immobile anchor radius and coordinates
        larger_anchor_coords(anchor_idx,:) = immobileAnchorRadiusandCoord(larger_coords, flattened_trajs_spots{anchor_idx}(2:end));
    else
        % Combined and trajectory anchor radius and coordinates
        larger_anchor_coords(anchor_idx,:) = combinedTrajAnchorRadiusandCenter(larger_coords, smaller_coords, flattened_trajs_spots{anchor_idx});
    end
end

% Need to recheck for overlaps
for anchor=1:length(flattened_trajs_spots)
    if ~isempty(flattened_trajs_spots{anchor})
        anchor_tree = KDTreeSearcher([larger_anchor_coords(1:anchor-1,2:3);NaN,NaN;larger_anchor_coords(anchor+1:end,2:3)]);
        final_overlaps = rangesearch(anchor_tree,larger_anchor_coords(anchor,2:3),larger_anchor_coords(anchor,1));
        final_overlaps = final_overlaps{:};
        % Replace, remake center and radius
        if ~isempty(final_overlaps)
            % Merge trajectories and spots
            for i=1:length(final_overlaps)
                flattened_trajs_spots{anchor} = combineTrajsandSpots(flattened_trajs_spots{anchor},flattened_trajs_spots{final_overlaps(i)});
                flattened_trajs_spots{final_overlaps(i)} = [];
                larger_anchor_coords(final_overlaps(i),:) = NaN;                
            end
            % Remake anchor radius and center
            if iscell(larger_coords) && ~iscell(flattened_trajs_spots{anchor}) && flattened_trajs_spots{anchor}(1) == -2
                % Remake immobile anchor radius and coordinates
                larger_anchor_coords(anchor,:) = immobileAnchorRadiusandCoord(smaller_coords, flattened_trajs_spots{anchor}(2:end));
            elseif iscell(smaller_coords) && ~iscell(flattened_trajs_spots{anchor}) && flattened_trajs_spots{anchor}(1) == -1
                % Remake immobile anchor radius and coordinates
                larger_anchor_coords(anchor,:) = immobileAnchorRadiusandCoord(larger_coords, flattened_trajs_spots{anchor}(2:end));
            else
                % Remake combined and trajectory anchor center and radius
                larger_anchor_coords(anchor,:) = combinedTrajAnchorRadiusandCenter(larger_coords, smaller_coords, flattened_trajs_spots{anchor});
            end
        end
    end
end

% Remove the anchor coordinates that's been merged
larger_anchor_coords = larger_anchor_coords(~cellfun(@isempty,flattened_trajs_spots),:);
% Get rid of empty arrays in smaller anchor trajectories
flattened_trajs_spots = filterTraj(flattened_trajs_spots,1);

% Find anchor duration
% Get the starting and the ending frame numbers for all of the trajectories in each anchor
% Need to convert spots into trajectory row IDs before I can find the
% frame numbers

% Convert spots into trajs and add to the trajs array
% Gets rid of markers (-1 and -2) for cluster and immobile
% trajs should only include trajectories, not immobile spots
trajs = cell(1,length(flattened_trajs_spots));
% If the smaller set refers to the immobile spots
if iscell(larger_coords)
    for current_anchor = 1:length(flattened_trajs_spots)
        if iscell(flattened_trajs_spots{current_anchor})
            trajs{current_anchor} = cat(2,trajs{current_anchor},flattened_trajs_spots{current_anchor}{1}(2:end));
            trajs{current_anchor} = cat(2,trajs{current_anchor},unique(immobile_coords(flattened_trajs_spots{current_anchor}{2}(2:end),1))');
        elseif flattened_trajs_spots{current_anchor}(1) == -1
            trajs{current_anchor} = cat(2,trajs{current_anchor},flattened_trajs_spots{current_anchor}(2:end));
        elseif flattened_trajs_spots{current_anchor}(1) == -2
            trajs{current_anchor} = cat(2,trajs{current_anchor},unique(immobile_coords(flattened_trajs_spots{current_anchor}(2:end),1))');
        end 
    end
% If the larger set refers to the immobile spots
else
    for current_anchor = 1:length(flattened_trajs_spots)
        if iscell(flattened_trajs_spots{current_anchor})
            trajs{current_anchor} = cat(2,trajs{current_anchor},unique(immobile_coords(flattened_trajs_spots{current_anchor}{1}(2:end),1))');
            trajs{current_anchor} = cat(2,trajs{current_anchor},flattened_trajs_spots{current_anchor}{2}(2:end));            
        elseif flattened_trajs_spots{current_anchor}(1) == -1
            trajs{current_anchor} = cat(2,trajs{current_anchor},unique(immobile_coords(flattened_trajs_spots{current_anchor}(2:end),1))');
        elseif flattened_trajs_spots{current_anchor}(1) == -2
            trajs{current_anchor} = cat(2,trajs{current_anchor},flattened_trajs_spots{current_anchor}(2:end));
        end 
    end
end

anchor_frames = frameNumbers(trajs, finalTraj);

% Get the first and last frames for all of the anchors
first_last_anchor_frames = firstLastFrame(anchor_frames);

end

function radiusandcoords = immobileAnchorRadiusandCoord(immobile_spot_coords, spot_IDs)
% Find the anchor coord
anchor_coord = mean(immobile_spot_coords(spot_IDs, :));
% Farthest out spot defines the radius of the anchor
radius = max(pdist2(anchor_coord, immobile_spot_coords(spot_IDs, :)));
radiusandcoords = [radius, anchor_coord];
end

function combined_trajs_and_spots = combineTrajsandSpots(trajs_and_spots1,trajs_and_spots2)
if iscell(trajs_and_spots1)
    if iscell(trajs_and_spots2)
        combined_trajs_and_spots = {cat(2,trajs_and_spots1{1},trajs_and_spots2{1}(2:end)), cat(2,trajs_and_spots1{2},trajs_and_spots2{2}(2:end))};
    elseif trajs_and_spots2(1) == -1
        combined_trajs_and_spots = {cat(2,trajs_and_spots1{1},trajs_and_spots2(2:end)), trajs_and_spots1{2}};
    elseif trajs_and_spots2(1) == -2
        combined_trajs_and_spots = {trajs_and_spots1{1}, cat(2,trajs_and_spots1{2},trajs_and_spots2(2:end))};
    else
        error('Marker does not exist')
    end
    
elseif trajs_and_spots1(1) == -1
    if iscell(trajs_and_spots2)
        combined_trajs_and_spots = {cat(2,trajs_and_spots2{1},trajs_and_spots1(2:end)), trajs_and_spots2{2}};
    elseif trajs_and_spots2(1) == -1
        combined_trajs_and_spots = cat(2,trajs_and_spots1,trajs_and_spots2(2:end));
    elseif trajs_and_spots2(1) == -2
        combined_trajs_and_spots = {trajs_and_spots1,trajs_and_spots2};
    else
        error('Marker does not exist')
    end
    
elseif trajs_and_spots1(1) == -2
    if iscell(trajs_and_spots2)
        combined_trajs_and_spots = {trajs_and_spots2{1}, cat(2,trajs_and_spots2{2},trajs_and_spots1(2:end))};
    elseif trajs_and_spots2(1) == -1
        combined_trajs_and_spots = {trajs_and_spots2,trajs_and_spots1};
    elseif trajs_and_spots2(1) == -2
        combined_trajs_and_spots = cat(2,trajs_and_spots1,trajs_and_spots2(2:end));
    else
        error('Marker does not exist')
    end
    
else
    error('Marker does not exist')
end

end

% Get the starting and the ending frame numbers for all of the trajectories in each anchor
function anchor_frames = frameNumbers(anchored_trajectories, allTraj)
anchor_frames = cell(1,sum(cellfun(@length,anchored_trajectories)>1));
% anchor_frames = {};
frame_idx = 0;
for a = 1:length(anchored_trajectories)
    % Screen for anchors with more than one trajectory
    if length(anchored_trajectories{a}) > 1
%     if length(anchored_trajectories{a})>=5 && length(anchored_trajectories{a})<=10
        frame_idx = frame_idx + 1;
        % 3 columns: anchor row ID, first, last
        firstandlast = zeros(length(anchored_trajectories{a}),3);
        for b = 1:length(anchored_trajectories{a})
            firstandlast(b,:) = [a, allTraj{anchored_trajectories{a}(b)}(1,6:7)];
        end
        anchor_frames{frame_idx} = firstandlast;
    end
end
end

% Find the first and the last frame for each anchor
function first_last_frames = firstLastFrame(anchor_frames)
first_last_frames = zeros(length(anchor_frames), 3);
for q = 1:length(anchor_frames)
    first_last_frames(q,:)=[anchor_frames{q}(1,1), min(anchor_frames{q}(:,2)), max(anchor_frames{q}(:,3))];
end
end

function radius_and_coords = combinedTrajAnchorRadiusandCenter(large_coords,small_coords,current_trajs_spots)
% Have to check to see if it's an array or a vector first, then check the
% first element (-1 or -2).
% Hold all of the x, y anchored frame coordinates into a n by 2 matrix

anchored_coords = [];
% Problem: one of the coordinate systems is a cell, while the other is a
% matrix. Traj IDs refer to the rows of finalTraj.

% Separate scenarios by both trajs and spots being anchored vs only one
% type being anchored
if iscell(current_trajs_spots)
    if iscell(large_coords)
        traj_coords = anchoredFrameCoords(large_coords, current_trajs_spots{1}(2:end));
        anchored_coords = cat(1,anchored_coords,traj_coords);
        anchored_coords = cat(1,anchored_coords,small_coords(current_trajs_spots{2}(2:end),:));
    else
        anchored_coords = cat(1,anchored_coords,large_coords(current_trajs_spots{1}(2:end),:));
        traj_coords = anchoredFrameCoords(small_coords, current_trajs_spots{2}(2:end));
        anchored_coords = cat(1,anchored_coords,traj_coords);
    end
elseif current_trajs_spots(1) == -1
    if iscell(large_coords)
        traj_coords = anchoredFrameCoords(large_coords, current_trajs_spots(2:end));
        anchored_coords = cat(1,anchored_coords,traj_coords);
    else
        error('Immobile anchors are not getting filtered')
%         anchored_coords = cat(1,anchored_coords,large_coords(current_trajs_spots(2:end),:));
    end
elseif current_trajs_spots(1) == -2
    if iscell(small_coords)
        traj_coords = anchoredFrameCoords(small_coords, current_trajs_spots(2:end));
        anchored_coords = cat(1,anchored_coords,traj_coords);
    else
        error('Immobile anchors are not getting filtered')
%         anchored_coords = cat(1,anchored_coords,small_coords(current_trajs_spots(2:end),:));
    end
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
    radius_and_coords = [diameter/2, kcluster_coords(1,:)];
% If there are outliars, define the center as the mean of the
% bigger cluster
elseif final_anchor_idx==2
    diameter = min(max(anchored_coords(kcluster_idx==2,1))-min(anchored_coords(kcluster_idx==2,1)),max(anchored_coords(kcluster_idx==2,2))-min(anchored_coords(kcluster_idx==2,2)));
    radius_and_coords = [diameter/2, kcluster_coords(2,:)];
elseif final_anchor_idx==3
    diameter = min(max(anchored_coords(:,1))-min(anchored_coords(:,1)),max(anchored_coords(:,2))-min(anchored_coords(:,2)));
    radius_and_coords = [diameter/2, average_coords];
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

function traj_coords = anchoredFrameCoords(finalTrajCoords, finalTrajIdx)
traj_coords = finalTrajCoords{finalTrajIdx(1)}(:,1:2);
for trajs = 2:length(finalTrajIdx)
    traj_coords = cat(1,traj_coords,finalTrajCoords{finalTrajIdx(trajs)}(:,1:2));
end
end

function [combined_trajs, larger_anchor_trajs, larger_anchor_coords, smaller_anchor_trajs, smaller_anchor_coords] = mergeOverlappingAnchorTrajs(larger_anchor_trajs, larger_anchor_coords, smaller_anchor_trajs, smaller_anchor_coords, localization_acc, larger_anchor_size)
% Combines anchored trajectories to the larger array and removes combined
% anchor coordinates and trajectories
% Will generate new anchor coordinates after this function is called
combined_trajs={};
kd_tree = KDTreeSearcher(smaller_anchor_coords);
overlappingAnchors = rangesearch(kd_tree,larger_anchor_coords,localization_acc*larger_anchor_size*1.5);

for larger_anchor_idx = 1:length(larger_anchor_trajs)
    % If there are overlapping smaller anchors
    if ~isempty(overlappingAnchors{larger_anchor_idx})
        smallerAnchors = overlappingAnchors{larger_anchor_idx};
        
        % Hold combined trajectories in the combined_trajs variable
        % LARGER AND SMALLER HERE DOESN'T MEAN THE ONE THAT'S
        % GETTING MERGED AND THE ARRAY THAT'S GOING TO REMAIN
        
        for small_idx = 1:length(smallerAnchors)
            if ~isempty(smaller_anchor_trajs{smallerAnchors(small_idx)})
                combined_trajs_and_spots = combineTrajsandSpots(larger_anchor_trajs{larger_anchor_idx},smaller_anchor_trajs{smallerAnchors(small_idx)});
                combined_trajs{end+1} = combined_trajs_and_spots;
                % Remove smaller anchor trajs/spots
                smaller_anchor_trajs{smallerAnchors(small_idx)} = [];
            end
        end
        
        % Remove larger anchor trajs/spots
        larger_anchor_trajs{larger_anchor_idx} = [];
    end
end

% Remove the anchor coordinates that's been merged
smaller_anchor_coords = smaller_anchor_coords(~cellfun(@isempty,smaller_anchor_trajs),:);
larger_anchor_coords = larger_anchor_coords(~cellfun(@isempty,larger_anchor_trajs),:);
% Get rid of empty arrays in smaller anchor trajectories
smaller_anchor_trajs = filterTraj(smaller_anchor_trajs,1);
larger_anchor_trajs = filterTraj(larger_anchor_trajs,1);
        
end

function pre_anchor_coords = findAnchorCenter(trajsandspots,larger_coords,smaller_coords)
    % Find new anchor coordinates and add them to the anchor_coords
    pre_anchor_coords=zeros(length(trajsandspots),2);
    % center_coords are the centroids for all trajectories
    for n=1:length(trajsandspots)
        
        if trajsandspots{n}{1}(1) ~= -1 || trajsandspots{n}{2}(1) ~= -2
            error('Marker error')
        end
        
        larger = trajsandspots{n}{1}(2:end);
        smaller = trajsandspots{n}{2}(2:end);
        
        if iscell(larger_coords)
            traj_coords = anchoredFrameCoords(larger_coords, larger);
            x_coords = [traj_coords(:,1);smaller_coords(smaller,1)];
            y_coords = [traj_coords(:,2);smaller_coords(smaller,2)];
        else
            traj_coords = anchoredFrameCoords(smaller_coords, smaller);
            x_coords = [larger_coords(larger,1);traj_coords(:,1)];
            y_coords = [larger_coords(larger,2);traj_coords(:,2)];
        end
        
        pre_anchor_coords(n,:)=[mean(x_coords),mean(y_coords)];
    end
end