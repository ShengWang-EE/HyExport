function [sol,solutionInfo] = optimalTransportation(EUhydrogenDemand,EUoffshoreCapacity,ferryPortShp_aggregated,...
    portIndexPerCountry,portInCountry,LCOHcurve,LCOAcurve,LCOHcurve_accumulated,LCOAcurve_accumulated,...
    EUoffshoreDomesticConsumption,capacityFactor_mean,nPort,nCountry,year,EUwindConsump_new,costOptions)
% try analytical first
%% parameters
if nargin < 16
    costOptions.importCostMode = "penalty";
    costOptions.importPenalty_EURperMW = 1e9;
end

operationTime = 329 * 24; % all converted to hour
loadUnloadTime = 48;
shipSpeed = 15 * 1.852; % convert knot to km/hour
u2e = 0.93; % usd to euro

hydrogenDensity = 70.8; % liquid hydrogen, from wiki, kg/m3
hydrogenHeatValue = 143; % MJ/kg
Q_shiphymax = 160000 * hydrogenDensity * hydrogenHeatValue / 3600; % convert m3 to MWh
ammoniaDensity = 617; % kg/m3 (liquid)
ammoniaHeatValue = 23; % MJ/kg
Q_shipammax = 38000 * ammoniaDensity * ammoniaHeatValue /3600; % convert to MWh
naturalGasHeatValue = 50; % MJ/kg
shipConsumption = 50 * 1e3 * naturalGasHeatValue / 3600 / 24; % MWh, per ship, per hour
hyLossRate = 0.002 / 24; % percentage, only for hydrogen, per hour
shipCosts = shippingCostParameters(year);
hyShipOperationCost = shipCosts.hyAnnualCost / 8760 / Q_shiphymax;
amShipOperationCost = shipCosts.amAnnualCost / 8760 / Q_shipammax;

% Trade quantities and cost-curve coordinates must both be average hydrogen MW.
for ic = 1:nCountry
    [LCOHcurve{ic}, LCOHcurve_accumulated{ic}] = hydrogenEnergySupplyCurve(LCOHcurve{ic}, capacityFactor_mean(ic), year);
    [LCOAcurve{ic}, LCOAcurve_accumulated{ic}] = hydrogenEnergySupplyCurve(LCOAcurve{ic}, capacityFactor_mean(ic), year);
end

% min and max
% Q_hysplmax = zeros(nCountry,1);
% for ic = 1:nCountry
%     Q_hysplmax(ic,1) = LCOHcurve{ic}(end,1);
% end
% Q_amsupmax = Q_hysplmax * 0.3;

% Demand is annual energy in the input table; trade variables are average MW.
yearIndex = find([2030, 2040, 2050] == str2double(string(year)), 1);
ammoniaColumn = 2 + (yearIndex - 1) * 5;
Q_hydm = sum(table2array(EUhydrogenDemand(:,ammoniaColumn+(1:3))),2) * 1e6 / 8760;
Q_amdm = table2array(EUhydrogenDemand(:,ammoniaColumn)) * 1e6 / 8760;
% Column 3 is residual WIND ELECTRICITY, already net of domestic use/curtailment.
Q_hysplmax = EUwindConsump_new{yearIndex}(:,3) * 1e6 / 8760 * offshoreHydrogenEfficiency(year);
Q_amsupmax = 0.1 * Q_hysplmax; % Existing hydrogen-equivalent ammonia allocation.

% number of shipping line, merge the shipping line between countries as the shortest one
shippingLineMatrix = 1e10*ones(nCountry);
for ip = 1:nPort
    for jp = ip:nPort % ! can ship to its own contry to meet its own demand
        fromCountry = portInCountry(ip); toCountry = portInCountry(jp);
        shiplineLength = deg2km(geoDistance([ferryPortShp_aggregated(ip).X,ferryPortShp_aggregated(ip).Y], ...
            [ferryPortShp_aggregated(jp).X,ferryPortShp_aggregated(jp).Y])) * pi/2;
        [shippingLineMatrix(fromCountry,toCountry),shippingLineMatrix(toCountry,fromCountry)] = ...
            deal(min([shippingLineMatrix(fromCountry,toCountry),shippingLineMatrix(toCountry,fromCountry),shiplineLength]));
    end
end
% organize it into a array
counter = 1;
for ic = 1:nCountry
    for jc = ic:nCountry
        shippingLineArray(counter,[1,2,3]) = [ic,jc,shippingLineMatrix(ic,jc)];
        counter = counter + 1;
    end
end
nShippingLine = size(shippingLineArray,1);

