function [totalCost,electricityGenerationCost,gasPurchasingCost,upDownCost,exportProfit,reserveCost] = ...
    obj_operatingCost_schedule(Pg,Pic,PGs,Qptg,Qd_export,windReserve,I_up,I_down, mpc, NK, iOnOffGen, iCoal)
% unit: $/hour
Pg = mpc.baseMVA*Pg;
windReserve = mpc.baseMVA*windReserve;
%
% mpc.Gcost = 0;
% electricityGenerationCost = sum(sum(Pg.^2 .* repmat(mpc.gencost(:,5)',[NK,1]) + Pg .* repmat(mpc.gencost(:,6)',[NK,1]) ));
electricityGenerationCost = sum(sum(Pg .* repmat(mpc.gencost(:,6)',[NK,1]) ));
upDownCost = sum(sum(I_up .* repmat(mpc.gencost(iOnOffGen,2)',[NK,1]))) + sum(sum(I_down .* repmat(mpc.gencost(iOnOffGen,2)',[NK,1])));
gasPurchasingCost = sum(sum(PGs * mpc.Gcost));
% subsidy of hydrogen and methane productions
% totalCost = totalCost- 0.1/6*1e6*sum(sum(Qptg));  % original
% PTGsubsidy = sum(sum(Qptg))  *1e6/24 * 0.089 * 2.2/ 6.7;  
% upDownCost = 0;
interconnectorCost = mean(mpc.gencost(iCoal,6)) * sum(Pic);
exportProfit = sum(sum(Qd_export)) *1e6/24 * 0.089 * 2.2/5;
reserveCost = sum(windReserve) * 70 * 2;
%%
totalCost = electricityGenerationCost + gasPurchasingCost + upDownCost + interconnectorCost - exportProfit + reserveCost;
% totalCost = electricityGenerationCost;
end