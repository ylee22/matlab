function [ incoords, cell_area, edges ] = select_coords( coords, nm_per_pixel, f )
% returns coordinates from selected polygon region in pixels

% 1. get rid of the header
coords = coords(2:end, :);

% 2. convert to nm from pixels
coords(:, 2:3) = coords(:, 2:3)*nm_per_pixel;

scatter(coords(:, 2), coords(:, 3), '.')

waitforbuttonpress

% 3. select region of interest
[edgesx, edgesy] = getline;
cell_area = polyarea(edgesx, edgesy)/10^6;

% 4. select the coordinates that are inside
in = inpolygon(coords(:, 2),coords(:, 3), edgesx, edgesy);
% only care about column 1: frame number, column 2: x, column 3: y
incoords = coords(in, 1:3);

edges = [edgesx, edgesy];

% 5. replot to make sure it worked
h = scatter(incoords(:, 2), incoords(:, 3), '.');
title({f, size(incoords, 1)})

waitfor(h)

end

