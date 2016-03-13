function [ frameByFrameDisp ] = dispAdjFrames( totalTraj )
%UNTITLED Summary of this function goes here
%   Used to make instaneous displacement histograms
frameByFrameDisp = [];
for i=1:length(totalTraj)
    for j=1:size(totalTraj{i},1)
        if j<size(totalTraj{i},1)
            frameByFrameDisp(end+1) = pdist(totalTraj{i}(j:j+1,1:2));
        end
    end
end

