hist(SS_all_anchor_sizes,100)
h = findobj(gca,'Type','patch');
hold on;

hist(EGF_5min_all_anchor_sizes,100)
h1 = findobj(gca,'Type','patch');
hold on;

hist(EGF_past_5min_all_anchor_sizes,100);
h2 = findobj(gca,'Type','patch');
hold on;

hist(RKW_all_anchor_sizes,100)
h3 = findobj(gca,'Type','patch');

set(h3,'FaceColor','b','EdgeColor','b','facealpha',0.5)
set(h2,'FaceColor','g','EdgeColor','g','facealpha',0.5)
set(h1,'FaceColor','r','EdgeColor','r','facealpha',0.5)
set(h,'FaceColor','k','EdgeColor','k','facealpha',1)
xlabel('Anchor Radius (nm)')
ylabel('Number of Anchors')

% where stuff is the two vectors of unequal lengths, stuff = [stuff1,
% stuff2], basically find the min and max of all of your values
xbin = linspace(min(stuff), max(stuff), spacing);
y1 = hist(stuff1, xbin);
y2 = hist(stuff2, xbin);
bar(xbin, [y1;y2]', 1)

%% example:
% xbin=linspace(3,54,50);
% y1=hist(rkd_duration,xbin);
% y2=hist(rkw_duration,xbin);
% bar(xbin,[y1;y2]',1)