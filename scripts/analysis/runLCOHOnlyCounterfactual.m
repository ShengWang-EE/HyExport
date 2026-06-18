function [summaryTable, countryTable] = runLCOHOnlyCounterfactual(projectRoot)
% LCOH-only counterfactual for the NC story.
%
% 目的：
% 这个函数不是替代原来的 integrated optimisation model，而是做一个反事实基线。
% 反事实问题是：如果欧洲绿氢贸易只按最低 LCOH 从低到高拿供应，
% 会得到怎样的供应国家排序、净出口格局和国际进口需求？
%
% 入口：
% - 统一从 main.m 调用。平时不要单独运行这个文件，避免入口分散。
%
% 输出：
% - results/checkpoints/NC_counterfactual_lcoh_only.mat
% - results/tables/NC_story_comparison.csv
% - results/tables/NC_story_comparison_country.csv

projectRoot = setupHyExport(projectRoot);

checkpointDir = fullfile(projectRoot, 'results', 'checkpoints');
tableDir = fullfile(projectRoot, 'results', 'tables');
if ~exist(tableDir, 'dir')
    mkdir(tableDir);
end

data = load(fullfile(checkpointDir, 'stop3.mat'), ...
    'EUcountryList', 'EUhydrogenDemand', 'EUoffshoreCapacity', 'capacityFactor_mean', ...
    'LCOHcurve2030', 'LCOHcurve2040', 'LCOHcurve2050', 'solution');

countryName = string(data.EUcountryList(:));
countryCode = ["BE"; "DK"; "FR"; "DE"; "IE"; "NL"; "NO"; "PT"; "ES"; "SE"; "GB"];
nodeCode = [countryCode; "ITN"];
yearList = [2030; 2040; 2050];
lcohCurves = {data.LCOHcurve2030, data.LCOHcurve2040, data.LCOHcurve2050};

summaryRows = {};
countryRows = {};

for iYear = 1:numel(yearList)
    year = yearList(iYear);

    % 需求单位是 TWh/year。EUhydrogenDemand 里每个年份有 ammonia 和三类氢需求。
    [countryDemandTWh, totalDemandTWh] = getDemandTWh(data.EUhydrogenDemand, iYear);

    % integrated model 是现在论文里的主模型结果。
    integrated = summariseIntegratedModel(data.solution{iYear}, countryDemandTWh, nodeCode);
    summaryRows(end+1,:) = makeSummaryRow(year, "Integrated model", totalDemandTWh, integrated);
    countryRows = appendCountryRows(countryRows, year, "Integrated model", nodeCode, ...
        [countryDemandTWh; NaN], integrated);

    % LCOH-only 反事实：只看政策 offshore capacity 和 LCOH 供应曲线。
    % 这里不扣除国内电-气系统消纳，也不考虑 shipping 和贸易优化。
    % 单位换算：GW * capacity factor * 8760 h/year = TWh/year 时，系数是 8.76。
    productionPotentialTWh = data.EUoffshoreCapacity(:,iYear) .* data.capacityFactor_mean * 8.76;
    lcohOnlySupplyTWh = allocateByLowestLCOH(lcohCurves{iYear}, productionPotentialTWh, totalDemandTWh);
    lcohOnly = summariseLCOHOnlyBaseline(lcohOnlySupplyTWh, countryDemandTWh, integrated.totalCarbonReductionMt, nodeCode);
    summaryRows(end+1,:) = makeSummaryRow(year, "LCOH-only baseline", totalDemandTWh, lcohOnly);
    countryRows = appendCountryRows(countryRows, year, "LCOH-only baseline", nodeCode, ...
        [countryDemandTWh; NaN], lcohOnly);
end

summaryTable = cell2table(summaryRows, 'VariableNames', { ...
    'Year', 'Scenario', 'TotalDemand_TWh', 'EuropeanOffshoreSupply_TWh', ...
    'InternationalImport_TWh', 'TotalCarbonReduction_Mt', ...
    'EuropeanOffshoreCarbonContribution_Mt', 'TopGrossExporter', ...
    'TopGrossExport_TWh', 'TopNetExporter', 'TopNetExport_TWh', ...
    'IrelandGrossExport_TWh', 'IrelandNetExport_TWh', ...
    'UKGrossExport_TWh', 'UKNetExport_TWh'});

