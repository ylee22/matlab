function [ ci095 ] = calculate095ci( dataset )
% data: cell array with each element a different dataset

ci095 = zeros(numel(dataset), size(dataset{1},2));
for i=1:numel(dataset)
    data = dataset{i};
    df = size(data, 1) - 1;
    ts = tinv([0.025  0.975], df);      % T-Score, 95%
    ci095(i, :) = ts(2)*std(data)/sqrt(size(data, 1));
end


end

