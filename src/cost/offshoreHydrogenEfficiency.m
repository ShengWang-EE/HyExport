function efficiency = offshoreHydrogenEfficiency(year)
% Net HHV hydrogen energy / wind electricity, including auxiliary loads.
% Cache the three sizing calculations, not one year-independent efficiency.
electrolyserEfficiency(year); % Validate the requested model year.
persistent netEfficiency
modelYears = [2030 2040 2050];
if isempty(netEfficiency)
    netEfficiency = zeros(1,3);
    for iYear = 1:3
        [~,~,~,~,~,~,hydrogenFlow] = electrolyzerSizing(1050,modelYears(iYear));
        netEfficiency(iYear) = hydrogenFlow * 12.75e6 / (1050e6);
    end
end
efficiency = netEfficiency(modelYears == str2double(string(year)));
end
