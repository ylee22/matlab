% Select trajectories with some minimum length
function filteredTraj = filterTraj(allTraj, minAnchoredTraj)
    filteredTraj = cell(1,length(allTraj));
    counter = 0;
    
    for m = 1:length(allTraj)
        if length(allTraj{m}) >= minAnchoredTraj
            counter = counter + 1;
            filteredTraj{counter} = allTraj{m};
        end
    end

    % Remove empty cells
    if counter < length(allTraj)
        filteredTraj = filteredTraj(1:counter);
    end
end

