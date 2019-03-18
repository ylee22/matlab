function finalTraj = SMT2D(coords,maxdist)
% everything is in um, maxdist needs to be in um!!!

numframes = coords(end,1);

FinalTraj = cell(0,0);
CurrFrameCoords = [];

% Find coordinates in frame 1
fn1 = find(coords(:,1) > 1,1);
PrevFrameCoords = coords(1:fn1-1,1:3);

ActiveTraj = cell(0,0);

for k = 1:size(PrevFrameCoords,1)
    ActiveTraj = [ActiveTraj;PrevFrameCoords(k,:)];
end

for frame = 2:numframes% - 1
    
    fn2 = find(coords(fn1:end,1) > frame,1) + fn1 - 1;
    
    if fn2 == fn1
        removeindex = [];
        for k = 1:size(ActiveTraj,1)
            siz = size(ActiveTraj{k},1);
            if siz == 1
                removeindex = [removeindex;k];
            end
        end
        ActiveTraj(removeindex) = [];
        FinalTraj = [FinalTraj;ActiveTraj];
        ActiveTraj = cell(0,0);
        continue
    end
    
    CurrFrameCoords = coords(fn1:fn2-1,1:3);
    fn1 = fn2;
    
    CurrIndex = [];
    PrevIndex = [];
    
    for k = 1:size(PrevFrameCoords,1)
        dist = sqrt((CurrFrameCoords(:,2) - PrevFrameCoords(k,2)).^2 + (CurrFrameCoords(:,3) - PrevFrameCoords(k,3)).^2);
        
        fn_dist = find(dist <= maxdist);
        
        if size(fn_dist,1) == 1
            CurrIndex = [CurrIndex;fn_dist];
            PrevIndex = [PrevIndex;k];
        end
        
    end
    
    % Find and remove repeated CurrIndex values
    [currsort,sortind] = sort(CurrIndex);
    fn = find(diff(currsort) == 0);
    CurrIndex([sortind(fn) sortind(fn+1)]) = [];
    PrevIndex([sortind(fn) sortind(fn+1)]) = [];
    
    ActiveTrajTemp = cell(size(CurrFrameCoords,1),1);
    for k = 1:size(CurrFrameCoords,1)
        ActiveTrajTemp{k} = CurrFrameCoords(k,:);
    end

    if ~isempty(ActiveTraj)
        for k = 1:size(CurrIndex,1)
            ActiveTrajTemp{CurrIndex(k)} = [ActiveTraj{PrevIndex(k)};ActiveTrajTemp{CurrIndex(k)}];
        end

        ActiveTraj(PrevIndex) = [];

        removeindex = [];
    
        for k = 1:numel(ActiveTraj)
            siz = size(ActiveTraj{k},1);
            if siz == 1
                removeindex = [removeindex;k];
            end
        end
        ActiveTraj(removeindex) = [];

        FinalTraj = [FinalTraj;ActiveTraj];
    end
    
    ActiveTraj = ActiveTrajTemp;
    
    PrevFrameCoords = CurrFrameCoords;
    
    if mod(frame,1000) == 0
        frame
    end
    
end

finalTraj = FinalTraj;

for m = 1:size(FinalTraj,1)

    temp = finalTraj{m}(:,2:3);
    temp = [temp,finalTraj{m}(:,1)];
    
    finalTraj{m} = temp;
    
end

finalTraj = finalTraj';
end