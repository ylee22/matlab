function [ radius_and_coords ] = finalize_anchor( IDX, anchored_coords, GLOBAL_DENSITY )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

radius_and_coords = zeros(max(IDX),4);
for i=1:max(IDX)
    % Find anchor center
    x_y_anchor_coord = mean(anchored_coords(IDX==i,:));
    % Define anchor radius
    radius = max(pdist2(x_y_anchor_coord,anchored_coords(IDX==i,:)));

    % Check to make sure that it's more dense than expected
    expected_number_of_points = ceil(GLOBAL_DENSITY*pi*radius^2);
    if 1-poisscdf(sum(IDX==i), expected_number_of_points) < 0.05

        % Save to a variable
        radius_and_coords(i,:) = [radius, x_y_anchor_coord, sum(IDX==i)];
        
    end
end

radius_and_coords = radius_and_coords(radius_and_coords(:,1) > 0, :);

end

