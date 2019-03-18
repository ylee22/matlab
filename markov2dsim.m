function [ xcoords, ycoords, states ] = markov2dsim( diff_coeff, occupancy, temp_trans_matrix, num_particles, dt, simtime, width )
% generate trajectories using a markov model
% inputs: transition matrix, occupancy, diffusion coefficients
% outputs: x, y coordinates

% if sum(sum(temp_trans_matrix, 2) ~= 1) > 0
%     error('transition probabilities do not sum to 1')
% end

% convert the transition matrix into a cell array where each cell is the
% transition range from state i to all states
transitions = cell(1, size(temp_trans_matrix, 1));
for s = 1:numel(transitions)
    lower = cumsum([0 temp_trans_matrix(s, 1:end-1)]);
    upper = cumsum(temp_trans_matrix(s, :));
    transitions{s} = [lower' upper'];
end

% find the time steps to be simulated (include t0)
timesteps = numel(dt:dt:simtime);

% state at each time step
states = zeros(num_particles, timesteps);

% transition over time (for t1 through tlast)
transition_prob = rand(num_particles, timesteps);

% assign x, y coord over time
xcoords = zeros(num_particles, timesteps);
ycoords = zeros(num_particles, timesteps);
% assuming a square
startx = rand(num_particles, 1)*width;
starty = rand(num_particles, 1)*width;

% for times t1 through tlast
for t = 1:timesteps
    % new displacement for every time point
    dispx = zeros(num_particles, 1);
    dispy = zeros(num_particles, 1);
    
    % for the first time step, assign state based on occupancy
    if t == 1
        occupancy = [cumsum([0 occupancy(1:end-1)])' cumsum(occupancy)'];
        % assuming that the order of occupancy matches the diff coeff
        for o=1:size(occupancy,1)
            ps2 = transition_prob(:, t) > occupancy(o, 1) & transition_prob(:, t) < occupancy(o, 2);
            % assign displacements
            % x = sqrt(2Dt) for each dimension
            speed_1d = sqrt(2*diff_coeff(o)*dt);
            dispx(ps2) = randn(sum(ps2), 1)*speed_1d;
            dispy(ps2) = randn(sum(ps2), 1)*speed_1d;
            % o = state
            states(ps2, t) = o;
        end

        % assign new coordinates
        xcoords(:, t) = startx + dispx;
        ycoords(:, t) = starty + dispy;
    else

        % determine current state from the prior state
        for s1 = 1:max(states(:, t-1))
            % determine next state by where the rand falls using the transition
            % prob from the prior state
            pidx = find(states(:, t-1)==s1);
            for s2 = 1:size(transitions{s1}, 1)
                % find particles that transitioned from s1 -> s2
                ps2 = transition_prob(pidx, t) > transitions{s1}(s2,1) & transition_prob(pidx, t) < transitions{s1}(s2,2);
                % assign current states
                states(pidx(ps2), t) = s2;
                % assign displacements from state s2
                % x = sqrt(2Dt) for each dimension
                speed_1d = sqrt(2*diff_coeff(s2)*dt);
                dispx(pidx(ps2)) = randn(sum(ps2), 1)*speed_1d;
                dispy(pidx(ps2)) = randn(sum(ps2), 1)*speed_1d;
            end
        end

        % assign new coordinates
        xcoords(:, t) = xcoords(:, t-1) + dispx;
        ycoords(:, t) = ycoords(:, t-1) + dispy;

    end
    
end

xcoords = [startx xcoords];
ycoords = [starty ycoords];

% wrap around
% xcoords(xcoords<0) = xcoords(xcoords<0) + width;
% xcoords(xcoords>width) = xcoords(xcoords>width) - width;
% ycoords(ycoords<0) = ycoords(ycoords<0) + width;
% ycoords(ycoords>width) = ycoords(ycoords>width) - width;

end