countryTable = cell2table(countryRows, 'VariableNames', { ...
    'Year', 'Scenario', 'Country', 'DomesticDemand_TWh', ...
    'EuropeanOffshoreSupply_TWh', 'GrossExport_TWh', 'GrossImport_TWh', ...
    'NetExport_TWh', 'SupplierCarbonContribution_Mt'});

writetable(summaryTable, fullfile(tableDir, 'NC_story_comparison.csv'));
writetable(countryTable, fullfile(tableDir, 'NC_story_comparison_country.csv'));

save(fullfile(checkpointDir, 'NC_counterfactual_lcoh_only.mat'), ...
    'summaryTable', 'countryTable', 'yearList', 'countryName', 'countryCode');

disp(summaryTable)
end

function [countryDemandTWh, totalDemandTWh] = getDemandTWh(EUhydrogenDemand, iYear)
% 从 EUhydrogenDemand 里取每个年份的 ammonia + hydrogen demand。
% 表里的数值已经是 TWh/year，所以这里不再做 8760 小时换算。

ammoniaColumns = [2, 7, 12];
hydrogenColumns = {3:5, 8:10, 13:15};
countryDemandTWh = table2array(EUhydrogenDemand(:, ammoniaColumns(iYear))) ...
    + sum(table2array(EUhydrogenDemand(:, hydrogenColumns{iYear})), 2);
totalDemandTWh = sum(countryDemandTWh);
end

function supplyByCountryTWh = allocateByLowestLCOH(LCOHcurve, exportPotentialTWh, totalDemandTWh)
% 把每个国家的 LCOH curve 拆成供应小段，然后按 LCOH 从低到高拿供应。
% 这里故意不考虑运输距离、船舶投资、国内消纳约束和需求地理分布，
% 因为目标是构造一个 "只看最低 LCOH 会怎样" 的反事实。

nCountry = numel(LCOHcurve);
segmentCountry = [];
segmentCost = [];
segmentEnergyTWh = [];

for ic = 1:nCountry
    curve = LCOHcurve{ic};
    maxExportMW = exportPotentialTWh(ic) * 1e6 / 8760;
    clippedCapacityMW = min(curve(:,1), maxExportMW);
    segmentMW = diff([0; clippedCapacityMW]);
    validSegment = segmentMW > 0;

    segmentCountry = [segmentCountry; repmat(ic, sum(validSegment), 1)];
    segmentCost = [segmentCost; curve(validSegment,2)];
    segmentEnergyTWh = [segmentEnergyTWh; segmentMW(validSegment) * 8760 / 1e6];
end

[~, order] = sort(segmentCost, 'ascend');
segmentCountry = segmentCountry(order);
segmentEnergyTWh = segmentEnergyTWh(order);

supplyByCountryTWh = zeros(nCountry, 1);
remainingDemandTWh = totalDemandTWh;
for iSegment = 1:numel(segmentEnergyTWh)
    usedEnergyTWh = min(segmentEnergyTWh(iSegment), remainingDemandTWh);
    supplyByCountryTWh(segmentCountry(iSegment)) = supplyByCountryTWh(segmentCountry(iSegment)) + usedEnergyTWh;
    remainingDemandTWh = remainingDemandTWh - usedEnergyTWh;
    if remainingDemandTWh <= 0
        break
    end
end
end

function result = summariseIntegratedModel(solution, countryDemandTWh, nodeCode)
% 从 integrated optimisation model 的 tradingArray 和 carbon matrix 里提取论文需要的口径。

nCountry = numel(countryDemandTWh);
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

countrySupplyTWh = (solution.Q_hyspl + solution.Q_amspl) * 8760 / 1e6;
supplierCarbonMt = sum(solution.carbonReductionContributionMatrix, 2);

result = buildResult(nodeCode, [countrySupplyTWh; grossExportTWh(end)], ...
    grossExportTWh, grossImportTWh, supplierCarbonMt);
