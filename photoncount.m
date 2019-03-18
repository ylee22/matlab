function [ photons, edgesx, edgesy, entireframe ] = photoncount( dirpath, tifname, rmsthreshold, edges )
% tifname includes the full path
% count the total number of photons for each particle
cd(dirpath)

% load the image
info = imfinfo(tifname);
frames = numel(info);
photons = [];
entireframe = [];

% select region of interest
if isempty(edges)
    % select the region of interest first (get rid of gold)
    % select region to exclude gold
    img = imread(tifname, 1);
    image(img)

    waitforbuttonpress
    [edgesx, edgesy] = getline;
else
    edgesx = edges(:,1);
    edgesy = edges(:,2);
end

close

for f = 1:frames
    disp(f)
    
    img = imread(tifname, f);
    img = double(img);
    entireframe = [entireframe, reshape(img,1,size(img,1)*size(img,2))];

    % find particles first
    % default settings from wfiread
	sig_min = 0.5;
	sig_max = 1.7;
    
    startx = 1;
    starty = 1;
    % reject particles based on rms threshold here
    % factor = rms setting in wfiread
    [~, centers, ~, ~, fit_boxes] = fp_nms(img, rmsthreshold, sig_min, sig_max, startx, starty);

    % apply mask here
    % can't apply mask before particle finding step, because then it makes
    % the background artifically low (0s from the mask) and results in
    % tons of false positive particles
    % 4. select the coordinates that are inside
    centers = centers';
    in = inpolygon(centers(:, 1), centers(:, 2), edgesx, edgesy);
    inboxes = fit_boxes(:, :, in);

    for i = 1:sum(in)
        particle = inboxes(:, :, i);
        % count the photons for the pixels contributing to the particle
        photons(end+1) = sum(sum(particle));
    end

end

