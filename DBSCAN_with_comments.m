%
% Copyright (c) 2015, Yarpiz (www.yarpiz.com)
% All rights reserved. Please read the "license.txt" for license terms.
%
% Project Code: YPML110
% Project Title: Implementation of DBSCAN Clustering in MATLAB
% Publisher: Yarpiz (www.yarpiz.com)
% 
% Developer: S. Mostapha Kalami Heris (Member of Yarpiz Team)
% 
% Contact Info: sm.kalami@gmail.com, info@yarpiz.com
%


% Do a better job commenting Yarpiz, I had to add all the comments in
% Also, use descriptive variable names and explain your god damn functions
% Function inputs:
% X: points to be clustered (your data)
% epsilon: minimum distance (radius) from each point to define a core point
% MinPts: minimum number of points to be found within epsilon radius to be
% considered a core point
% Function outputs:
% IDX: n by 1 matrix (each row corresponds to points in X) with cluster IDs
% for each point or 0 for noise
% isnoise: a n by 1 matrix with value 1 if the point is a noise, 0 if the
% point belons to a cluster
function [IDX, isnoise]=DBSCAN_with_comments(X,epsilon,MinPts)

    % C is a cluster counter, use to give unique cluster IDs (separate
    % points into different clusters)
    C=0;
    
    n=size(X,1);
    IDX=zeros(n,1);
    
    % Distance matrix, point to point distance for all points in X
    D=pdist2(X,X);
    
    visited=false(n,1);
    isnoise=false(n,1);
    
    % Loop through each point in X, i is the current point
    for i=1:n
        % If this point hasn't been visited before, mark it as visited
        if ~visited(i)
            visited(i)=true;
            
            Neighbors=RegionQuery(i);
            % If the number of neighbors is less than the minimum points,
            % then mark this point as noise
            if numel(Neighbors)<MinPts
                % X(i,:) is NOISE
                isnoise(i)=true;
            % Otherwise, mark it as a new cluster
            else
                % New cluster ID
                C=C+1;
                ExpandCluster(i,Neighbors,C);
            end
            
        end
    
    end
    
    function ExpandCluster(i,Neighbors,C)
        % Mark the current point as belonging to cluster ID C
        IDX(i)=C;
        
        % Loop through each of the neighboring points
        k = 1;
        while true
            % Neighbors is a list of all the indices of points in epsilon
            % distance of current point i
            j = Neighbors(k);
            
            % For each neighboring point, if it hasn't been visited, mark
            % it as visited and find its neighboring points
            if ~visited(j)
                visited(j)=true;
                Neighbors2=RegionQuery(j);
                % If this neighboring point is also a core point, then add
                % its neighbors to the Neighbors list (adding it to the
                % loop)
                if numel(Neighbors2)>=MinPts
                    Neighbors=[Neighbors Neighbors2];   %#ok
                end
            end
            % Add the neighboring point to the cluster (same cluster as the
            % current point), a non-core neighboring point is added to the
            % cluster as well
            if IDX(j)==0
                IDX(j)=C;
            end
            
            % Break loop when all of the points in the Neighbors list have
            % been scanned
            k = k + 1;
            if k > numel(Neighbors)
                break;
            end
        end
    end
    
    function Neighbors=RegionQuery(i)
        % Searches for all of the neighboring points within epsilon,
        % returns indices
        Neighbors=find(D(i,:)<=epsilon);
    end

end



