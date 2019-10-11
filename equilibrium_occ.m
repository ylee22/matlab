function [ occupancies ] = equilibrium_occ( ptm )

occupancies = zeros(numel(ptm), 3);

for i=1:numel(ptm)
    % grab transition rates
    k = ptm{i};
    
    syms x y z
    eqn1 = k(1,2)*x - k(2,1)*y == 0;
    eqn2 = k(2,3)*y - k(3,2)*z == 0;
    eqn3 = x + y + z == 1;

    sol = solve([eqn1, eqn2, eqn3], [x, y, z]);
    occupancies(i,1) = double(sol.x);
    occupancies(i,2) = double(sol.y);
    occupancies(i,3) = double(sol.z);
    
    clearvars eqn1 eqn2 eqn3 sol x y z

end

end

