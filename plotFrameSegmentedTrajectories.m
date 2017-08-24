function plotFrameSegmentedTrajectories( segmented_trajs, anchored_traj, anchor_coords )

figure
cmap = colormap(jet(length(segmented_trajs)));
ang=0:0.01:2*pi;

% Plot anchored trajectories
for i=1:length(segmented_trajs)
    color = cmap(i, :);
    curr_anch_trajs = anchored_traj{i};
    curr_trajs = segmented_trajs{i};
    curr_anch_coords = anchor_coords{i};
    
    % plot trajs
    for j = 1:numel(curr_anch_trajs)
        % plot anchors
        xp=curr_anch_coords(j,1)*cos(ang);
        yp=curr_anch_coords(j,1)*sin(ang);
        % plot the anchor
        plot(curr_anch_coords(j,2) + xp, curr_anch_coords(j,3) + yp,'Linewidth',2,'Color', color);
        hold on
        
        % plot the traj
        for t = 1:numel(curr_anch_trajs{j})
            plot(curr_trajs{curr_anch_trajs{j}(t)}(:,1),curr_trajs{curr_anch_trajs{j}(t)}(:,2),'Color', color);
        end
    end
end

axis equal
colorbar

end