function anchoredTraj = convertSpotsIntoTraj(anchoredSpots, immobile_coords)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

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
