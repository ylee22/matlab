clear;clc

folder_list = dir('*201*');
curr_folder = pwd;
all_anchor_info = struct('life_time', [], 'trajs_anchored', [], 'anchor_duration_per_traj', {}, 'anchor_size', [], 'traj_den', []);
counter = 1;

for idx1 = 1:length(folder_list)
    
    cd(strcat(curr_folder,'/',folder_list(idx1).name))

    file_list = dir('*mat');

    for idx2 = 1:length(file_list)
        
        cd(strcat(curr_folder,'/',folder_list(idx1).name))
        
        load(file_list(idx2).name, 'finalTrajmin5', 'anchor_trajs', 'anchor_coords', 'cell_area')
        
        cd(strcat('/mnt/data0/yerim/Trajectory_Analysis/FBDMEM_no_prolong/SS_RKD/',folder_list(idx1).name))
        
        load(file_list(idx2).name,'timestep', 'finalTraj')
        
        anchor_time_number_trajs = zeros(length(anchor_trajs), 2);

        % screen for anchors with more than 1 trajectory
        multiple_traj_anchor_idx = find(cellfun(@(x) numel(x) > 1, anchor_trajs) > 0);
        anchor_first_last_frames = zeros(numel(multiple_traj_anchor_idx), 2);

        % finalTrajmin5 column 6 and 7 are the first and last frames for the
        % trajectory (end-1:end)
        for i = 1:numel(multiple_traj_anchor_idx)
            trajs = anchor_trajs{multiple_traj_anchor_idx(i)};
            frames = zeros(numel(trajs), 2);
            for j = 1:numel(trajs)
                frames(j, :) = finalTrajmin5{trajs(j)}(1,6:7);
            end
            anchor_first_last_frames(i, :) = [min(frames(:)) max(frames(:))];
        end
        
        anchor_life_time = (anchor_first_last_frames(:,2) - anchor_first_last_frames(:,1))*timestep;
        
        % Anchor life time (0 indicate anchors with single trajectories)
        temp_life_time = zeros(length(anchor_trajs), 1);
        temp_life_time(multiple_traj_anchor_idx) = anchor_life_time;
        all_anchor_info(counter).life_time = temp_life_time;

        % Number of anchored traj per anchor
        all_anchor_info(counter).trajs_anchored = cellfun(@numel, anchor_trajs);
        
        % anchor duration per trajectory        
        anchor_duration = anchor_duration_per_traj(anchor_trajs, anchor_coords, finalTrajmin5, multiple_traj_anchor_idx);
        all_anchor_info(counter).anchor_duration_per_traj = anchor_duration;
        
        % anchor size
        all_anchor_info(counter).anchor_size = anchor_coords(:,1);
        
        % trajectory density
        all_anchor_info(counter).traj_den = length(finalTraj)/cell_area*10^6;
        
        counter = counter + 1 ;
        
        clear finalTrajmin5 anchor_trajs
        
    end
    
end
