function [ eq_occ ] = transition_error_equilibrium_occ( dir_path, runinput, cell_area, particles, dt, occrange )
% what are the ranges of x, y, z?
% theoretical occupancies calculated in eq_s1_occ

width = sqrt(cell_area);

[ diff_mean, ~, occupancy, ~, posterior_mean, ~, ~, bootstrap_std ] = get_vbSPT_results( dir_path, runinput, 0 );

cd /home/yerim/data/code/
% the mean
[ ~, ~, s1 ] = markov2dsim( diff_mean, occupancy, posterior_mean, particles, dt, 500*dt, width );

eq_occ = [sum(s1==1); sum(s1==2); sum(s1==3)]/particles;
eq_occ = [occupancy', eq_occ];

if occrange
    % assume last half of the simulation is at equilibrium
    eq_occ = [mean([mean(s1(:,end-250:end)==1)', mean(s1(:,end-250:end)==2)', mean(s1(:,end-250:end)==3)']), 0, 0];
    
    figure
    c = get(gca, 'colororder');
    plot(1:size(s1,2), sum(s1==1,1)/5000,'color',c(1,:),'LineWidth',3)
    hold on
    plot(1:size(s1,2), sum(s1==2,1)/5000,'color',c(2,:),'LineWidth',3)
    plot(1:size(s1,2), sum(s1==3,1)/5000,'color',c(3,:),'LineWidth',3)

    % for each state i, maximize pii and pji to find the upper bound, minimize
    % pii and pij to find the lower bound

    for lower_upper = [-1 1]
        for j = 1:numel(diff_mean)
            for i = 1:numel(diff_mean)
                % p11, p21, p31
                % p12, p22, p32
                % p13, p23, p33
                % try 2*std dev and lower it if you get negative probabilities
                tpmean = posterior_mean;
                s = setdiff(1:3, j);
                r = bootstrap_std(i, s(1))/(bootstrap_std(i, s(1)) + bootstrap_std(i, s(2)));
                err = 2*bootstrap_std(i, j)*lower_upper;

                % 2 conditions: 1. sum(pij)=1, 2. no negative values
                tpmean(i, j) = tpmean(i, j) + err;
                tpmean(i, s(1)) = tpmean(i, s(1)) - err*r;
                tpmean(i, s(2)) = tpmean(i, s(2)) - err*(1-r);

                if tpmean(i, s(1)) < 0 && tpmean(i, s(2)) < 0 && (posterior_mean(i, s(1)) - err) < 0 && (posterior_mean(i, s(2)) - err) < 0
                    err = bootstrap_std(i, j)*lower_upper;
                end

                % check to see if one of the values is negative
                if tpmean(i, s(1)) < 0 && (posterior_mean(i, s(2)) - err) > 0
                    tpmean(i, s(1)) = posterior_mean(i, s(1));
                    tpmean(i, s(2)) = posterior_mean(i, s(2)) - err;
                elseif tpmean(i, s(2)) < 0 && (posterior_mean(i, s(1)) - err) > 0
                    tpmean(i, s(2)) = posterior_mean(i, s(2));
                    tpmean(i, s(1)) = posterior_mean(i, s(1)) - err;
                end
            end

            [ ~, ~, s2 ] = markov2dsim( diff_mean, occupancy, tpmean, 5000, 0.012, 500*0.012, width );
            eq_occ(end+1,:) = [mean([mean(s2(:,end-250:end)==1)', mean(s2(:,end-250:end)==2)', mean(s2(:,end-250:end)==3)']), lower_upper, j];

            plot(1:size(s2,2), sum(s2==1,1)/5000, 'color', c(j,:))
            plot(1:size(s2,2), sum(s2==2,1)/5000, 'color', c(j,:))
            plot(1:size(s2,2), sum(s2==3,1)/5000, 'color', c(j,:))
        end
    end

    h = findobj(gca,'Type','line');
    legend([h(end),h(end-1),h(end-2),h(end-3),h(end-6),h(end-9)],'slow','intermediate','fast','min/max slow','min/max intermediate','min/max fast')
    ylabel('percent occupancy')
    xlabel('simulation cycle')
    temp = strsplit(dir_path,'/');
    temp2 =  strsplit(runinput,'dox');
    temp2 = strcat('dox ',temp2{end});
    temp2 = erase(temp2,'_runinput.m');
    temp2 = strrep(temp2, '_', ' ');
    title(strjoin({temp{end}, temp2}, ' '))

end

end

