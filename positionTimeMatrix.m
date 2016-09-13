function [ position_time ] = positionTimeMatrix( finalTraj, LOC_ACC )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% pixel_size = cor_data.smt_params(1);
% LOC_ACC = cor_data.smt_params(2);
% Look into Tao's more
% % Sort by frame number
% frames_x_y = sortrows(cor_data.coords(2:end, 1:3), 1);
% frames_x_y(:,2:3) = frames_x_y(:,2:3) * pixel_size;
% % Find the last frame
% max_frame = frames_x_y(end,1);

frames_x_y = zeros(sum(cellfun(@numel,finalTraj))/7, 3);
counter = 0;
max_frame = 0;
for traj = 1:length(finalTraj)
    frames_x_y(counter + 1: counter + size(finalTraj{traj},1), :) = [finalTraj{traj}(:,5) finalTraj{traj}(:,1:2)];
    counter = counter + size(finalTraj{traj},1);
    if finalTraj{traj}(1,7) > max_frame
        max_frame = finalTraj{traj}(1,7);
    end
end

if counter ~= sum(cellfun(@numel,finalTraj))/7
    error('counter mismatch')
end

x_axis_range = [min(frames_x_y(:,2)) max(frames_x_y(:,2))];
y_axis_range = [min(frames_x_y(:,3)) max(frames_x_y(:,3))];
x_bins = ceil((x_axis_range(2) - x_axis_range(1)) / LOC_ACC);
y_bins = ceil((y_axis_range(2) - y_axis_range(1)) / LOC_ACC);

% The position is ordered in (x bin position, y bin position)
% i.e. [1 (x bin) 1 (y bin); 1 (x bin) 2 (y bin); ... ; 1 (x bin) n
% (y bin); 2 (x bin) 1 (y bin); ... ; n (x bin) n (y bin)]

index_array = zeros(length(frames_x_y), 2);
counter = 0;

for coord = 1:length(frames_x_y)
    x_bin_idx = mod(frames_x_y(coord, 2) - x_axis_range(1), LOC_ACC);
    y_bin_idx = mod(frames_x_y(coord, 3) - y_axis_range(1), LOC_ACC);
    if x_bin_idx == 0
        x_bin_idx = (frames_x_y(coord, 2) - x_axis_range(1)) / LOC_ACC + 1;
        y_bin_idx = ceil((frames_x_y(coord, 3) - y_axis_range(1)) / LOC_ACC);
    elseif y_bin_idx == 0
        y_bin_idx = (frames_x_y(coord, 3) - y_axis_range(1)) / LOC_ACC + 1;
        x_bin_idx = ceil((frames_x_y(coord, 2) - x_axis_range(1)) / LOC_ACC);
    else
        x_bin_idx = ceil((frames_x_y(coord, 2) - x_axis_range(1)) / LOC_ACC);
        y_bin_idx = ceil((frames_x_y(coord, 3) - y_axis_range(1)) / LOC_ACC);
    end
    
    % create index value arrays for 1s in the sparse matrix
    counter = counter + 1;
    index_array(counter, :) = [(x_bin_idx - 1) * y_bins + y_bin_idx, frames_x_y(coord, 1)];
end

position_time = sparse(index_array(:, 1), index_array(:, 2), ones(size(index_array, 1),1), x_bins * y_bins, max_frame);

% % MATRIX TOO BIG, OUT OF MEMORY. HOW ABOUT SUBDIVIDING THE FIELD OF VIEW?
% segments = 10;
% x_segmented_bins = ceil(x_bins/segments);
% position_time = arrayfun(@(x) zeros(segmented_view, max_frame), cell(1,segments),'UniformOutput', false);

% % Since segments are ordered by x position (x bins), frames_x_y must also
% % be sorted by x position (each segment is going to be saved and deleted to
% % free memory) and subdivided into x segments
% frames_x_y = sortrows(frames_x_y, 2);
% lower_idx = 1;
% 
% for segment_idx = 1:segments
%     % Initialize the position and time matrix
%     position_time = zeros(x_segmented_bins*y_bins, max_frame);
%     % Select the correct x segment
%     remaining_coords = frames_x_y(lower_idx:end, :);
%     current_segment = remaining_coords(remaining_coords(:, 2) < (segment_idx * x_segmented_bins * LOC_ACC), :);
%     lower_idx = lower_idx + size(current_segment, 1);
% 
%     % FIX FROM HERE!!!
%     for coord = 1:length(current_segment)
%         bins = ceil((current_segment(1,2:3) - [x_axis_range(1) y_axis_range(1)]) / LOC_ACC);
%         position_time((bins(1) - 1) * y_bins + bins(2), current_segment(coord,1)) = 1;
%     end
%     
%     % save and clear memory
%     save('filename','position_time')
%     clearvars 'position_time'
%     
% end

end

