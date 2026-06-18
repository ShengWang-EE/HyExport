function [summaryTable, countryTable] = runDomesticAbsorptionSensitivity(projectRoot)
% Domestic absorption sensitivity for the NC story.
%
% 目的：
% 测试论文里最容易被审稿人质疑的假设：
% 用 Ireland 的 domestic power-gas absorption 结果外推到其他欧洲国家。
%
% 做法：
% 不重新跑 unit commitment，只改变 Europe-wide 国内消纳量的外推系数，
% 然后用同一个 international trading model 重新求解贸易和碳减排结果。
%
% 情景：
% - Low absorption: 国内消纳能力较弱，可出口量更高
% - Base absorption: 当前主文基准
% - High absorption: 国内消纳能力较强，可出口量更低
%
% 入口：
% - 统一从 main.m 调用。
%
% 输出：
% - results/checkpoints/NC_sensitivity_domestic_absorption.mat
% - results/tables/NC_domestic_absorption_sensitivity.csv
% - results/tables/NC_domestic_absorption_sensitivity_country.csv

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
    'EUoffshoreDomesticConsumption', 'capacityFactor_mean', 'nCountry', ...
    'EUoffshoreGenerationTotal', 'EUoffshoreDomesticConsumptionByElectricity', ...
    'EUoffshoreDomesticConsumptionByGas', 'EUoffshoreCurtailedTotal');

nPort = size(data.ferryPortShp_aggregated, 1);
countryCode = ["BE"; "DK"; "FR"; "DE"; "IE"; "NL"; "NO"; "PT"; "ES"; "SE"; "GB"];
nodeCode = [countryCode; "ITN"];
yearList = ["2030", "2040", "2050"];
scenarioName = ["Low absorption", "Base absorption", "High absorption"];
absorptionFactor = [0.75, 1.00, 1.25];

lcohCurves = {data.LCOHcurve2030, data.LCOHcurve2040, data.LCOHcurve2050};
lcoaCurves = {data.LCOAcurve2030, data.LCOAcurve2040, data.LCOAcurve2050};
lcohAccumulated = {data.LCOHcurve2030_accumulated, data.LCOHcurve2040_accumulated, data.LCOHcurve2050_accumulated};
lcoaAccumulated = {data.LCOAcurve2030_accumulated, data.LCOAcurve2040_accumulated, data.LCOAcurve2050_accumulated};

summaryRows = {};
countryRows = {};

for iScenario = 1:numel(scenarioName)
    factorNow = absorptionFactor(iScenario);
    EUwindConsumpSensitive = buildSensitiveWindConsumption(data, factorNow);

    for iYear = 1:numel(yearList)
        yearNow = char(yearList(iYear));

        % 每个 sensitivity case 都重新跑一次贸易优化。
        % 这里改变的只有 EUwindConsumpSensitive，也就是每个国家的可出口上限。
        yalmip('clear')
        [solutionNow, solutionInfoNow] = optimalTransportation( ...
            data.EUhydrogenDemand, data.EUoffshoreCapacity, data.ferryPortShp_aggregated, ...
            data.portIndexPerCountry, data.portInCountry, ...
            lcohCurves{iYear}, lcoaCurves{iYear}, lcohAccumulated{iYear}, lcoaAccumulated{iYear}, ...
            data.EUoffshoreDomesticConsumption, data.capacityFactor_mean, ...
            nPort, data.nCountry, yearNow, EUwindConsumpSensitive);

        result = summariseTradeSolution(solutionNow, nodeCode, data.nCountry);
        exportPotentialTWh = sum(EUwindConsumpSensitive{iYear}(:,3));

        summaryRows(end+1,:) = makeSummaryRow(str2double(yearNow), scenarioName(iScenario), ...
            factorNow, exportPotentialTWh, solutionInfoNow.problem, result);
        countryRows = appendCountryRows(countryRows, str2double(yearNow), scenarioName(iScenario), ...
            factorNow, nodeCode, result);

        sensitivitySolution{iScenario,iYear} = solutionNow;
        sensitivityInfo{iScenario,iYear} = solutionInfoNow;
    end
end

summaryTable = cell2table(summaryRows, 'VariableNames', { ...
    'Year', 'Scenario', 'DomesticAbsorptionFactor', 'ExportPotential_TWh', ...
    'SolverProblemCode', 'EuropeanOffshoreSupply_TWh', 'InternationalImport_TWh', ...
    'TotalCarbonReduction_Mt', 'EuropeanOffshoreCarbonContribution_Mt', ...
    'TopGrossExporter', 'TopGrossExport_TWh', 'TopNetExporter', 'TopNetExport_TWh', ...
    'IrelandNetExport_TWh', 'UKNetExport_TWh', ...
    'IrelandCarbonContribution_Mt', 'UKCarbonContribution_Mt'});

