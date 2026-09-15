function costs = shippingCostParameters(year)
% Vessel investment and equivalent annual cost, all in EUR.
years = [2030, 2040, 2050];
hydrogenInvestmentUSD = [398, 250, 213] * 1e6;
index = find(years == str2double(string(year)), 1);
assert(~isempty(index), 'Unsupported shipping cost year.');
costs.hyInvestment = hydrogenInvestmentUSD(index) * 0.93;
costs.amInvestment = 52e6 * 0.93;
costs.discountRate = 0.06;
costs.lifetime = 25;
capitalRecoveryFactor = 1 / sum((1 + costs.discountRate).^(-(1:costs.lifetime)));
costs.hyAnnualCost = costs.hyInvestment * (capitalRecoveryFactor + 0.04);
costs.amAnnualCost = costs.amInvestment * (capitalRecoveryFactor + 0.04);
end
