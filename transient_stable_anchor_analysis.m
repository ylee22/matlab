% Find which ones are stable and which ones are transient
% First convert from an array to a matrix with information for cell and row
all_anchors = [];
% 1: number singles, 2: number transient, 3: number stable, 4: total
anchor_type_per_movie = zeros(length(all_anchor_info), 4);
for i = 1:length(all_anchor_info)
    % 1: file, 2: row, 3: life time, 4: average anchor duration for
    % anchored trajs
    all_anchors = cat(1, all_anchors, [repmat(i, length(all_anchor_info(i).life_time), 1) [1:length(all_anchor_info(i).life_time)]' all_anchor_info(i).life_time cellfun(@mean,all_anchor_info(i).anchor_duration_per_traj)]);
    anchor_type_per_movie(i, 4) = size(all_anchor_info(i).anchor_size, 1);
end

% all anchors
[ all_anchored, all_duration, all_size, all_traj_den, ~ ] = parse_anchor_info( all_anchors, all_anchor_info, anchor_type_per_movie, 1 );

single_anchors = all_anchors(all_anchors(:,3) == 0, :);

% single anchor properties
[ single_anchored, single_duration, single_size, single_traj_den, anchor_type_per_movie ] = parse_anchor_info( single_anchors, all_anchor_info, anchor_type_per_movie, 1 );

single_duration = [single_duration{:}];

% anchors with min 2 anchored trajs
min_2_anchors = all_anchors(all_anchors(:, 3) > 0, :);

[ min_2_anchored, min_2_duration, min_2_size, min_2_traj_den, ~ ] = parse_anchor_info( min_2_anchors, all_anchor_info, anchor_type_per_movie, 1 );

min_2_traj_den2 = [];
min_2_anchored2 = [];
for i = 1:length(min_2_duration)
    min_2_traj_den2 = [min_2_traj_den2 repmat(min_2_traj_den(i), 1, numel(min_2_duration{i}))];
    min_2_anchored2 = [min_2_anchored2 repmat(min_2_anchored(i), 1, numel(min_2_duration{i}))];
end

min_2_duration2 = [min_2_duration{:}];
min_2_traj_den2 = min_2_traj_den2(min_2_duration2 > 0);
min_2_anchored2 = min_2_anchored2(min_2_duration2> 0);
min_2_duration2 = min_2_duration2(min_2_duration2 > 0);

% % kmeans with 2 then map it back to the correct movie and row
% idx = kmeans(min_2_anchors(:,end), 2);
% 
% if mean(min_2_anchors(idx==1, end)) > mean(min_2_anchors(idx==2, end))
%     transient = min_2_anchors(idx==2, :);
%     stable = min_2_anchors(idx==1, :);
% else
%     transient = min_2_anchors(idx==1, :);
%     stable = min_2_anchors(idx==2, :);
% end

transient = min_2_anchors(min_2_anchors(:, 3) < 3, :);
stable = min_2_anchors(min_2_anchors(:, 3) > 350, :);

% minimum 2 anchor properties
[ transient_anchored, transient_duration, transient_size, transient_traj_den, anchor_type_per_movie ] = parse_anchor_info( transient, all_anchor_info, anchor_type_per_movie, 2 );

[ stable_anchored, stable_duration, stable_size, stable_traj_den, anchor_type_per_movie ] = parse_anchor_info( stable, all_anchor_info, anchor_type_per_movie, 3 );

transient_traj_den2 = [];
transient_anchored2 = [];
for i = 1:length(transient_duration)
    transient_traj_den2 = [transient_traj_den2 repmat(transient_traj_den(i), 1, numel(transient_duration{i}))];
    transient_anchored2 = [transient_anchored2 repmat(transient_anchored(i), 1, numel(transient_duration{i}))];
end

transient_duration2 = [transient_duration{:}];
transient_traj_den2 = transient_traj_den2(transient_duration2 > 0);
transient_anchored2 = transient_anchored2(transient_duration2 > 0);
transient_duration2 = transient_duration2(transient_duration2 > 0);

stable_traj_den2 = [];
stable_anchor_life_time = [];
stable_anchored2 = [];
for i = 1:length(stable_duration)
    stable_traj_den2 = [stable_traj_den2 repmat(stable_traj_den(i), 1, numel(stable_duration{i}))];
    stable_anchor_life_time = [stable_anchor_life_time repmat(stable(i,3), 1, numel(stable_duration{i}))];
    stable_anchored2 = [stable_anchored2 repmat(stable_anchored(i), 1, numel(stable_duration{i}))];
end
stable_duration2 = [stable_duration{:}];
stable_anchored2 = stable_anchored2(stable_duration2 > 0);
stable_traj_den2 = stable_traj_den2(stable_duration2 > 0);
stable_duration2 = stable_duration2(stable_duration2 > 0);

% figure
% group = [zeros(size(transient_anchored)) ones(size(stable_anchored))];
% boxplot([transient_anchored stable_anchored], group)
% str = {'transient','stable'};
% set(gca, 'XTickLabel',str, 'XTick',1:numel(str))

% figure
% group = [zeros(size(single_duration)) ones(size(transient_duration2)) ones(size(stable_duration2))*2];
% boxplot([single_duration transient_duration2 stable_duration2], group)
% 
% figure
% group = [zeros(size(single_traj_den)) ones(size(transient_traj_den)) ones(size(stable_traj_den))*2];
% boxplot([single_traj_den transient_traj_den stable_traj_den], group)
% 
% figure
% group = [zeros(size(single_size)) ones(size(transient_size)) ones(size(stable_size))*2];
% boxplot([single_size transient_size stable_size], group)
% 
% figure
% scatter(transient_traj_den, transient_anchored)
% hold on
% scatter(stable_traj_den, stable_anchored)

% boxplot of anchored traj distribution across all traj densities
group = [];
anchored_traj_distrib = [];
avg_anchored_traj = [];
avg_duration = [];
for i = 1:length(all_anchor_info)
    group = [group ones(size(all_anchor_info(i).trajs_anchored))*all_anchor_info(i).traj_den];
    anchored_traj_distrib = [anchored_traj_distrib all_anchor_info(i).trajs_anchored];
    avg_anchored_traj = [avg_anchored_traj mean(all_anchor_info(i).trajs_anchored)];
    avg_duration = [avg_duration mean([all_anchor_info(i).anchor_duration_per_traj{:}])];
end

% anchor duration over trajectory density (messy isn't very helpful)
% avg anchor duration over trajectory density
% individual anchor duration for anchored trajectory
% anchor duration over anchor life time (average anchor duration per
% anchor)