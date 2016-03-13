function [ anchor_coords, anchoredSpots, immobile_coords ] = findImmobileAnchors( finalTraj, localization_acc, cell_area )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    % Find all adjacent frames that traveled less than the localization
    % accuracy and put them into an n by 5 matrix
    % [traj row number in finalTraj, 1st frame, 2nd frame, averaged x,
    % averaged y]
    immobile_coords=[];
    for i=1:length(finalTraj)
        for j=1:size(finalTraj{i},1)-1
            if pdist2(finalTraj{i}(j,1:2),finalTraj{i}(j+1,1:2))<localization_acc
                immobile_coords(end+1,:)=[i,j,j+1,mean(finalTraj{i}(j:j+1,1:2))];
            end
        end
    end

    % KD Tree of all the trajectory centers
    kd_center=KDTreeSearcher(immobile_coords(:,4:5));

    % Indices of trajectories in finalTraj within the localization accuracy (20 nms)
    neighboringSpots = rangesearch(kd_center,immobile_coords(:,4:5),localization_acc);

    % Remove duplicate rows of overlapping trajectories
    % Sometimes two rows are identical, so remove the latter row
    neighboringSpots = removeDuplicateRows(neighboringSpots);

    % Find anchors here
    anchoredSpots = mergeImmobileSpots(neighboringSpots, localization_acc, immobile_coords);
    
    % Filter based on the minimum number of spots per anchor
    % Calculate the probability and the threshold for min spots/anchor
    anchor_coords={};
    for anchor_radius_idx=1:length(anchoredSpots)
        if ~isempty(anchoredSpots{anchor_radius_idx})
            expected_number_of_immobile_spots=(length(immobile_coords)/cell_area)*pi*(20*anchor_radius_idx)^2;
            minAnchoredSpots=2;
            probability=1;
            while probability>0.05
                minAnchoredSpots=minAnchoredSpots+1;
                probability=1-poisscdf(minAnchoredSpots,expected_number_of_immobile_spots);
            end
            anchoredSpots{anchor_radius_idx} = filterTraj(anchoredSpots{anchor_radius_idx}, minAnchoredSpots);
            if ~isempty(anchoredSpots{anchor_radius_idx})
                % Remake anchor coordinates
                anchor_coords{anchor_radius_idx}=findImmobileAnchorCoord(anchoredSpots,anchor_radius_idx,immobile_coords);                
            end
        end
    end
    
%     % Convert immobile spots into trajectories (same format as cluster
%     % anchor)
%     anchoredTraj = convertSpotsIntoTraj(anchoredSpots, immobile_coords);
    
end

function anchoredTraj = convertSpotsIntoTraj(anchoredSpots, immobile_coords)
anchoredTraj = cell(1,length(anchoredSpots));
for anchor_size_idx = 1:length(anchoredSpots)
    if ~isempty(anchoredSpots{anchor_size_idx})
        temp = cell(1,length(anchoredSpots{anchor_size_idx}));
        for anchoredSpots_idx = 1:length(anchoredSpots{anchor_size_idx})
            temp{anchoredSpots_idx} = unique(immobile_coords(anchoredSpots{anchor_size_idx}{anchoredSpots_idx},1))';
        end
        anchoredTraj{anchor_size_idx} = temp;
    end
end

end
