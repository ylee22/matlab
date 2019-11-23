function drawdomains_2D( domains, finalTraj, state )
% plot z stack of the domains over time using slice

figure
% plot the trajectories in gray
for i = 1:numel(finalTraj)
    plot(finalTraj{i}(:,1), finalTraj{i}(:,2), 'color', [0.7 0.7 0.7])
    hold on
end
% plot grouped domains
for d = 1:numel(domains)
    curr = domains(d).dpoints;
    curr = curr(curr(:,4)==state, 1:2);
    color = rand(1,3);
    scatter(curr(:,1), curr(:,2), [], color, '.')
    % plot the boundary
    plot(domains(d).boundaries(:,1), domains(d).boundaries(:,2), 'color', color)
end

axis equal

end
