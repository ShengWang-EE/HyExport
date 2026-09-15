function costs = hydrogenCostParameters(year)
% SI supplementary hydrogen-system cost table: columns are 2030/2040/2050.
index = find([2030 2040 2050] == str2double(string(year)),1);
assert(~isempty(index), 'Use a model year: 2030, 2040 or 2050.');
p2e = 1.17;
u2e = 0.93;
capex.electrolyser = [625 400 300] * 1e3;
capex.compressor = [3.3 2.3 2.0] * 1e3 * p2e;
capex.battery = [48.2 35.5 19.3] * 1e3 * p2e;
capex.water = [1.2 0.8 0.2] * 1e3 * p2e;
capex.platform = [198.4 167.5 111.5] * 1e3 * p2e;
capex.replacement = [9.37 18.05 9.82] * 1e3 * p2e;
capex.pipeline = 37360 * 0.99.^[0 10 20] * u2e;
opex.electrolyser = 0.02 * capex.electrolyser;
opex.compressor = [0.10 0.07 0.03] * 1e3 * p2e;
opex.battery = [1.20 0.89 0.48] * 1e3 * p2e;
opex.water = [0.04 0.02 0.01] * 1e3 * p2e;
opex.platform = [2.5 2.5 2.5] * 1e3 * p2e;
opex.pipeline = 0.03 * capex.pipeline;
names = fieldnames(capex);
for i = 1:numel(names)
    name = names{i};
    costs.capex.(name) = capex.(name)(index);
end
names = fieldnames(opex);
for i = 1:numel(names)
    name = names{i};
    costs.opex.(name) = opex.(name)(index);
end
costs.year = str2double(string(year));
end
