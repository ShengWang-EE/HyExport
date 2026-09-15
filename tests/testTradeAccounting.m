function testTradeAccounting()
% Small synthetic checks only: no optimisation, checkpoints, or paper results.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(root,'src')));

% Recover the vessel investment from discounted annual capital payments.
for year = [2030 2040 2050]
    c = shippingCostParameters(year);
    annualCapital = c.hyAnnualCost - 0.04*c.hyInvestment;
    presentValue = sum(annualCapital ./ (1+c.discountRate).^(1:c.lifetime));
    assert(abs(presentValue-c.hyInvestment) < 1e-6);
end
c2030 = shippingCostParameters(2030);
c2050 = shippingCostParameters('2050');
assert(c2030.hyInvestment == 398e6*0.93);
assert(c2050.hyInvestment == 213e6*0.93);
assert(c2050.hyAnnualCost < c2030.hyAnnualCost);
assert(c2030.amAnnualCost == c2050.amAnnualCost);

% A reversed route charges the exporter, regardless of node numbering.
routes = [1 2; 2 3];
fuel = allocateShippingFuel(routes,[0;3],[5;0],3);
assert(isequal(full(fuel),[0;8;0]));
reversed = allocateShippingFuel(fliplr(routes),[5;0],[0;3],3);
assert(isequal(fuel,reversed));
assert(sum(fuel)==8);
% Source 2 supplies 100 delivered MW plus 5 fuel MW to destination 1.
fuel = allocateShippingFuel([1 2],0,5,2);
netInflow = [100;-100];
assert(all([0;105]+netInflow-fuel-[100;0] == 0));

% Each year uses the manuscript's electrolyser efficiency, before auxiliaries.
modelYears = [2030 2040 2050];
expected = [0.79 0.805 0.82];
netYield = zeros(1,3);
productionCosts = zeros(1,3);
windCost = struct('DEVEX',1e7,'CAPEX',1e9,'installation',1e8,'totalCost',2e9);
for iYear = 1:3
    year = modelYears(iYear);
    assert(abs(electrolyserEfficiency(year)-expected(iYear)) < 1e-12);
    [~,bt,cp,el,wp,waterMassFlow,q] = electrolyzerSizing(1050,year);
    % One standard cubic metre of hydrogen requires about 0.803 kg of water.
    assert(waterMassFlow/q > 0.80 && waterMassFlow/q < 0.81);
    eta = offshoreHydrogenEfficiency(year);
    netYield(iYear) = eta;
    productionCosts(iYear) = evaluateHydrogenCost(1050,bt,cp,el,wp,q,50,windCost,0.5,0.95,year,1);
    assert(abs(bt+cp+el+wp-1050e6) < 1e-5);
    assert(abs(q*12.75e6/el-expected(iYear)) < 1e-12);
    assert(abs(eta-q*12.75e6/(1050e6)) < 1e-12);
    assert(eta > 0 && eta < expected(iYear));
    [curve,cumulative] = hydrogenEnergySupplyCurve([0 50;100 50;200 70],0.5,year);
    yield = 0.5*0.95*eta;
    assert(max(abs(curve(:,1)-[0;100;200]*yield)) < 1e-12);
    assert(cumulative(1,2)==0);
    assert(abs(cumulative(end,2)-200*yield*50) < 1e-10);
    residualWindTWh = 200*0.5*0.95*8760/1e6;
    assert(abs(residualWindTWh*1e6/8760*eta-curve(end,1)) < 1e-12);
    % Domestic PTG: output = input * efficiency, and inverse capacity bound.
    inputMW = 100;
    outputMW = inputMW*expected(iYear);
    assert(outputMW < inputMW && abs(outputMW/expected(iYear)-inputMW)<1e-12);
end
assert(all(diff(netYield)>0));
assert(all(isfinite(productionCosts)) && all(productionCosts>0));
assert(productionCosts(1) ~= productionCosts(3));
% SI annual equipment prices must be selected independently of efficiency.
expectedCAPEX = [625 400 300]*1e3;
expectedOPEX = [12.5 8 6]*1e3;
for iYear = 1:3
    prices = hydrogenCostParameters(modelYears(iYear));
    assert(prices.capex.electrolyser == expectedCAPEX(iYear));
    assert(prices.opex.electrolyser == expectedOPEX(iYear));
end
% Wind-cost sensitivity must leave hydrogen equipment expenditure unchanged.
[~,bt,cp,el,wp,~,q] = electrolyzerSizing(1050,2050);
fullWind = evaluateHydrogenCost(1050,bt,cp,el,wp,q,50,windCost,0.5,0.95,2050,1);
halfWind = evaluateHydrogenCost(1050,bt,cp,el,wp,q,50,windCost,0.5,0.95,2050,0.5);
energyMWh = 27*8760*q*12.75*0.5;
expectedDifference = 0.5*(windCost.totalCost+0.2*windCost.DEVEX*0.93)/energyMWh;
assert(abs(fullWind-halfWind-expectedDifference) < 1e-10);
% The cost of an extra MW of water treatment is independent of wind capacity.
waterCostIncrement = zeros(1,2);
windCapacities = [525 1050];
for k = 1:2
    oneMW = evaluateHydrogenCost(windCapacities(k),bt,cp,el,1e6,q,50,windCost,0.5,0.95,2050,1);
    twoMW = evaluateHydrogenCost(windCapacities(k),bt,cp,el,2e6,q,50,windCost,0.5,0.95,2050,1);
    waterCostIncrement(k) = twoMW-oneMW;
end
assert(all(waterCostIncrement>0));
assert(abs(diff(waterCostIncrement)) < 1e-10);
% Annual H/A prices must not be multiplied by the outer wind reduction again.
annualSupply.H = repmat({[0 60;100 60]},3,1);
annualSupply.A = repmat({[0 70;100 70]},3,1);
outputs = cell(1,18);
[outputs{:}] = owfCostReduction({[0 50;100 50]},0.25*ones(4,2),1,{[20;20]},annualSupply);
for first = [1 7 13]
    assert(all(outputs{first}{1}(:,2)==37.5));
    assert(all(outputs{first+1}{1}(:,2)==60));
    assert(all(outputs{first+2}{1}(:,2)==70));
end
[~,wt] = windTurbineModel(12,15);
assert(wt.ratedPower==15 && wt.rotorRadius==118);
fprintf('Trade accounting checks passed; net efficiencies = %.8f %.8f %.8f.\n',netYield);
end
