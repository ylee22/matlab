function [ anchored, duration, anchor_size, traj_den, all_types_per_movie ] = parse_anchor_info( anchor_type, anchor_info, all_types_per_movie, anchor_type_column )
% Filter anchor properties for the anchor type

anchored = zeros(1, size(anchor_type, 1));
duration = cell(1, size(anchor_type, 1));
anchor_size = zeros(1, size(anchor_type, 1));
traj_den = zeros(1, size(anchor_type, 1));
for i = 1:length(anchor_type)
    file = anchor_type(i, 1);
    row = anchor_type(i, 2);
    anchored(i) = anchor_info(file).trajs_anchored(row);
    duration{i} = anchor_info(file).anchor_duration_per_traj{row};
    anchor_size(i) = anchor_info(file).anchor_size(row);
    traj_den(i) = anchor_info(file).traj_den;
    all_types_per_movie(file, anchor_type_column) = all_types_per_movie(file, anchor_type_column) + 1;
end

end

