function [ idx, clusters ] = find_clusters( cor_file, min_points, eps )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

clear;clc

load(cor_file,'-mat','coords')

coords = coords(2:end, 2:3);

% find particles with neighbors in eps nm distance with minimum of 2 core
% points
[idx, ~] = DBSCAN(coords, eps, min_points);

% for each cluster, find size and number of particles
clusters = zeros(max(idx), 5);
for i = 1:max(idx)
    radius = max(pdist2(mean(coords(idx == i, :)), coords(idx == i, :)));
    % [the cluster id, the number of points in each cluster, radius, x coord, y coord]
    clusters(i, :) = [i sum(idx == i) radius mean(coords(idx == i, :))];
end

% plot the individual points in clusters (each cluster is a different color)
for i = 1:max(idx)
    color = rand(1, 3);
    scatter(coords(idx==i, 1), coords(idx==i, 2), 'MarkerEdgeColor', color)
    hold on
end

% plot the x, y, radius of the clusters
ang = 0:0.1:2*pi;
for i = 1:size(clusters,1)
    radius = clusters(i, 3);
    xp = radius*cos(ang);
    yp = radius*sin(ang);
    plot(clusters(i, 4) + xp, clusters(i, 5) + yp)
end

axis equal

end