travelTime = shippingLineArray(:,3) / shipSpeed;
%% decision vars
Q_hyspl = sdpvar(nCountry,1);       % hydrogen supply of a country, MWh
Q_amspl = sdpvar(nCountry,1);       % ammonia supply of a country, MWh
% Nonnegative forward/reverse flows let fuel follow the actual exporter.
Q_hyflow = sdpvar(nShippingLine,2,'full');
Q_amflow = sdpvar(nShippingLine,2,'full');
n_hyshipDirection = sdpvar(nShippingLine,2,'full');
n_amshipDirection = sdpvar(nShippingLine,2,'full');
Q_hytrans = Q_hyflow(:,1) - Q_hyflow(:,2);
Q_amtrans = Q_amflow(:,1) - Q_amflow(:,2);
n_hyship = sum(n_hyshipDirection,2);
n_amship = sum(n_amshipDirection,2);
Q_hy_im = sdpvar(nCountry,1); % international import
Q_am_im = sdpvar(nCountry,1);
%% constraints
% 1 supply capacity
supplyCapacityCons = [
    Q_hyspl >= 0;
    Q_hyspl + Q_amspl <= Q_hysplmax; % MW
    Q_amspl >= 0;
    Q_amspl <= Q_amsupmax;
    Q_hy_im >= 0;
    Q_am_im >= 0;
    ];

% 2 country nodal balance
Q_hytranssum = sdpvar(nCountry,1);       % hydrogen flow out from a country
Q_amtranssum = sdpvar(nCountry,1);       % ammonia flow out from a country
Q_hyfuelDirection = (shipConsumption + hyLossRate * Q_shiphymax) * operationTime/8760 * n_hyshipDirection;
Q_amfuelDirection = shipConsumption * operationTime/8760 * n_amshipDirection;
Q_hyship = sum(Q_hyfuelDirection,2);
Q_amship = sum(Q_amfuelDirection,2);
Q_hyshipsum = allocateShippingFuel(shippingLineArray, Q_hyfuelDirection(:,1), Q_hyfuelDirection(:,2), nCountry);
Q_amshipsum = allocateShippingFuel(shippingLineArray, Q_amfuelDirection(:,1), Q_amfuelDirection(:,2), nCountry);
for ic = 1:nCountry
    Q_hytranssum(ic) = sum(Q_hytrans(find(shippingLineArray(:,2)==ic))) ...
        - sum(Q_hytrans(find(shippingLineArray(:,1)==ic)));                    % flow in - flow out
    Q_amtranssum(ic) = sum(Q_amtrans(find(shippingLineArray(:,2)==ic))) ...
        - sum(Q_amtrans(find(shippingLineArray(:,1)==ic)));

end

countryBalanceCons = [
    Q_hyspl + Q_hytranssum - Q_hyshipsum - Q_hydm + Q_hy_im == 0;
    Q_amspl + Q_amtranssum - Q_amshipsum - Q_amdm + Q_am_im== 0;
    ];

% 3 transportation capacity constraints
n_trip = operationTime ./ (2 * (travelTime + loadUnloadTime)); % number of trips for a ship per year in a shipping line
Q_hytransmax = repmat(n_trip,1,2) .* n_hyshipDirection * Q_shiphymax / 8760;
Q_amtransmax = repmat(n_trip,1,2) .* n_amshipDirection * Q_shipammax / 8760;
transportationCapacityCons = [
    Q_hyflow(:) >= 0;
    Q_hyflow(:) <= Q_hytransmax(:);
    Q_amflow(:) >= 0;
    Q_amflow(:) <= Q_amtransmax(:);
    ];

% 4 bounding cons
boundingCons = [
    n_hyshipDirection(:) >= 0;
    n_amshipDirection(:) >= 0;
    ];
% test
testCons = [
    sum(Q_hyspl) - sum(Q_hydm) == 0;
    % sum(Q_amspl) - sum(Q_amdm) == 0;
    ];

cons = [
    supplyCapacityCons;
    countryBalanceCons;
    transportationCapacityCons;
    boundingCons;
    % testCons;
    ];
%% 
[objfcn,costComposition] = objfcn_exportCost(Q_hyspl,Q_amspl,Q_hy_im,Q_am_im,n_hyship,n_amship,LCOHcurve_accumulated,LCOAcurve_accumulated,nCountry,costOptions,shipCosts);
options = sdpsettings('verbose',2,'solver','gurobi', 'debug',1,'showprogress',1);
options.gurobi.MIPGap = 1e-2;
if isfield(costOptions, 'gurobiMIPGap')
    options.gurobi.MIPGap = costOptions.gurobiMIPGap;
end
options.gurobi.TuneTimeLimit = 0;
solutionInfo = optimize(cons,objfcn,options);
%% results
Q_hyspl = value(Q_hyspl); 
Q_amspl = value(Q_amspl); 
Q_hytrans = value(Q_hytrans);
Q_amtrans = value(Q_amtrans);
Q_hyship = value(Q_hyship);
Q_amship = value(Q_amship);
n_hyship = value(n_hyship);
n_amship = value(n_amship);
Q_hytranssum = value(Q_hytranssum);
Q_amtranssum = value(Q_amtranssum);
Q_hyshipsum = value(Q_hyshipsum);
Q_amshipsum  =value(Q_amshipsum);
Q_hy_im  =value(Q_hy_im);
Q_am_im = value(Q_am_im);

