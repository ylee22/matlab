% Remove duplicate rows of overlapping trajectories
% This function replaces duplicate rows with empty matrices
% setdiff IS TAKING UP LITERALLY ALL OF THE TIME!!!
function array_with_duplicate_rows = removeDuplicateRows(array_with_duplicate_rows)
    for i=1:length(array_with_duplicate_rows)
        current_row = array_with_duplicate_rows{i};
        for j=2:length(current_row)
            % duplicateRows are the output from rangesearch using kdtrees
            % Since it holds row indices for each vector, row indices
            % should all be unique, no need to check for duplicates before
            % comparing length
            % If two rows are identical, they should have the same length
            duplicate_row = array_with_duplicate_rows{current_row(j)};
            if numel(current_row) == numel(duplicate_row)
                % Check here to see if the two rows have identical elements
                if isequal(sort(current_row), sort(duplicate_row))
                    % Delete the second duplicated row
                    array_with_duplicate_rows{current_row(j)}=[];
                end
            end
        end
    end
end
