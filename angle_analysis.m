function [ degrees ] = angle_analysis( trajs )
% break into 2 vectors (3 consecutive coords)
% dot product: dot(a, b) = norm(a)*norm(b)*cos(theta)
% theta = angle between vectors a and b

% returns in radians: [0 pi]
radians = [];
for i=1:numel(trajs)
    traj = trajs{i}(:,1:2);
    % find the x and y consecutive displacement for each trajectory to
    % create the vectors
    xydisp = [diff(traj(:,1)), diff(traj(:,2))];
    for j = 1:size(xydisp, 1)-1
        v0 = xydisp(j, :);
        v1 = xydisp(j+1, :);
        costheta = dot(v0, v1)/(norm(v0)*norm(v1));
        % find angle
        theta = acos(costheta);
        radians(end+1) = theta;
    end
end

degrees = 180 - (radians*360)/(2*pi);

end

