function [summaryTable, countryTable] = runOutsideOptionSensitivity(projectRoot)
% Outside-option threshold scan for the NC story.
%
% 目的：
% 不把论文主文的稳健性压在 domestic absorption 这种自定义假设上，
% 而是检查一个更自然、也更容易被文献支撑的问题：
% 如果欧洲以外低碳氢/氨进口价格下降，欧洲 offshore hydrogen 还会不会被使用？
%
% 做法：
% 把 international import node 从原来的高惩罚项改成可竞争的外部价格。
% 每个价格点重新求解一次 international trading model。
%
% 入口：
% - 统一从 main.m 调用。
%
% 输出：
% - results/checkpoints/NC_sensitivity_outside_option.mat
% - results/tables/NC_outside_option_sensitivity.csv
% - results/tables/NC_outside_option_sensitivity_country.csv

projectRoot = setupHyExport(projectRoot);

checkpointDir = fullfile(projectRoot, 'results', 'checkpoints');
tableDir = fullfile(projectRoot, 'results', 'tables');
if ~exist(tableDir, 'dir')
    mkdir(tableDir);
end

data = load(fullfile(checkpointDir, 'stop2.mat'), ...
    'EUcountryList', 'EUhydrogenDemand', 'EUoffshoreCapacity', ...
    'ferryPortShp_aggregated', 'portIndexPerCountry', 'portInCountry', ...
    'LCOHcurve2030', 'LCOAcurve2030', 'LCOHcurve2030_accumulated', 'LCOAcurve2030_accumulated', ...
    'LCOHcurve2040', 'LCOAcurve2040', 'LCOHcurve2040_accumulated', 'LCOAcurve2040_accumulated', ...
    'LCOHcurve2050', 'LCOAcurve2050', 'LCOHcurve2050_accumulated', 'LCOAcurve2050_accumulated', ...
    'EUoffshoreDomesticConsumption', 'capacityFactor_mean', 'nCountry', 'EUwindConsump_new');

nPort = size(data.ferryPortShp_aggregated, 1);

countryCode = ["BE"; "DK"; "FR"; "DE"; "IE"; "NL"; "NO"; "PT"; "ES"; "SE"; "GB"];
nodeCode = [countryCode; "ITN"];
yearList = ["2030", "2040", "2050"];

% 工作价格网格：2-6 EUR/kg-H2，折算成 60-180 EUR/MWh。
% 这个范围不是预测情景，而是 threshold scan：
% 低端覆盖 IRENA 乐观 global trade/cost outlook，较高端覆盖交付、基础设施、融资和政策不确定性。
% 具体来源整理在 manuscript/notes/outside_option_price_sources.md。
hydrogenLHV_MWhPerKg = 33.333e-3;
importCost_EURperMWh = [60; 90; 120; 150; 180];
importCost_EURperKgH2 = importCost_EURperMWh * hydrogenLHV_MWhPerKg;
scenarioName = "Outside option " + string(round(importCost_EURperKgH2, 1)) + " EUR/kg-H2";

lcohCurves = {data.LCOHcurve2030, data.LCOHcurve2040, data.LCOHcurve2050};
lcoaCurves = {data.LCOAcurve2030, data.LCOAcurve2040, data.LCOAcurve2050};
lcohAccumulated = {data.LCOHcurve2030_accumulated, data.LCOHcurve2040_accumulated, data.LCOHcurve2050_accumulated};
lcoaAccumulated = {data.LCOAcurve2030_accumulated, data.LCOAcurve2040_accumulated, data.LCOAcurve2050_accumulated};

summaryRows = {};
countryRows = {};

for iPrice = 1:numel(importCost_EURperMWh)
    costOptions.importCostMode = "price";
    costOptions.hyImportCost_EURperMWh = importCost_EURperMWh(iPrice);
    costOptions.amImportCost_EURperMWh = importCost_EURperMWh(iPrice);
    costOptions.gurobiMIPGap = 1e-4;

    for iYear = 1:numel(yearList)
        yearNow = char(yearList(iYear));

        % 每个 outside-option price 都重新解贸易优化。
        yalmip('clear')
        [solutionNow, solutionInfoNow] = optimalTransportation( ...
            data.EUhydrogenDemand, data.EUoffshoreCapacity, data.ferryPortShp_aggregated, ...
            data.portIndexPerCountry, data.portInCountry, ...
            lcohCurves{iYear}, lcoaCurves{iYear}, lcohAccumulated{iYear}, lcoaAccumulated{iYear}, ...
            data.EUoffshoreDomesticConsumption, data.capacityFactor_mean, ...
            nPort, data.nCountry, yearNow, data.EUwindConsump_new, costOptions);

        result = summariseTradeSolution(solutionNow, nodeCode, data.nCountry);
        summaryRows(end+1,:) = makeSummaryRow(str2double(yearNow), scenarioName(iPrice), ...
            importCost_EURperMWh(iPrice), importCost_EURperKgH2(iPrice), solutionInfoNow.problem, result);
        countryRows = appendCountryRows(countryRows, str2double(yearNow), scenarioName(iPrice), ...
            importCost_EURperMWh(iPrice), importCost_EURperKgH2(iPrice), nodeCode, result);

        outsideOptionSolution{iPrice,iYear} = solutionNow;
        outsideOptionInfo{iPrice,iYear} = solutionInfoNow;
    end
end

