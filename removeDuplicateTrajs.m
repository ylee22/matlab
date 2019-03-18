function [ unique_trajs ] = removeDuplicateTrajs( finalTraj )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

first_coord = cellfun(@(x) x(1,1), finalTraj);

% find indices where the values are the same
[~,i,~] = unique(first_coord);

% make sure that the indices with same first coordinate are duplicates


end

