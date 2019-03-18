function [ subsampleTrajs ] = skipframes( finalTraj, frames )
% subsample 12 ms trajectories every 3 frames to synthesize 36 ms data
subsampleTrajs = cell(1,numel(finalTraj)*2);
c = 0;

for i=1:numel(finalTraj)
    traj = finalTraj{i};
    % minimum of 4 frames
    if size(traj,1) > frames
        start = 1:(size(traj,1) - frames);
        for s = 1:numel(start)
            idx = start(s):frames:size(traj,1);
            c = c + 1;
            subsampleTrajs{c} = traj(idx, :);
        end
    end
end

subsampleTrajs = subsampleTrajs(1:c);

end