[sol.Q_hyspl, sol.Q_amspl, sol.Q_hytrans, sol.Q_amtrans, sol.Q_hyship, sol.Q_amship, sol.n_hyship, sol.n_amship, ...
    sol.Q_hytranssum, sol.Q_amtranssum, sol.Q_hyshipsum, sol.Q_amshipsum] = deal(Q_hyspl, Q_amspl, Q_hytrans, ...
    Q_amtrans, Q_hyship, Q_amship, n_hyship, n_amship, Q_hytranssum, Q_amtranssum, Q_hyshipsum, Q_amshipsum);
% sol.Q_hyspl = sol.Q_hyspl * 8760 / 1e6; sol.Q_amspl = sol.Q_amspl * 8760 / 1e6; % TWh/year



costComposition.hyProductionCostPerCountry = value(costComposition.hyProductionCostPerCountry);
costComposition.amProductionCostPerCountry = value(costComposition.amProductionCostPerCountry);
costComposition.hyTransportationCostPerline = value(costComposition.hyTransportationCostPerline);
costComposition.amTransportationCostPerline = value(costComposition.amTransportationCostPerline);
costComposition.hyProductionCost = value(costComposition.hyProductionCost);
costComposition.amProductionCost = value(costComposition.amProductionCost);
costComposition.hyTransportationCost = value(costComposition.hyTransportationCost);
costComposition.amTransportationCost = value(costComposition.amTransportationCost);
costComposition.amProductionCost_up = value(costComposition.amProductionCost_up);
costComposition.amProductionCost_down = value(costComposition.amProductionCost_down);
costComposition.importCost = value(costComposition.importCost);
totalCost = value(objfcn);
sol.totalCost = totalCost;
sol.shipCosts = shipCosts;
sol.hydrogenEfficiency = offshoreHydrogenEfficiency(year);
sol.Q_hysplmax = Q_hysplmax;
sol.n_hyshipDirection = value(n_hyshipDirection);
sol.n_amshipDirection = value(n_amshipDirection);
sol.Q_hyflow = value(Q_hyflow);
sol.Q_amflow = value(Q_amflow);
sol.costComposition = costComposition;
sol.costOptions = costOptions;

% marginal production cost
marginalCostHy = zeros(nCountry,3); marginalCostAm = zeros(nCountry,3);
for ic = 1:nCountry
    indexHy = find(Q_hyspl(ic) > LCOHcurve{ic}(:,1),1,'last');
    indexAm = find(Q_amspl(ic) > LCOAcurve{ic}(:,1),1,'last');
    if isempty(indexHy)
        indexHy = 1;
    end
    if isempty(indexAm)
        indexAm = 1;
    end
    marginalCostHy(ic,1:3) = [LCOHcurve{ic}(indexHy,:),indexHy];
    marginalCostAm(ic,1:3) = [LCOAcurve{ic}(indexAm,:),indexAm];
end
% hydrogen and am capacity utilization rate
hyUnitizationRate = (Q_hyspl + Q_amspl)./Q_hysplmax;

% hydrogen and ammonia trade among countries
% transportation and fuel (per unit and total) cost
tradingArray = shippingLineArray;
tradingArray(:,4:9) = [Q_hytrans,Q_amtrans,Q_hyship,Q_amship,costComposition.hyTransportationCostPerline,costComposition.amTransportationCostPerline];
for ic = 1:nCountry
    iRow = tradingArray(:,1) == ic & tradingArray(:,2) == ic;
    tradingArray(iRow,4) = min([Q_hydm(ic) - Q_hytranssum(ic),Q_hydm(ic)]);
    tradingArray(iRow,5) = max([min([Q_amdm(ic) - Q_amtranssum(ic),Q_amdm(ic)]),0]);
