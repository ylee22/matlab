all_finalTrajmin5 = who('finalTrajmin5*');
all_lt100_trajs = who('lt100_trajs*');
all_lt100_anchor_coords = who('lt100_anchor_coords*');
anchored_frames = [];

for movie_index=1:length(all_finalTrajmin5)
    % Clear variables, just in case
    clearvars current_finalTrajmin5 current_lt100_trajs current_100_anchor_coords
    
    current_finalTrajmin5 = eval(all_finalTrajmin5{movie_index});
    current_lt100_trajs = eval(all_lt100_trajs{movie_index});
    current_lt100_anchor_coords = eval(all_lt100_anchor_coords{movie_index});
    
    % Find number of frames stuck in anchor
    temp_frames = framesInAnchor(current_lt100_trajs, current_lt100_anchor_coords, current_finalTrajmin5, movie_index);
    % [first frame in anchor, last frame in anchor, trajectory ID (finalTrajmin5 row), anchor ID, movie ID]
    anchored_frames = [anchored_frames ; temp_frames];
end