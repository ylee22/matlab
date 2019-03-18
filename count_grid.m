function [ counts, frames ] = count_grid( coords, pix, minx, miny )
% coords: for a given state coordinates with 1: x, 2: y, 3: frame #
% pix: resolution of the grid
% minx: minimum x coordinate in the entire traj map
% miny: minimum y coordinate in the entire traj map

% convert coords to grid coordinates
coords(:,1) = ceil((coords(:,1) - minx)/pix);
coords(:,2) = ceil((coords(:,2) - miny)/pix);

% mins should get mapped to 1, not 0
coords(coords==0)=1;

% count using sparse matrix
sp_counts = sparse(coords(:,1), coords(:,2), ones(size(coords(:,1))));

% I want 1: x, 2: y, 3: # events and frames corresponding to each row
[r, c] = find(sp_counts);
counts = zeros(numel(r), 3);
counts(:,1:2) = [r, c];
frames = cell(1, numel(r));
for i=1:numel(r)
    counts(i, 3) = sp_counts(r(i), c(i));
    % corresponding frames
    idx = coords(:,1)==r(i) & coords(:,2)==c(i);
    frames{i} = coords(idx, 3);
end

end

