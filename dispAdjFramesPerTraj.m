function [ frameByFrameDispPerTraj ] = dispAdjFramesPerTraj( totalTraj )
%UNTITLED Summary of this function goes here
%   Was used to make FCS data
frameByFrameDispPerTraj = {};
for i=1:length(totalTraj)
    temporary_traj=[];
    for j=1:size(totalTraj{i},1)-1
        temporary_traj(end+1) = pdist(totalTraj{i}(j:j+1,1:2));
    end
    frameByFrameDispPerTraj{i} = temporary_traj;
end


