function [ s_points ] = collapse_vbspt_states( spaths, finalTraj, interested_state )
% extract the most likely sequence of states and collapses it into a single
% point per state segment
% s_points: averaged x, y coordinates for continuous segments, otherwise x,
% y coordinates for the single point for the state of interest

states = vertcat(spaths{:});
num_transitions = sum(diff(states));
num_transitions = num_transitions + (num_transitions - 1);

s_points = zeros(num_transitions, 2);

c = 0;
for s = 1:numel(spaths)
    traj = finalTraj{s}(:,1:2);
    states = spaths{s};
    % a state segment can occur multiple times in a trajectory
    % find the indices of the interested state
    idx1 = find(states == interested_state);
    % shift index by 1 because the states are the intervals between the
    % coords, idx1 is the last point of the segment (t1 to t2, then idx=t2)
    idx1 = idx1 + 1;
    if ~isempty(idx1)
        % find each continuous segment (change of > 1 indicates jump in index)
        idx2 = find(diff(idx1)>1) + 1;
        % start of each segment (find t1, one before t2)
        first = [idx1(1); idx1(idx2)] - 1;
        % end of each segment (t2, so no need to change idx1 values)
        last = [idx1(idx2 - 1); idx1(end)];

        % loop through each found segment and then average the segment
        % positions
        for i = 1:numel(first)
            c = c + 1;
            s_points(c, :) = mean(traj(first(i):last(i), :), 1);
        end
    end
end

s_points = s_points(1:c,:);

end

