function [ mergedFinalTraj, mergedTraj, mergeMultTraj ] = combineTraj_faster( finalTraj, merge_frame_threshold, dist_threshold )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% dist_threshold as defined by Tao in SMT:
% divides both the x,y coordinate and the max distance into 20 nm blocks

% Find start and ending frames (column 6 and 7)
% Indices in first_last_frames are the trajectory indices in finalTraj
first_last_frames=zeros(length(finalTraj),2);
for a=1:length(finalTraj)
    first_last_frames(a,:)=[finalTraj{a}(1,6),finalTraj{a}(1,7)];
end

% Find trajectories with the frame threshold
% Calculate the distance between first and last frames for all pairs of trajectories
frameDist = pdist2(first_last_frames(:,2),first_last_frames(:,1));

% Set the diagonal to 0 (last - first same trajectory, trajectory length)
for i=1:length(frameDist)
    frameDist(i,i)=0;
end

% traj_i_last: indices of the trajectories with the last frame within the 
% frame threshold in first_last_frames
% traj_j_start: indices of the trajectories with the first frame within the
% frame threshold in the first_last_frames matrix
% new trajectory should be in the following order: traj_i_last + traj_j_start
[traj_i_last, traj_j_start] = find(frameDist > 0 & frameDist <= merge_frame_threshold);

% Last frame must come before the start frame!
% The start frame of the 2nd trajectory must come after the last frame of
% the 1st trajectory (if last frame i, then start is i+2)
mask=(first_last_frames(traj_j_start,1)-first_last_frames(traj_i_last,2))>0;
traj_i_last=traj_i_last(mask);
traj_j_start=traj_j_start(mask);

% mergedTraj is the finalTraj indices
mergedTraj = [];
% Check their distance, which should depend on the number of frames skipped!
for b=1:length(traj_i_last)
    % Modify dist_threshold depending on the frame number skipped
    new_dist_threshold=dist_threshold*(first_last_frames(traj_j_start(b),1)-first_last_frames(traj_i_last(b),2));
    if pdist2(finalTraj{traj_i_last(b)}(end,1:2),finalTraj{traj_j_start(b)}(1,1:2)) < new_dist_threshold
        mergedTraj(end+1,:) = [traj_i_last(b), traj_j_start(b)];
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
    mergedTraj(index,:)=[];
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
    mergedTraj(index,:)=[];
end

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

