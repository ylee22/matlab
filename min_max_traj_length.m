function [ min_max_finalTraj ] = min_max_traj_length( finalTraj, minLength, maxLength )
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here
min_max_finalTraj={};
for i=1:length(finalTraj)
    if size(finalTraj{i}, 1) >= minLength && size(finalTraj{i}, 1) <= maxLength
        min_max_finalTraj{end+1} = finalTraj{i};
    end
end

end