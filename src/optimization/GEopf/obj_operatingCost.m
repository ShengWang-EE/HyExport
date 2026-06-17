function [f,totalCost,electricityGenerationCost,gasPurchasingCost,PTGsubsidy] = ...
    obj_operatingCost(Pg,PGs,Qptg, mpc)
% unit: $/hour
Pg = mpc.baseMVA*Pg;
%
mpc.Gcost = 0;
electricityGenerationCost = sum(sum(Pg.^2 .* mpc.gencost(:,5)) + Pg .* mpc.gencost(:,6) + mpc.gencost(:,5));
gasPurchasingCost = sum(sum(PGs * mpc.Gcost));
% subsidy of hydrogen and methane productions
% totalCost = totalCost- 0.1/6*1e6*sum(sum(Qptg));  % original
PTGsubsidy = sum(sum(Qptg))  *1e6/24 * 0.089 * 2.2/ 6.7;  


%%
totalCost = electricityGenerationCost + gasPurchasingCost - 0*PTGsubsidy;
f  = electricityGenerationCost + gasPurchasingCost - 0*PTGsubsidy;
end