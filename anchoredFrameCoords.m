function [traj_coords, frame_displacement] = anchoredFrameCoords(finalTrajCoords, finalTrajIdx)
% Returns a n by 2 matrix of just x, y coordinates of the all the anchored
% trajectories
    number_columns = size(finalTrajCoords{1},2);
    traj_coords = zeros(sum(cellfun(@numel,finalTrajCoords(finalTrajIdx))/number_columns), 2);
    % Displacement is going to have one lesse element than coordinates each
    % time
    frame_displacement = zeros(1,size(traj_coords,1) - numel(finalTrajIdx));
    COUNTER = 1;
    for trajs = 1:numel(finalTrajIdx)
        temp_traj_coords = finalTrajCoords{finalTrajIdx(trajs)}(:,1:2);
        temp_frame_disp = adjacentFrameDisplacement(temp_traj_coords);
        LENGTH = numel(temp_frame_disp);
        traj_coords(COUNTER:COUNTER + LENGTH,:) = temp_traj_coords;
        % COUNTER is based off of the traj_coords index but for each cycle,
        % frame_displacement has one less element than traj_coords
        frame_displacement(COUNTER - trajs + 1:COUNTER - trajs + LENGTH) = temp_frame_disp;
        COUNTER = COUNTER + LENGTH + 1;
    end

end

function frame_by_frame_displacement = adjacentFrameDisplacement(coordinates)
    frame_by_frame_displacement = zeros(length(coordinates)-1,1);
    for i=1:length(coordinates)-1
        frame_by_frame_displacement(i) = pdist2(coordinates(i,:),coordinates(i+1,:));
    end
end
