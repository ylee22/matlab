function [ anchor_coords, anchoredTraj ] = findDiffSizedAnchors( finalTraj, localization_acc, cell_area )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    % Center coordinates of all trajectories
    center_coords=zeros(length(finalTraj),2);
    for c=1:length(finalTraj)
        center_coords(c,:)=[mean(finalTraj{c}(:,1)),mean(finalTraj{c}(:,2))];
    end

    % KD Tree of all the trajectory centers
    kd_center=KDTreeSearcher(center_coords);

    % Indices of trajectories in finalTraj within the localization accuracy (20 nms)
    neighboringTraj=rangesearch(kd_center,center_coords,localization_acc);

    % Remove duplicate rows of overlapping trajectories
    % Sometimes two rows are identical, so remove the latter row
    neighboringTraj = removeDuplicateRows(neighboringTraj);

    % Find anchors here
    anchoredTraj = findAnchors(neighboringTraj, localization_acc, center_coords);
    
    % Filter based on the minimum number of trajectories per anchor
    % Calculate the probability and the threshold for min traj/anchor
    anchor_coords={};
    first_last_frames_anchor={};
    for anchor_radius_idx=1:length(anchoredTraj)
        if ~isempty(anchoredTraj{anchor_radius_idx})
            traj_density=(length(finalTraj)/cell_area)*pi*(20*anchor_radius_idx)^2;
            minAnchoredTraj=2;
            probability=1;
            while probability>0.05
                minAnchoredTraj=minAnchoredTraj+1;
                probability=1-poisscdf(minAnchoredTraj,traj_density);
            end
            anchoredTraj{anchor_radius_idx} = filterTraj(anchoredTraj{anchor_radius_idx}, minAnchoredTraj);
            if ~isempty(anchoredTraj{anchor_radius_idx})
                % Remake anchor coordinates
                anchor_coords{anchor_radius_idx}=findAnchorCoord(anchoredTraj{anchor_radius_idx},center_coords);

                % Get the starting and the ending frame numbers for all of the trajectories in each anchor
                anchor_frames = frameNumbers(anchoredTraj{anchor_radius_idx},finalTraj);

                % Get the first and last frames for all of the anchors
                first_last_frames_anchor{anchor_radius_idx} = firstLastFrame(anchor_frames);
            end
        end
    end
    
end

    % Get the starting and the ending frame numbers for all of the trajectories in each anchor
    function anchor_frames = frameNumbers(anchored_trajectories, allTraj)
    anchor_frames={};
    for a=1:length(anchored_trajectories)
        firstandlast=zeros(length(anchored_trajectories{a}),2);
        for b=1:length(anchored_trajectories{a})
            firstandlast(b,:)=allTraj{anchored_trajectories{a}(b)}(1,6:7);
        end
        anchor_frames{end+1}=firstandlast;
    end
    end

    % Find the first and the last frame for each anchor
    function first_last_frames = firstLastFrame(anchor_frames)
    first_last_frames=zeros(length(anchor_frames),2);
    for q=1:length(anchor_frames)
        first_last_frames(q,:)=[min(anchor_frames{q}(:)),max(anchor_frames{q}(:))];
    end
    end