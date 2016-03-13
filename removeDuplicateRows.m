% Remove duplicate rows of overlapping trajectories
% This function replaces duplicate rows with empty matrices
function duplicateRows = removeDuplicateRows(duplicateRows)
    for i=1:length(duplicateRows)
        for j=2:length(duplicateRows{i})
            if isempty(setdiff(duplicateRows{i},duplicateRows{duplicateRows{i}(j)})) && isempty(setdiff(duplicateRows{duplicateRows{i}(j)},duplicateRows{i}))
                duplicateRows{duplicateRows{i}(j)}=[];
            end
        end
    end
end
