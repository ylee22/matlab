function [ traj_den_per_frame ] = TrajDenperFrame( finalTraj, cell_area )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

frames = [];
for i = 1:length(finalTraj)
    frames = cat(1, frames, finalTraj{i}(:,5));
end

traj_den_per_frame = zeros(max(frames), 2);
for i = 1:length(traj_den_per_frame)
    traj_den_per_frame(i, 1) = sum(frames == i);
end

traj_den_per_frame(:, 2) = traj_den_per_frame(:, 1)/cell_area*10^6;

end

