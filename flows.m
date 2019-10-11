function [ pairratio, flowratio, netflow, flowperarm, flowperstate ] = flows( transcell, occmat )
% s1 and s2: p12 and p21
% s2 and s3: p23 and p32
% s1 and s3: p13 and p31

ratio12 = [];
ratio23 = [];
ratio31 = [];
f1 = [];
f2 = [];
f3 = [];
nf1 = [];
nf2 = [];
nf3 = [];
f21 = [];
f32 = [];
f13 = [];
s1 = zeros(numel(transcell), 3);
for i = 1:numel(transcell)
    % ratios of flows
    ratio12(end+1) = (transcell{i}(1,2)*occmat(i,1))/(transcell{i}(2,1)*occmat(i,2));
    ratio23(end+1) = (transcell{i}(2,3)*occmat(i,2))/(transcell{i}(3,2)*occmat(i,3));
    ratio31(end+1) = (transcell{i}(3,1)*occmat(i,3))/(transcell{i}(1,3)*occmat(i,1));
    % ratio of flow in vs flow out
    f1(end+1) = (transcell{i}(2,1)*occmat(i,2) + transcell{i}(3,1)*occmat(i,3))/((transcell{i}(1,2) + transcell{i}(1,3))*occmat(i,1));
    f2(end+1) = (transcell{i}(1,2)*occmat(i,1) + transcell{i}(3,2)*occmat(i,3))/((transcell{i}(2,1) + transcell{i}(2,3))*occmat(i,2));
    f3(end+1) = (transcell{i}(1,3)*occmat(i,1) + transcell{i}(2,3)*occmat(i,2))/((transcell{i}(3,1) + transcell{i}(3,2))*occmat(i,3));
    % absolute value of net flow
    nf1(end+1) = (transcell{i}(2,1)*occmat(i,2) + transcell{i}(3,1)*occmat(i,3)) - ((transcell{i}(1,2) + transcell{i}(1,3))*occmat(i,1));
    nf2(end+1) = (transcell{i}(1,2)*occmat(i,1) + transcell{i}(3,2)*occmat(i,3)) - ((transcell{i}(2,1) + transcell{i}(2,3))*occmat(i,2));
    nf3(end+1) = (transcell{i}(1,3)*occmat(i,1) + transcell{i}(2,3)*occmat(i,2)) - ((transcell{i}(3,1) + transcell{i}(3,2))*occmat(i,3));
    % flow for each arm (clockwise)
    f21(end+1) = (transcell{i}(2,1)*occmat(i,2)) - (transcell{i}(1,2)*occmat(i,1));
    f32(end+1) = (transcell{i}(3,2)*occmat(i,3)) - (transcell{i}(2,3)*occmat(i,2));
    f13(end+1) = (transcell{i}(1,3)*occmat(i,1)) - (transcell{i}(3,1)*occmat(i,3));
    % flow for each state for each direction
    s1(i,:) = [transcell{i}(1,1)*occmat(i,1), transcell{i}(1,2)*occmat(i,1), transcell{i}(1,3)*occmat(i,1)];
    s2(i,:) = [transcell{i}(2,1)*occmat(i,2), transcell{i}(2,2)*occmat(i,2), transcell{i}(2,3)*occmat(i,2)];
    s3(i,:) = [transcell{i}(3,1)*occmat(i,3), transcell{i}(3,2)*occmat(i,3), transcell{i}(3,3)*occmat(i,3)];
end

pairratio = [ratio12;ratio23;ratio31]';
flowratio = [f1;f2;f3]';
netflow = [nf1;nf2;nf3]';
flowperarm = [f32;f21;f13]';
flowperstate = {s1, s2, s3};
end

