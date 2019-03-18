function [ totalTraj20ms ] = skipFrames( totalTraj )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

totalTraj20ms = {};
for i = 1:length(totalTraj)
    totalTraj20ms{end+1} = totalTraj{i}(1:2:end,:);
end

end

