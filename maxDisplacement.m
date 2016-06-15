function [ maxDispperTraj ] = maxDisplacement( totalTraj )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
maxDispperTraj=[];
for i=1:length(totalTraj)
    maxDispperTraj(end+1) = max(pdist(totalTraj{i}(:,1:2)));
end

