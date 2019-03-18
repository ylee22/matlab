function [ s_points ] = collapse_markov2dsim_states( x, y, s )
% collapse continuous state segments into single points

% mark start of each trajectory with -1, in case there is a wrap around
s = [ones(size(s,1),1)*-1 s];
s1d = reshape(s', 1, numel(s));

% reshape x and y to match s1d
x1d = reshape(x', 1, numel(x));
y1d = reshape(y', 1, numel(y));

s_points = cell(1, max(s1d));
for curr_state=1:max(s1d)
    % idx1 is the last point of the segment (t1 to t2, then idx=t2)
    idx1 = find(s1d == curr_state);

    if ~isempty(idx1)
        % find each continuous segment (change of > 1 indicates jump in index)
        idx2 = find(diff(idx1)>1) + 1;
        % start of each segment (find t1, one before t2)
        first = [idx1(1), idx1(idx2)] - 1;
        % end of each segment (t2, so no need to change idx1 values)
        last = [idx1(idx2 - 1), idx1(end)];

        temp_points = zeros(numel(first), 2);
        % loop through each found segment and then average the segment
        % positions
        for i = 1:numel(first)
            temp_points(i, 1) = mean(x1d(first(i):last(i)));
            temp_points(i, 2) = mean(y1d(first(i):last(i)));
        end
    end
    
    s_points{curr_state} = temp_points;
end

end

