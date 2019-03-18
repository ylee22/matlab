function [ finalTraj ] = add_columns( traj )
% Need to add columns 4, 5, 6, 7

finalTraj = cell(1, numel(traj));

for i = 1:numel(traj)
    % sort by frame number
    temp_traj = sortrows(traj{i}, 3);
    
    % 1: x, 2: y, 3 and 4: 0, 5: frame number, 6: starting frame number, 7:
    % ending frame number
    finalTraj{i} = [temp_traj(:, 1:2) zeros(size(temp_traj, 1), 2) temp_traj(:,3) ones(size(temp_traj, 1), 1)*temp_traj(1,3) ones(size(temp_traj, 1), 1)*temp_traj(end,3)];
end

end

