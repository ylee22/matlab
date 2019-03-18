function plot_s2_time( start_path, runinput, finalTraj, time_window, interested_state )
% no output, just plots
% time_window: nx2 matrix (each pair indicates the time window in minutes)
% start_path = '/mnt/data0/yerim/vbSPT1.1.4_20170411/traj_connection_carey/ss_rkd/cyto_lat_treatment/11.8.2017';
% runinput='trajs_max_800_nm_dox_5_ss_rkd_2_runinput';

[ ~, ~, ~, spaths ] = get_vbSPT_results( start_path, runinput );

% segment into 10 min sections
traj_frames = cellfun(@(x) max(x(:,3)), finalTraj);

% convert minutes into frames with overlapping window
frame_window = round(time_window*60/0.035);

traj_segments = cell(1, size(frame_window, 1));
smaxp_segments = cell(1, size(frame_window, 1));

for t = 1:size(frame_window, 1)
    curr_seg = traj_frames >= frame_window(t, 1) + 1 & traj_frames <= frame_window(t, 2);
    traj_segments{t} = finalTraj(curr_seg);
    smaxp_segments{t} = spaths(curr_seg);
end

% after segmenting, pull out end state only, and make a map
points = cell(1, size(frame_window, 1));
for seg = 1:numel(smaxp_segments)
    s2 = cellfun(@(x) ismember(interested_state, x),smaxp_segments{seg});
    trajs = traj_segments{seg}(s2);
    states = smaxp_segments{seg}(s2);
    
    % pull out points
    for t = 1:numel(trajs)
        curr_traj = trajs{t};
        curr_state = states{t};
        
        % a state segment can occur multiple times in a trajectory
        % find the indices of the interested state
        idx = find(curr_state == interested_state);
        idx = unique([idx idx+1]);

        points{seg} = cat(1, points{seg}, curr_traj(idx, :));
    end
end

% make map over time, overlapping window
f = figure;
loops = numel(points);
% F(loops) = struct('cdata', [], 'colormap', []);
v = VideoWriter(strjoin({strrep(runinput, 'runinput', 'movie'), '.avi'}, ''));
v.FrameRate = 1;
open(v);
for i = 1:loops
    scatter(points{i}(:,1), points{i}(:,2), '.')
    hold on;
    drawnow;
    frame = getframe(f);
    writeVideo(v, frame);
end
close(v);

legend(num2str(time_window))

end