summaryTable = cell2table(summaryRows, 'VariableNames', { ...
    'Year', 'Scenario', 'ImportCost_EURperMWh', 'ImportCost_EURperKgH2', ...
    'SolverProblemCode', 'EuropeanOffshoreSupply_TWh', 'InternationalImport_TWh', ...
    'TotalCarbonReduction_Mt', 'EuropeanOffshoreCarbonContribution_Mt', ...
    'TotalCost_BnEUR', 'ImportCost_BnEUR', ...
    'TopGrossExporter', 'TopGrossExport_TWh', 'TopNetExporter', 'TopNetExport_TWh', ...
    'IrelandNetExport_TWh', 'UKNetExport_TWh', ...
    'IrelandCarbonContribution_Mt', 'UKCarbonContribution_Mt'});

countryTable = cell2table(countryRows, 'VariableNames', { ...
    'Year', 'Scenario', 'ImportCost_EURperMWh', 'ImportCost_EURperKgH2', 'Country', ...
    'EuropeanOffshoreSupply_TWh', 'GrossExport_TWh', 'GrossImport_TWh', ...
    'NetExport_TWh', 'SupplierCarbonContribution_Mt'});

writetable(summaryTable, fullfile(tableDir, 'NC_outside_option_sensitivity.csv'));
writetable(countryTable, fullfile(tableDir, 'NC_outside_option_sensitivity_country.csv'));

save(fullfile(checkpointDir, 'NC_sensitivity_outside_option.mat'), ...
    'summaryTable', 'countryTable', 'outsideOptionSolution', 'outsideOptionInfo', ...
    'scenarioName', 'importCost_EURperMWh', 'importCost_EURperKgH2', 'countryCode', 'yearList');

disp(summaryTable)
end

function result = summariseTradeSolution(solution, nodeCode, nCountry)
% 从 optimalTransportation 的输出里提取论文关心的指标。

nNode = nCountry + 1;
grossExportTWh = zeros(nNode, 1);
grossImportTWh = zeros(nNode, 1);

tradingArray = solution.tradingArray;
for iLine = 1:size(tradingArray,1)
    fromNode0 = tradingArray(iLine,1);
    toNode0 = tradingArray(iLine,2);
    flowValues = tradingArray(iLine,4:5);

    for iFlow = 1:numel(flowValues)
        flowTWh = flowValues(iFlow);
        if flowTWh > 0
            fromNode = fromNode0;
            toNode = toNode0;
        elseif flowTWh < 0
            fromNode = toNode0;
            toNode = fromNode0;
            flowTWh = -flowTWh;
        else
            continue
        end

        if fromNode ~= toNode
            grossExportTWh(fromNode) = grossExportTWh(fromNode) + flowTWh;
            grossImportTWh(toNode) = grossImportTWh(toNode) + flowTWh;
        end
    end
end

supplyTWh = [(solution.Q_hyspl + solution.Q_amspl) * 8760 / 1e6; grossExportTWh(end)];
supplierCarbonMt = sum(solution.carbonReductionContributionMatrix, 2);
netExportTWh = grossExportTWh - grossImportTWh;

[topGrossExportTWh, topGrossIdx] = max(grossExportTWh(1:nCountry));
[topNetExportTWh, topNetIdx] = max(netExportTWh(1:nCountry));

result.supplyTWh = supplyTWh;
result.grossExportTWh = grossExportTWh;
result.grossImportTWh = grossImportTWh;
result.netExportTWh = netExportTWh;
result.supplierCarbonMt = supplierCarbonMt;
result.europeanOffshoreSupplyTWh = sum(supplyTWh(1:nCountry));
result.internationalImportTWh = grossExportTWh(end);
result.totalCarbonReductionMt = sum(solution.carbonReductionContributionMatrix, 'all');
result.europeanOffshoreCarbonMt = sum(solution.carbonReductionContributionMatrix(1:nCountry,:), 'all');
result.totalCostBnEUR = solution.totalCost / 1e9;
result.importCostBnEUR = solution.costComposition.importCost / 1e9;
result.topGrossExporter = nodeCode(topGrossIdx);
result.topGrossExportTWh = topGrossExportTWh;
result.topNetExporter = nodeCode(topNetIdx);
result.topNetExportTWh = topNetExportTWh;
end

function row = makeSummaryRow(year, scenario, importCostMWh, importCostKg, problemCode, result)
% 汇总表：每个年份、每个进口价格一行。

irelandIndex = 5;
ukIndex = 11;
row = {year, scenario, importCostMWh, importCostKg, problemCode, ...
    result.europeanOffshoreSupplyTWh, result.internationalImportTWh, ...
    result.totalCarbonReductionMt, result.europeanOffshoreCarbonMt, ...
    result.totalCostBnEUR, result.importCostBnEUR, ...
    result.topGrossExporter, result.topGrossExportTWh, result.topNetExporter, result.topNetExportTWh, ...
    result.netExportTWh(irelandIndex), result.netExportTWh(ukIndex), ...
    result.supplierCarbonMt(irelandIndex), result.supplierCarbonMt(ukIndex)};
end

function rows = appendCountryRows(rows, year, scenario, importCostMWh, importCostKg, nodeCode, result)
% 国家表：保留画 robustness 图需要的国家级指标。

for iNode = 1:numel(nodeCode)
    rows(end+1,:) = {year, scenario, importCostMWh, importCostKg, nodeCode(iNode), ...
        result.supplyTWh(iNode), result.grossExportTWh(iNode), ...
        result.grossImportTWh(iNode), result.netExportTWh(iNode), ...
        result.supplierCarbonMt(iNode)};
end
end
