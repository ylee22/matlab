
function circle(xandy,r)
figure
%x and y are the coordinates of the center of the circle
%r is the radius of the circle
%0.01 is the angle step, bigger values will draw the circle faster but
%you might notice imperfections (not very smooth)
ang=0:0.01:2*pi; 
xp=r*cos(ang);
yp=r*sin(ang);
for i=1:length(xandy)
    plot(xandy(i,1)+xp,xandy(i,2)+yp);
    hold on;
end
axis image
end