function makeAnchorPlots( first_last_frames_array, anchor_merge_distance )
%UNTITLED8 Summary of this function goes here
%   Detailed explanation goes here
anchor_frame_duration={};
for i=1:length(first_last_frames_array)
    if ~isempty(first_last_frames_array{i})
        anchor_frame_duration{i}=first_last_frames_array{i}(:,2)-first_last_frames_array{i}(:,1);
    end
end

values=[];
group=[];
for i=1:length(anchor_frame_duration)
    if ~isempty(anchor_frame_duration{i})
        values=[values,anchor_frame_duration{i}'];
        group=[group,ones(1,length(anchor_frame_duration{i}))*i];
    end
end
figure
boxplot(values, group*anchor_merge_distance)
xlabel('Anchor Radius in nm')
ylabel('Anchor Duration in Frames, 20 ms Frame Rate')

figure
hist(values,100)
xlabel('Anchor Duration in Frames, 20 ms Frame Rate')
ylabel('Number of Anchors')

% After combining:
figure
hist(first_last_anchor(:,2)-first_last_anchor(:,1),100)
xlabel('Anchor Duration in Frames, 20 ms Frame Rate')
ylabel('Number of Anchors')

figure
hist(combined_anchor_coords(:,1),100)
xlabel('Anchor Radius in nm')
ylabel('Number of Anchors')

end

