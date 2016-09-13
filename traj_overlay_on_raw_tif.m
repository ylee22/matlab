cd /mnt/data0/yerim/SMT

x = loadcor;

cd /mnt/data0/yerim/Trajectory_Analysis/findDiffSizedAnchors/4.19.2016/fixed_duplicate_traj_rows/total_var_100_dbscan_50
load('RKD10_RMS5_9900frames.mat')

cd /mnt/data0/yerim/Trajectory_Analysis/4.19.2016
load('RKD10_RMS5_9900frames.mat','finalTraj')

cd /mnt/data0/yerim/imaging/PAmCherry-KRAS/4.19.2016/RKD_10

filename = strtrim(ls('*.tif'));

mov_frame_idx = 0;
pixel_size = x.smt_params(1);

anchored_trajs = [anchor_trajs_3{:}];
final_info = zeros(numel(finalTraj), 4);
counter = 0;
anchored_idx = [];

% Need to convert finalTrajmin5 to matrix [start, end, anchored/free marker, finalTrajmin5 row idx]
% I'm changing it to draw all coordinates
for traj_idx = 1:numel(finalTrajmin5)
    if ismember(traj_idx, anchored_trajs)
        counter = counter + 1;
        final_info(counter, :) = [finalTrajmin5{traj_idx}(1, 6:7), 1, traj_idx];
        % anchored_idx is the row number in finalTraj
        anchored_idx = cat(1,anchored_idx,unique(finalTrajmin5{traj_idx}(:,4)));
%     else
%         final_info = cat(1,final_info,[finalTrajmin5{traj_idx}(1,6:7), 0, traj_idx]);
    end
end

% Find all other free trajs
for i = 1:length(finalTraj)
    if ~ismember(i, anchored_idx)
        counter = counter + 1;
        final_info(counter, :) = [finalTraj{i}(1, 6:7), 0, i];
    end
end

final_info = final_info(1:counter, :);

tot_frames = 1000;
movie_frame(1:tot_frames) = struct('cdata',[],'colormap',[]);
for i = 1:tot_frames
    frame = imread(filename,i);
    imagesc(frame)
    caxis([300 2000])
    colormap gray
    hold on;

    % figure out the pixel position
    % switch x and y
    % add back in the gold fiducial
    
    current_traj = final_info(final_info(:,1) <= i, :);
    current_traj = current_traj(current_traj(:,2) >= i, :);

    for j = 1:size(current_traj,1)
        
        if current_traj(j, 3) == 1
            if i > size(finalTrajmin5{current_traj(j,4)}, 1)
                last_idx = size(finalTrajmin5{current_traj(j,4)});
            else
                last_idx = i;
            end
            plot(finalTrajmin5{current_traj(j,4)}(1:last_idx,2)/pixel_size,finalTrajmin5{current_traj(j,4)}(1:last_idx,1)/pixel_size,'r','LineWidth',2)
        else
            if i > size(finalTraj{current_traj(j,4)}, 1)
                last_idx = size(finalTraj{current_traj(j,4)});
            else
                last_idx = i;
            end
            plot(finalTraj{current_traj(j,4)}(1:last_idx,2)/pixel_size,finalTraj{current_traj(j,4)}(1:last_idx,1)/pixel_size,'g','LineWidth',2)
        end
        
    end

    axis([50 200 50 200])
    
    % capture figure as movie
    % movie2avi function to turn it into avi
    movie_frame(i) = getframe;
    close
end