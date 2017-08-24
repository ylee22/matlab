function [ mergedFinalTraj, mergedTraj, mergeMultTraj ] = combineTraj_lessmemory( finalTraj, merge_frame_threshold, dist_threshold )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% dist_threshold as defined by Tao in SMT:
% divides both the x,y coordinate and the max distance into 20 nm blocks

% Find start and ending frames (column 6 and 7)
% Indices in first_last_frames are the trajectory indices in finalTraj
first_last_frames=zeros(length(finalTraj),2,'single');
for a=1:length(finalTraj)
    first_last_frames(a,:)=[finalTraj{a}(1,6),finalTraj{a}(1,7)];
end

first_second_traj=[];
for i=1:length(first_last_frames)
    % Find trajectories with the frame threshold
    % calculate the distance between the last frame of traj i and first
    % frame for the rest of the traj
    frameDist=pdist2(first_last_frames(i,2),first_last_frames(:,1));
    % set same trajectory to 0
    frameDist(i)=0;
    % the difference between the first and the last frame must be <=
    % frame threshold
    next_traj = find(frameDist > 0 & frameDist <= merge_frame_threshold);
    % Last frame must come before the start frame!
    % The start frame of the 2nd trajectory must come after the last frame of
    % the 1st trajectory (if last frame i, then start is i+2)
    next_traj = next_traj(first_last_frames(next_traj,1) > first_last_frames(i,2));
    first_second_traj = [first_second_traj;[repmat(i,[length(next_traj),1]), next_traj']];
end

% mergedTraj is the finalTraj indices
mergedTraj = [];
% Check their distance, which should depend on the number of frames skipped!
for b=1:size(first_second_traj,1)
    % Modify dist_threshold depending on the frame number skipped
    new_dist_threshold=dist_threshold*(first_last_frames(first_second_traj(b,2),1)-first_last_frames(first_second_traj(b,1),2));
    if pdist2(finalTraj{first_second_traj(b,1)}(end,1:2),finalTraj{first_second_traj(b,2)}(1,1:2)) < new_dist_threshold
        mergedTraj(end+1,:) = [first_second_traj(b,1), first_second_traj(b,2)];
    end
end

% There is nothing to be merged
% assert throws an error when condition is false
assert(~isempty(mergedTraj), 'There are no trajectories to be merged')

% Can't have 1 trajectory being merged to 2 different trajectories
while length(unique(mergedTraj(:,1))) ~= length(mergedTraj(:,1))
    disp('A single trajectory is trying to be split into multiple different trajectories')
    % Throw them out
    [n, bin] = histc(mergedTraj(:,1), unique(mergedTraj(:,1)));
    multiple = find(n > 1);
    disp(length(multiple))
    index = ismember(bin, multiple);
    invalid_trajectories=unique(mergedTraj(index,:));
    for g=1:length(invalid_trajectories)
        finalTraj{invalid_trajectories(g)}=[];
    end
    mergedTraj = mergedTraj(~index, :);
end

% Can't have 2 different trajectories being merged to the same trajectory
while length(unique(mergedTraj(:,2))) ~= length(mergedTraj(:,2))
    disp('Multiple trajectories are trying to be merged into a single trajectory')
    % Throw them out
    [n, bin] = histc(mergedTraj(:,2), unique(mergedTraj(:,2)));
    multiple = find(n > 1);
    disp(length(multiple))
    index = ismember(bin, multiple);
    invalid_trajectories=unique(mergedTraj(index,:));
    for h=1:length(invalid_trajectories)
        finalTraj{invalid_trajectories(h)}=[];
    end
    mergedTraj = mergedTraj(~index, :);
end

% Have to get rid of empty trajectories trajectories from mergedTraj list
% (if [a b ; b c], and 1st line was deleted, b is empty, so need to delete
% the 2nd line)
deleted_trajs = find(cellfun(@(x) isempty(x), finalTraj) ~= 0);
idx1 = ismember(mergedTraj(:, 1), deleted_trajs) > 0;
mergedTraj = mergedTraj(~idx1, :);
idx2 = ismember(mergedTraj(:, 2), deleted_trajs) > 0;
mergedTraj = mergedTraj(~idx2, :);

% Find more than 2 trajectories merging together (a & b, b & c = a & b & c)
mergeMultTraj={};
for c=1:length(mergedTraj)
    if mergedTraj(c,2)>0
        nextTraj_index=find(mergedTraj(:,1)==mergedTraj(c,2));
        tempTrajHolder=[];
        while nextTraj_index
            if isempty(tempTrajHolder)
                tempTrajHolder=unique([mergedTraj(c,:),mergedTraj(nextTraj_index,:)]);
            else
                tempTrajHolder=unique([tempTrajHolder,mergedTraj(nextTraj_index,:)]);
            end
            % Save the next trajectory to be searched before the row gets
            % marked for deletion
            nextTraj=mergedTraj(nextTraj_index,2);
            % Mark both of the merged rows for deletion
            mergedTraj(c,:)=[-1, -1];
            mergedTraj(nextTraj_index,:)=[-1, -1];
            % Find the next trajectory in the chain
            nextTraj_index=find(mergedTraj(:,1)==nextTraj);
        end
        if tempTrajHolder
            mergeMultTraj{end+1}=tempTrajHolder;
        end
    end
end

% Remove rows marked for deletion
mergedTraj=mergedTraj(mergedTraj(:,1)>0,:);

% Combine trajectories
for d=1:length(mergeMultTraj)
    first_traj=mergeMultTraj{d}(1);
    for e=2:length(mergeMultTraj{d})
        trajectory_idx=mergeMultTraj{d}(e);
        finalTraj{first_traj} = [finalTraj{first_traj};finalTraj{trajectory_idx}];
        finalTraj{trajectory_idx}=[];
    end
    finalTraj{first_traj}(:,6)=min(finalTraj{first_traj}(:,5));
    finalTraj{first_traj}(:,7)=max(finalTraj{first_traj}(:,5));
end

for f=1:length(mergedTraj)
    if ~isempty(finalTraj{mergedTraj(f,1)})
        finalTraj{mergedTraj(f,1)}=[finalTraj{mergedTraj(f,1)};finalTraj{mergedTraj(f,2)}];
        finalTraj{mergedTraj(f,2)}=[];
        finalTraj{mergedTraj(f,1)}(:,6)=min(finalTraj{mergedTraj(f,1)}(:,5));
        finalTraj{mergedTraj(f,1)}(:,7)=max(finalTraj{mergedTraj(f,1)}(:,5));
    end
end

% Remove cell arrays with empty matrices
mergedFinalTraj = finalTraj(~cellfun('isempty',finalTraj));

end

