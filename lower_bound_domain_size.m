function [ domainlbsize, state_coords, mid_points ] = lower_bound_domain_size( spaths, finalTraj, interested_state )
% find the distance traveled for every continuous patch of states to
% calculate the lower bound on the domain size
% also returns coordinates associated with the input state

states = vertcat(spaths{:});
num_transitions = sum(diff(states));
num_transitions = num_transitions + (num_transitions - 1);

domainlbsize = zeros(1, num_transitions);
state_coords = {};
mid_points = {};

c = 0;
for s = 1:numel(spaths)
    traj = finalTraj{s};
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
            domainlbsize(c) = max(pdist(traj(first(i):last(i), 1:2)));
            state_coords{end+1} = traj(first(i):last(i), :);
            mid_points{end+1} = (traj(first(i):last(i)-1,:) + traj(first(i)+1:last(i),:))/2;
        end
    end
end

domainlbsize = domainlbsize(1:c);

end
