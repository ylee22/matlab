function plot_sMaxP( spaths, finalTraj, start_traj, end_traj )
% no output, just plot traj segments with a different color for each state

figure
c = get(gca,'colororder');
% plot them in the following order: free (state 3), intermediate (state 2),
% anchored (state 1) and intermediate gets line thickness 2
state_colors = [c(1:2,:); c(5,:)];

for traj = start_traj:end_traj
    currtraj = finalTraj{traj};
    states = spaths{traj};
    for start = 1:size(currtraj, 1) - 1
        if states(start) == 3
            plot(currtraj(start:start + 1, 1), currtraj(start:start + 1, 2), 'color', state_colors(states(start), :))
            hold on
        else
            plot(currtraj(start:start + 1, 1), currtraj(start:start + 1, 2), 'color', state_colors(states(start), :), 'LineWidth', 2)
            hold on
        end
    end
end

axis equal