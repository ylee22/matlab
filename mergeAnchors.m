function [newAnchoredTraj, anchoredTraj, anchor_coords] = mergeAnchors(neighboringAnchors, anchoredTraj, bigger_idx, smaller_idx, anchor_coords)
    % New anchored trajectory for new anchors
    newAnchoredTraj = {};

    % If it's a new anchor radius (a new entry in the cell array)
    % Filter out the empty and the single entry anchors (single
    % entries didn't have neighboring anchors if i==j)
    % Single entry for different sized anchors means that there minimum two
    % overlapping spots
    for anchor_coords_i_row_idx = 1:length(neighboringAnchors)
        if (bigger_idx==smaller_idx && length(neighboringAnchors{anchor_coords_i_row_idx})>=2) || (bigger_idx~=smaller_idx && length(neighboringAnchors{anchor_coords_i_row_idx})>=1)
            anchor_coords_j_rows = neighboringAnchors{anchor_coords_i_row_idx};
            % Combine the anchoredTraj from anchor_coord{i} and anchor_coord{j}
            temp = unique([anchoredTraj{bigger_idx}{anchor_coords_i_row_idx},anchoredTraj{smaller_idx}{anchor_coords_j_rows}]);
            if ~isempty(temp)
                % newAnchoredTraj holds the new combined anchor trajectories
                newAnchoredTraj{end+1}=temp;
                % Remove the combined anchoredTraj from i and j
                anchoredTraj{bigger_idx}{anchor_coords_i_row_idx}=[];
                for anchor_coords_j_idx=1:length(anchor_coords_j_rows)
                    anchoredTraj{smaller_idx}{anchor_coords_j_rows(anchor_coords_j_idx)}=[];
                end
            end
        end
    end
    
    % Remove anchor coordinates of the anchors that have been merged
    if bigger_idx==smaller_idx
        anchor_coords{bigger_idx}=anchor_coords{bigger_idx}(~cellfun(@isempty,anchoredTraj{bigger_idx}),:);
        anchoredTraj{bigger_idx} = filterTraj(anchoredTraj{bigger_idx},1);
    else
        % Rows of anchoredTraj match with rows of anchor_coords
        anchor_coords{bigger_idx}=anchor_coords{bigger_idx}(~cellfun(@isempty,anchoredTraj{bigger_idx}),:);
        anchor_coords{smaller_idx}=anchor_coords{smaller_idx}(~cellfun(@isempty,anchoredTraj{smaller_idx}),:);

        % Get rid of empty arrays in anchoredTraj
        anchoredTraj{bigger_idx} = filterTraj(anchoredTraj{bigger_idx},1);
        anchoredTraj{smaller_idx} = filterTraj(anchoredTraj{smaller_idx},1);
    end
end
