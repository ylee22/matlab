function [ avgTraj20ms ] = averageFrames( totalTraj )
%UNTITLED Summary of this function goes here
%   Use this function to make slower frame rate trajectories (20 ms input 
%   => 40 ms output)

avgTraj20ms = {};
for i = 1:length(totalTraj)
    XavgTraj20ms = [];
    YavgTraj20ms = [];
    for j = 1:2:size(totalTraj{i},1)
        if j+1<=size(totalTraj{i},1)
            XavgTraj20ms(end+1) = mean(totalTraj{i}(j:j+1,1));
            YavgTraj20ms(end+1) = mean(totalTraj{i}(j:j+1,2));
        end
    end
    avgTraj20ms{end+1} = [XavgTraj20ms' YavgTraj20ms'];
end

end

