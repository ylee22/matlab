% Select trajectories with some minimum length
function filteredTraj = filterTraj(allTraj, minAnchoredTraj)
    filteredTraj={};
    for m=1:length(allTraj)
        if length(allTraj{m})>=minAnchoredTraj
            filteredTraj{end+1}=allTraj{m};
        end
    end
end

