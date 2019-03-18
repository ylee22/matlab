function [ s123_counts, trjl_states ] = count_transitions( start_path, runinput )
% count the number of times a trajectory was in either state 2 or 3 before
% transitioning into or out of state 1 and plot colored trajectory map

s123_counts = [];
trjl_states = [];

cd(start_path)
%% Parse input

% if an existing file, generate options structure
if(isstr(runinput) && exist(runinput)==2)
    runinputfile = runinput;
    opt=VB3_getOptions(runinputfile);
    disp(['Read runinput file ' runinputfile])
    % if an option struct, read in the runinputfilename
elseif(isstruct(runinput))
    opt=runinput;
    runinputfile=opt.runinputfile;
    disp(['Read options structure based on runinput file ' runinputfile ])
else
    error(['Not a valid input, aborting']);
end

%% load the vbSPT model
res=load(opt.outputfile);
spaths = res.Wbest.est2.sMaxP;

if isempty(spaths)
    return
end

%% count the transitions into and out of state 1

% only want to count for the 3 state models
if max(vertcat(spaths{:})) > 3
    return
end

% find trajectories that transitioned into or out of state 1
s123 = cellfun(@(x) (ismember(1, x) & numel(unique(x)) > 1), spaths);
s123 = spaths(s123);

% count the number of times that a trajejctory was in state 2 or 3 before
% and after transitioning into state 1
s123_counts = zeros(2,2);
for i = 1:numel(s123)
    trajstate = s123{i};
    % immobile state indices
    s1_idx = find(trajstate == 1);
    % right before
    rb = min(s1_idx) - 1;
    % right after
    ra = max(s1_idx) + 1;

    if rb >= 1
        % row = 1: before state 1 (immobile state)
        % column = 1: state 2, column = 2: state 3
        s123_counts(1, trajstate(rb) - 1) = s123_counts(1, trajstate(rb) - 1) + 1;
    elseif ra <= numel(trajstate)
        % row = 2: after state 1 (immobile state)
        % column = 1: state 2, column = 2: state 3
        s123_counts(2, trajstate(ra) - 1) = s123_counts(2, trajstate(ra) - 1) + 1;
    end
end

%% count the number of trajectory lengths associated with each state

% row: trajectory lengths, column 1: state 1 count, column 2: state 2
% count, column 3: state 3 count
traj_length = res.Wbest.T;
trjl_states = zeros(max(traj_length), 3);

for traj = 1:numel(spaths)
    states = unique(spaths{traj});
    trjl_states(traj_length(traj), states) = trjl_states(traj_length(traj), states) + ones(1, numel(states));
end

end

