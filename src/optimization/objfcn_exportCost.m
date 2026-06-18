function [totalCost,costComposition] = objfcn_exportCost(Q_hyspl,...
    Q_amspl,Q_hy_im,Q_am_im,n_hyship,n_amship,LCOHcurve_accumulated,LCOAcurve_accumulated,nCountry,costOptions)
if nargin < 10
    costOptions.importCostMode = "penalty";
    costOptions.importPenalty_EURperMW = 1e9;
end

for ic = 1:nCountry
    hyProductionCostPerCountry(ic) = interp1(LCOHcurve_accumulated{ic}(:,1),LCOHcurve_accumulated{ic}(:,2),Q_hyspl(ic),'sos2');
    amProductionCost_up(ic) = interp1(LCOAcurve_accumulated{ic}(:,1),LCOAcurve_accumulated{ic}(:,2),(Q_hyspl(ic)+Q_amspl(ic)),'sos2');
    amProductionCost_down(ic) = interp1(LCOAcurve_accumulated{ic}(:,1),LCOAcurve_accumulated{ic}(:,2),Q_hyspl(ic),'sos2');
    amProductionCostPerCountry(ic) = amProductionCost_up(ic) - amProductionCost_down(ic);
end
hyProductionCost = sum(hyProductionCostPerCountry) * 8760;
amProductionCost = sum(amProductionCostPerCountry) * 8760;

C_hyshipcap = 398 * 1e6; C_amshipcap = 52 * 1e6; % investment cost
C_hyshipom = 0.04 * C_hyshipcap; C_amshipom = 0.04 * C_amshipcap; % maintainess cost per year
discountRate = 0.06;
lifetime = 25;

hyTransportationCostPerline = n_hyship * (C_hyshipcap / sum((1+discountRate).^(0:lifetime-1)) + C_hyshipom);
amTransportationCostPerline = n_amship * (C_amshipcap / sum((1+discountRate).^(0:lifetime-1)) + C_amshipom);
hyTransportationCost = sum(sum(hyTransportationCostPerline));
amTransportationCost = sum(sum(amTransportationCostPerline));
transportationCostPerline = hyTransportationCostPerline + amTransportationCostPerline;
%% international import
% 默认模式保留原模型逻辑：国际进口是一个很大的惩罚项，只在欧洲供给不足时启用。
% price 模式用于论文 robustness：把国际进口当成一个可竞争的外部低碳氢/氨选项。
if string(costOptions.importCostMode) == "price"
    costImport = (sum(Q_hy_im) * costOptions.hyImportCost_EURperMWh ...
        + sum(Q_am_im) * costOptions.amImportCost_EURperMWh) * 8760;
else
    costImport = (sum(Q_hy_im) + sum(Q_am_im)) * costOptions.importPenalty_EURperMW;
end
%% cost
totalCost = hyProductionCost + amProductionCost + hyTransportationCost + amTransportationCost + costImport;
% totalCost = hyProductionCost + amProductionCost;

costComposition.hyProductionCostPerCountry = hyProductionCostPerCountry;
costComposition.amProductionCostPerCountry = amProductionCostPerCountry;
costComposition.hyTransportationCostPerline = hyTransportationCostPerline;
costComposition.amTransportationCostPerline = amTransportationCostPerline;
costComposition.hyProductionCost = hyProductionCost;
costComposition.amProductionCost = amProductionCost;
costComposition.hyTransportationCost = hyTransportationCost;
costComposition.amProductionCost_up = amProductionCost_up;
costComposition.amProductionCost_down = amProductionCost_down;
costComposition.amTransportationCost = amTransportationCost;
costComposition.importCost = costImport;
costComposition.importCostMode = costOptions.importCostMode;


end
