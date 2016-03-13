function [ minTraj ] = minimumTrajLength( finalTraj, minLength )
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here
minTraj={};
for i=1:length(finalTraj)
    if size(finalTraj{i},1) >= minLength
        minTraj{end+1} = finalTraj{i};
    end
end

end