end
shipHyFuelProportion = shipConsumption .* travelTime / Q_shiphymax; % 每次运输所消耗hy占全船所运的hy的百分比
shipAmFuelProportion = shipConsumption .* travelTime / Q_shipammax; % 每次运输所消耗am占全船所运的am的百分比
hyOrigin = tradingArray(:,1);
amOrigin = tradingArray(:,1);
hyOrigin(Q_hytrans < 0) = tradingArray(Q_hytrans < 0,2);
amOrigin(Q_amtrans < 0) = tradingArray(Q_amtrans < 0,2);
shipHyFuelCost = shipHyFuelProportion .* marginalCostHy(hyOrigin,2) + hyShipOperationCost * travelTime; % 运送每MWh的hy的fuelcost（marginal）
shipAmFuelCost = shipAmFuelProportion .* marginalCostAm(amOrigin,2) + amShipOperationCost * travelTime; % 运送每MWh的am的fuelcost（marginal）
tradingArray(:,10:13) = [shipHyFuelProportion,shipAmFuelProportion,shipHyFuelCost,shipAmFuelCost];
% add intenational trade array
addTradingArray = zeros(nCountry,size(tradingArray,2));
addTradingArray(:,1) = nCountry + 1; addTradingArray(:,2) = (1:nCountry)';
addTradingArray(:,4) = Q_hy_im;
addTradingArray(:,5) = Q_am_im;
tradingArray = [tradingArray;addTradingArray];


shipHyFuelCostMatrix = zeros(nCountry); shipAmFuelCostMatrix = zeros(nCountry);
for ic = 1:nCountry
    for jc = 1:nCountry
        shipHyFuelCostMatrix(ic,jc) = shipConsumption .* shippingLineMatrix(ic,jc)/shipSpeed / Q_shiphymax .* marginalCostHy(ic,2) ...
            + hyShipOperationCost * shippingLineMatrix(ic,jc)/shipSpeed;
        shipAmFuelCostMatrix(ic,jc) = shipConsumption .* shippingLineMatrix(ic,jc)/shipSpeed / Q_shipammax .* marginalCostAm(ic,2) ...
            + amShipOperationCost * shippingLineMatrix(ic,jc)/shipSpeed;
        if ic == jc
            shipHyFuelCostMatrix(ic,jc) = nan; shipAmFuelCostMatrix(ic,jc) = nan;
        end
    end
end

sol.tradingArray = tradingArray;
sol.shipHyFuelCostMatrix = shipHyFuelCostMatrix; sol.shipAmFuelCostMatrix = shipAmFuelCostMatrix;
sol.tradingArray(:,4:7) = sol.tradingArray(:,4:7)* 8760 / 1e6; % TWh/year
% carbon emission reduction by replacing natural gas with hydrogen or
% ammonia (of each country, and contribution by each country)
carbonReductionHyByCountry = Q_hydm * 8760 * 3600 / naturalGasHeatValue / 16 * 44 / 1e9; % Mt CO2/year
carbonReductionAmByCountry = Q_amdm * 8760 * 3600 / ammoniaHeatValue / 17 * 44 / 1e9; % Mt CO2/year
carbonReductionByCountry = carbonReductionHyByCountry + carbonReductionAmByCountry;

carbonReductionContributionMatrix = zeros(nCountry+1);
for ij = 1:nShippingLine
    ic = tradingArray(ij,1); jc = tradingArray(ij,2);
    carbonReduction = Q_hytrans(ij)* 8760 * 3600 / naturalGasHeatValue / 16 * 44 / 1e9 ...
            + Q_amtrans(ij)* 8760 * 3600 / ammoniaHeatValue / 17 * 44 / 1e9; % Mt CO2/year
    if Q_hytrans(ij) > 0
        carbonReductionContributionMatrix(ic,jc) = carbonReductionContributionMatrix(ic,jc) ...
            + Q_hytrans(ij)* 8760 * 3600 / naturalGasHeatValue / 16 * 44 / 1e9; %ic对jc的脱碳贡献
    else
        carbonReductionContributionMatrix(jc,ic) = carbonReductionContributionMatrix(jc,ic) ...
            - Q_hytrans(ij)* 8760 * 3600 / naturalGasHeatValue / 16 * 44 / 1e9;
    end
    if Q_amtrans(ij) > 0
        carbonReductionContributionMatrix(ic,jc) = carbonReductionContributionMatrix(ic,jc) ...
            + Q_amtrans(ij)* 8760 * 3600 / ammoniaHeatValue / 17 * 44 / 1e9; %ic对jc的脱碳贡献
    else
        carbonReductionContributionMatrix(jc,ic) = carbonReductionContributionMatrix(jc,ic) ...
            - Q_amtrans(ij)* 8760 * 3600 / ammoniaHeatValue / 17 * 44 / 1e9;
    end   
end
% international
carbonReductionContributionMatrix(nCountry+1,1:nCountry) = Q_hy_im' * 8760 * 3600 / naturalGasHeatValue / 16 * 44 / 1e9 + Q_am_im' * 8760 * 3600 / ammoniaHeatValue / 17 * 44 / 1e9;
for ic = 1:nCountry
    carbonReductionContributionMatrix(ic,ic) = carbonReductionByCountry(ic) - sum(carbonReductionContributionMatrix(:,ic));
end
carbonReductionContributionMatrix(carbonReductionContributionMatrix<0) = 0;
sol.carbonReductionContributionMatrix = carbonReductionContributionMatrix;

end

