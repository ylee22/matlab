function bar_with_error( x, y )
% plots god damn bar graphs

figure
b = bar(x');
hold on

for i = 1:size(x, 2)
    for j = 1:size(y, 1)
        errorbar(i+b(j).XOffset,x(j,i),y(j,i),'k')
    end
end

end