result.totalCarbonReductionMt = sum(solution.carbonReductionContributionMatrix, 'all');
result.europeanOffshoreCarbonMt = sum(solution.carbonReductionContributionMatrix(1:nCountry,:), 'all');
result.internationalImportTWh = grossExportTWh(end);
end

function result = summariseLCOHOnlyBaseline(supplyByCountryTWh, countryDemandTWh, referenceCarbonMt, nodeCode)
% LCOH-only baseline 只决定谁生产。为了得到出口/进口口径，
% 这里先让每个国家的供应满足本国需求，超过本国需求的部分记为 gross export。
% 如果总供应不足，总缺口记为 ITN international import。

totalDemandTWh = sum(countryDemandTWh);
totalSupplyTWh = sum(supplyByCountryTWh);
internationalImportTWh = max(totalDemandTWh - totalSupplyTWh, 0);
if internationalImportTWh < 1e-9
    internationalImportTWh = 0;
end

netExportCountryTWh = supplyByCountryTWh - countryDemandTWh;
grossExportTWh = [max(netExportCountryTWh, 0); internationalImportTWh];
grossImportTWh = [max(-netExportCountryTWh, 0); 0];

% 这个 carbon contribution 是用于 story comparison 的比例估算：
% 总减排强度沿用 integrated model，同一份欧洲需求中，谁供应就把减排贡献分给谁。
supplierCarbonMt = [supplyByCountryTWh; internationalImportTWh] / totalDemandTWh * referenceCarbonMt;

result = buildResult(nodeCode, [supplyByCountryTWh; internationalImportTWh], ...
    grossExportTWh, grossImportTWh, supplierCarbonMt);
result.totalCarbonReductionMt = min(totalSupplyTWh + internationalImportTWh, totalDemandTWh) / totalDemandTWh * referenceCarbonMt;
result.europeanOffshoreCarbonMt = totalSupplyTWh / totalDemandTWh * referenceCarbonMt;
result.internationalImportTWh = internationalImportTWh;
end

function result = buildResult(nodeCode, supplyTWh, grossExportTWh, grossImportTWh, supplierCarbonMt)
% 统一整理 integrated model 和 LCOH-only baseline 的输出字段。

netExportTWh = grossExportTWh - grossImportTWh;
[topGrossExportTWh, topGrossIdx] = max(grossExportTWh(1:end-1));
[topNetExportTWh, topNetIdx] = max(netExportTWh(1:end-1));

result.supplyTWh = supplyTWh;
result.grossExportTWh = grossExportTWh;
result.grossImportTWh = grossImportTWh;
result.netExportTWh = netExportTWh;
result.supplierCarbonMt = supplierCarbonMt;
result.europeanOffshoreSupplyTWh = sum(supplyTWh(1:end-1));
result.topGrossExporter = nodeCode(topGrossIdx);
result.topGrossExportTWh = topGrossExportTWh;
result.topNetExporter = nodeCode(topNetIdx);
result.topNetExportTWh = topNetExportTWh;
end

function row = makeSummaryRow(year, scenario, totalDemandTWh, result)
% 汇总表是一年一个 scenario 一行，方便直接看论文故事。

irelandIndex = 5;
ukIndex = 11;
row = {year, scenario, totalDemandTWh, result.europeanOffshoreSupplyTWh, ...
    result.internationalImportTWh, result.totalCarbonReductionMt, ...
    result.europeanOffshoreCarbonMt, result.topGrossExporter, ...
    result.topGrossExportTWh, result.topNetExporter, result.topNetExportTWh, ...
    result.grossExportTWh(irelandIndex), result.netExportTWh(irelandIndex), ...
    result.grossExportTWh(ukIndex), result.netExportTWh(ukIndex)};
end

function rows = appendCountryRows(rows, year, scenario, nodeCode, demandTWh, result)
% 国家表保留每个国家和 ITN 的细节，后面画 Fig. 4 可以直接读这个表。

for iNode = 1:numel(nodeCode)
    rows(end+1,:) = {year, scenario, nodeCode(iNode), demandTWh(iNode), ...
        result.supplyTWh(iNode), result.grossExportTWh(iNode), ...
        result.grossImportTWh(iNode), result.netExportTWh(iNode), ...
        result.supplierCarbonMt(iNode)};
end
end
