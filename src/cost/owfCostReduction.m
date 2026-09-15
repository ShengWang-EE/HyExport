function [LCOEcurve2030,LCOHcurve2030,LCOAcurve2030,LCOEcurve2030_accumulated,LCOHcurve2030_accumulated,LCOAcurve2030_accumulated, ...
    LCOEcurve2040,LCOHcurve2040,LCOAcurve2040,LCOEcurve2040_accumulated,LCOHcurve2040_accumulated,LCOAcurve2040_accumulated, ...
    LCOEcurve2050,LCOHcurve2050,LCOAcurve2050,LCOEcurve2050_accumulated,LCOHcurve2050_accumulated,LCOAcurve2050_accumulated] = ...
    owfCostReduction(LCOEcurve,reductionRate,nCountry,waterDepthArrayE,yearSupply)


% H/A grids already combine annual equipment prices with wind-only learning.
% Apply the aggregate wind cost reduction here only to the electricity curves.
for ic = 1:nCountry
    fixedIndexE = waterDepthArrayE{ic}<=60; floatingIndexE = waterDepthArrayE{ic}>60;
    % 2030
    factor2030E = (1-reductionRate(2,1)) * fixedIndexE + (1-reductionRate(2,2)) * floatingIndexE;

    LCOEcurve2030{ic}(:,1) = LCOEcurve{ic}(:,1);
    LCOEcurve2030{ic}(:,2) = LCOEcurve{ic}(:,2) .* factor2030E;
    LCOHcurve2030{ic}(:,1) = yearSupply.H{1,ic}(:,1);
    LCOHcurve2030{ic}(:,2) = yearSupply.H{1,ic}(:,2);
    LCOAcurve2030{ic}(:,1) = yearSupply.A{1,ic}(:,1);
    LCOAcurve2030{ic}(:,2) = yearSupply.A{1,ic}(:,2);

    LCOEcurve2030{ic}(:,2) = sort(LCOEcurve2030{ic}(:,2));
    LCOHcurve2030{ic}(:,2) = sort(LCOHcurve2030{ic}(:,2));
    LCOAcurve2030{ic}(:,2) = sort(LCOAcurve2030{ic}(:,2));    

    LCOEcurve2030_accumulated{ic} = accumulateCostCurve(LCOEcurve2030{ic});
    LCOHcurve2030_accumulated{ic} = accumulateCostCurve(LCOHcurve2030{ic});
    LCOAcurve2030_accumulated{ic} = accumulateCostCurve(LCOAcurve2030{ic});
    % 2040
    factor2040E = (1-reductionRate(3,1)) * fixedIndexE + (1-reductionRate(3,2)) * floatingIndexE;

    LCOEcurve2040{ic}(:,1) = LCOEcurve{ic}(:,1);
    LCOEcurve2040{ic}(:,2) = LCOEcurve{ic}(:,2) .* factor2040E;
    LCOHcurve2040{ic}(:,1) = yearSupply.H{2,ic}(:,1);
    LCOHcurve2040{ic}(:,2) = yearSupply.H{2,ic}(:,2);
    LCOAcurve2040{ic}(:,1) = yearSupply.A{2,ic}(:,1);
    LCOAcurve2040{ic}(:,2) = yearSupply.A{2,ic}(:,2);

    LCOEcurve2040{ic}(:,2) = sort(LCOEcurve2040{ic}(:,2));
    LCOHcurve2040{ic}(:,2) = sort(LCOHcurve2040{ic}(:,2));
    LCOAcurve2040{ic}(:,2) = sort(LCOAcurve2040{ic}(:,2)); 

    LCOEcurve2040_accumulated{ic} = accumulateCostCurve(LCOEcurve2040{ic});
    LCOHcurve2040_accumulated{ic} = accumulateCostCurve(LCOHcurve2040{ic});
    LCOAcurve2040_accumulated{ic} = accumulateCostCurve(LCOAcurve2040{ic});
    % 2050
    factor2050E = (1-reductionRate(4,1)) * fixedIndexE + (1-reductionRate(4,2)) * floatingIndexE;

    LCOEcurve2050{ic}(:,1) = LCOEcurve{ic}(:,1);
    LCOEcurve2050{ic}(:,2) = LCOEcurve{ic}(:,2) .* factor2050E;
    LCOHcurve2050{ic}(:,1) = yearSupply.H{3,ic}(:,1);
    LCOHcurve2050{ic}(:,2) = yearSupply.H{3,ic}(:,2);
    LCOAcurve2050{ic}(:,1) = yearSupply.A{3,ic}(:,1);
    LCOAcurve2050{ic}(:,2) = yearSupply.A{3,ic}(:,2);

    LCOEcurve2050{ic}(:,2) = sort(LCOEcurve2050{ic}(:,2));
    LCOHcurve2050{ic}(:,2) = sort(LCOHcurve2050{ic}(:,2));
    LCOAcurve2050{ic}(:,2) = sort(LCOAcurve2050{ic}(:,2)); 

    LCOEcurve2050_accumulated{ic} = accumulateCostCurve(LCOEcurve2050{ic});
    LCOHcurve2050_accumulated{ic} = accumulateCostCurve(LCOHcurve2050{ic});
    LCOAcurve2050_accumulated{ic} = accumulateCostCurve(LCOAcurve2050{ic});
end
end

function accumulatedCurve = accumulateCostCurve(costCurve)
accumulatedCurve = [0,0; [costCurve(2:end,1), cumsum(diff(costCurve(:,1)) .* costCurve(1:end-1,2))]];
end