countryTable = cell2table(countryRows, 'VariableNames', { ...
    'Year', 'Scenario', 'DomesticAbsorptionFactor', 'Country', ...
    'EuropeanOffshoreSupply_TWh', 'GrossExport_TWh', 'GrossImport_TWh', ...
    'NetExport_TWh', 'SupplierCarbonContribution_Mt'});

writetable(summaryTable, fullfile(tableDir, 'NC_domestic_absorption_sensitivity.csv'));
writetable(countryTable, fullfile(tableDir, 'NC_domestic_absorption_sensitivity_country.csv'));

save(fullfile(checkpointDir, 'NC_sensitivity_domestic_absorption.mat'), ...
    'summaryTable', 'countryTable', 'sensitivitySolution', 'sensitivityInfo', ...
    'scenarioName', 'absorptionFactor', 'countryCode', 'yearList');

disp(summaryTable)
end

function EUwindConsumpSensitive = buildSensitiveWindConsumption(data, absorptionFactor)
% 按国内消纳系数重建 EUwindConsump_new。
%
% data 里的 EUoffshoreGenerationTotal 等变量单位是 GW 平均功率。
% 输出 EUwindConsumpSensitive 的单位是 TWh/year，结构与原来的 EUwindConsump_new 相同：
% 第 1 列：domestic electricity use
% 第 2 列：domestic gas/hydrogen use
% 第 3 列：exportable offshore wind/hydrogen
% 第 4 列：unavoidable curtailment

for iYear = 1:3
    domesticElectricityGW = data.EUoffshoreDomesticConsumptionByElectricity(:,iYear) * absorptionFactor;
    domesticGasGW = data.EUoffshoreDomesticConsumptionByGas(:,iYear) * absorptionFactor;
    curtailedGW = data.EUoffshoreCurtailedTotal(:,iYear);
    exportGW = data.EUoffshoreGenerationTotal(:,iYear) - domesticElectricityGW - domesticGasGW - curtailedGW;

    windConsump = [domesticElectricityGW, domesticGasGW, exportGW, curtailedGW] * 8760 / 1e3;
    windConsumpNew = windConsump;

    % 如果国内消纳加不可避免弃风超过总发电，则把超出的部分按比例扣回去。
    % 这样不会出现负的可出口量，也保持和 main.m 原有处理逻辑一致。
    deductionBaseGW = [domesticElectricityGW, domesticGasGW, curtailedGW];
    deductionTotalGW = sum(deductionBaseGW, 2);
    deduction = repmat(-exportGW ./ deductionTotalGW, [1,3]) .* deductionBaseGW * 8760 / 1e3;
    deduction(deduction < 0) = 0;

    [windConsumpNew(:,1), windConsumpNew(:,2), windConsumpNew(:,4)] = ...
        deal(windConsump(:,1) - deduction(:,1), windConsump(:,2) - deduction(:,2), ...
        windConsump(:,4) - deduction(:,3));
    windConsumpNew(windConsumpNew < 0) = 0;

    EUwindConsumpSensitive{iYear} = windConsumpNew;
end
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
result.topGrossExporter = nodeCode(topGrossIdx);
result.topGrossExportTWh = topGrossExportTWh;
result.topNetExporter = nodeCode(topNetIdx);
result.topNetExportTWh = topNetExportTWh;
end

function row = makeSummaryRow(year, scenario, factorNow, exportPotentialTWh, problemCode, result)
% 汇总表：每个年份、每个国内消纳情景一行。

irelandIndex = 5;
ukIndex = 11;
row = {year, scenario, factorNow, exportPotentialTWh, problemCode, ...
    result.europeanOffshoreSupplyTWh, result.internationalImportTWh, ...
    result.totalCarbonReductionMt, result.europeanOffshoreCarbonMt, ...
    result.topGrossExporter, result.topGrossExportTWh, result.topNetExporter, result.topNetExportTWh, ...
    result.netExportTWh(irelandIndex), result.netExportTWh(ukIndex), ...
    result.supplierCarbonMt(irelandIndex), result.supplierCarbonMt(ukIndex)};
end

function rows = appendCountryRows(rows, year, scenario, factorNow, nodeCode, result)
% 国家表：保留画 sensitivity 图需要的国家级指标。

for iNode = 1:numel(nodeCode)
    rows(end+1,:) = {year, scenario, factorNow, nodeCode(iNode), ...
        result.supplyTWh(iNode), result.grossExportTWh(iNode), ...
        result.grossImportTWh(iNode), result.netExportTWh(iNode), ...
        result.supplierCarbonMt(iNode)};
end
end
