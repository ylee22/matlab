function [ seg_den ] = cross_pair_correlation( points1, points2, dr, maxr, total_area )
% calculates pair_correlation from 0 to maxr for every dr segment
% for every points1, calculate positions of points2

% make a kd tree of the points to be searched
kdtree = KDTreeSearcher(points2);

% average density later to be used to calculate the expected density
avg_den = size(points2, 1)/total_area;

% use range search for each r to get all points within a certain radius
search = 0:dr:maxr;

% keep track of the normalized density for each segment
seg_den = zeros(1, numel(search) - 1);

for r = 2:numel(search)
    r1 = search(r-1);
    r2 = search(r);
    
    % for each origin, find distance > r1 and distance < r2
    [~, dist] = rangesearch(kdtree, points1, r2);
    % for each point, i is the sum of the counts in that segment
    i = cellfun(@(x) sum(x>r1), dist, 'UniformOutput', false);
    
    % count all of them first and keep track of the total area summed
    seg_count = sum(cell2mat(i));
    seg_area = (pi*r2^2 - pi*r1^2)*numel(i);
    
    % caculate the density and normalize by the expected density
    seg_den(r - 1) = seg_count/(seg_area*avg_den);
    
    
   % NEED TO IMPLEMENT EDGE CORRECTION THAT'S WHY IT GOES BELOW 1
end


end

