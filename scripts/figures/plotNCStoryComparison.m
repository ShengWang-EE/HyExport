function plotNCStoryComparison(projectRoot)
% Plot the LCOH-only counterfactual against the integrated model.
%
% 目的：
% 把 `runLCOHOnlyCounterfactual` 生成的结果画成更接近 Nature Communications
% energy-system 图件风格的主文候选图。核心信息不是“谁的柱子更长”，而是
% 国家净出口平衡在 cost-only 和 integrated 两种模型之间如何系统性改变。
%
% 入口：
% - 统一从 main.m 调用。
%
% 输出：
% - results/figures/fig_nc_lcoh_counterfactual.pdf
% - results/figures/fig_nc_lcoh_counterfactual.png
% - manuscript/figs/fig_nc_lcoh_counterfactual.pdf

projectRoot = setupHyExport(projectRoot);

tablePath = fullfile(projectRoot, 'results', 'tables', 'NC_story_comparison.csv');
countryTablePath = fullfile(projectRoot, 'results', 'tables', ...
    'NC_story_comparison_country.csv');
sensitivityTablePath = fullfile(projectRoot, 'results', 'tables', ...
    'NC_outside_option_sensitivity.csv');
sensitivityCountryTablePath = fullfile(projectRoot, 'results', 'tables', ...
    'NC_outside_option_sensitivity_country.csv');
figureDir = fullfile(projectRoot, 'results', 'figures');
manuscriptFigureDir = fullfile(projectRoot, 'manuscript', 'figs');

if ~exist(figureDir, 'dir')
    mkdir(figureDir);
end
if ~exist(manuscriptFigureDir, 'dir')
    mkdir(manuscriptFigureDir);
end

summaryTable = readtable(tablePath, 'TextType', 'string');
countryTable = readtable(countryTablePath, 'TextType', 'string');
sensitivitySummaryTable = readtable(sensitivityTablePath, 'TextType', 'string');
sensitivityCountryTable = readtable(sensitivityCountryTablePath, 'TextType', 'string');

yearList = [2030 2040 2050];
scenarioList = ["LCOH-only baseline", "Integrated model"];
scenarioLabel = ["Cost-only", "Integrated"];
europeCountry = ["BE","DK","FR","DE","IE","NL","NO","PT","ES","SE","GB"];

netExportMatrix = buildNetExportMatrix(countryTable, yearList, scenarioList, europeCountry);
countryOrder = sortCountriesBy2050Integrated(netExportMatrix, europeCountry);
netExportMatrix = netExportMatrix(countryOrder,:);
countryLabel = europeCountry(countryOrder);

[topExporter, topExport, ~] = buildSummaryMatrices(summaryTable, ...
    yearList, scenarioList);

sensitivityYearList = unique(sensitivitySummaryTable.Year, 'stable');
sensitivityPriceKgList = unique(sensitivitySummaryTable.ImportCost_EURperKgH2, 'stable');
sensitivityPriceMWhList = round(unique(sensitivitySummaryTable.ImportCost_EURperMWh, 'stable'));
literatureAnchorPrice = makeLiteratureAnchorPrices(projectRoot, sensitivityYearList);
offshoreSupply = makeSummaryMatrix(sensitivitySummaryTable, sensitivityYearList, ...
    sensitivityPriceKgList, 'EuropeanOffshoreSupply_TWh');
outsideImport = makeSummaryMatrix(sensitivitySummaryTable, sensitivityYearList, ...
    sensitivityPriceKgList, 'InternationalImport_TWh');
europeCarbon = makeSummaryMatrix(sensitivitySummaryTable, sensitivityYearList, ...
    sensitivityPriceKgList, 'EuropeanOffshoreCarbonContribution_Mt');
totalCarbon = makeSummaryMatrix(sensitivitySummaryTable, sensitivityYearList, ...
    sensitivityPriceKgList, 'TotalCarbonReduction_Mt');
externalCarbon = totalCarbon - europeCarbon;
sensitivityCountryList = unique( ...
    sensitivityCountryTable.Country(sensitivityCountryTable.Country ~= "ITN"), 'stable');
countryNetExport2050 = getCountryNetExport(sensitivityCountryTable, 2050, ...
    sensitivityPriceKgList, sensitivityCountryList);
[~, price35Index] = min(abs(sensitivityPriceKgList - 3.5));
[~, sensitivityCountryOrder] = sort(countryNetExport2050(:, price35Index), 'descend');
sensitivityCountryList = sensitivityCountryList(sensitivityCountryOrder);
countryNetExportByYear = getCountryNetExportByYear(sensitivityCountryTable, ...
    sensitivityYearList, sensitivityPriceKgList, sensitivityCountryList);

blueColor = [0.02 0.24 0.47];
orangeColor = [0.78 0.34 0.12];
axisColor = [0.18 0.18 0.18];

fig = figure('Color', 'white', 'Position', [100 100 1300 1300]);

% panel a：国家净出口平衡是主证据，模仿能源系统文章常用的 country-balance heatmap。
heatmapAx = axes('Parent', fig, 'Position', [0.040 0.60 0.46 0.29]);
plotCountryBalanceHeatmap(heatmapAx, netExportMatrix, countryLabel, yearList, ...
    scenarioLabel, topExporter, topExport, axisColor);

% panel b：外部进口价格改变碳减排归因，但核心 offshore role 在高于边界后稳定。
carbonAx = axes('Parent', fig, 'Position', [0.620 0.60 0.34 0.29]);
plotCarbonOwnershipCurve(carbonAx, sensitivityPriceMWhList, externalCarbon, ...
    europeCarbon, sensitivityYearList, blueColor, axisColor);

% panel c：把价格扫描下的国家净出口轨迹并入同一张图，避免单独做一张 robustness 图。
countryAx = axes('Parent', fig, 'Position', [0.040 0.11 0.91 0.39]);
plotCountryYearSupplyMixResponse(countryAx, countryNetExportByYear, ...
    offshoreSupply, outsideImport, sensitivityCountryList, sensitivityYearList, ...
    sensitivityPriceMWhList, literatureAnchorPrice, blueColor, orangeColor, axisColor);

outputPdf = fullfile(figureDir, 'fig_nc_lcoh_counterfactual.pdf');
outputPng = fullfile(figureDir, 'fig_nc_lcoh_counterfactual.png');
outputManuscriptPdf = fullfile(manuscriptFigureDir, 'fig_nc_lcoh_counterfactual.pdf');

exportgraphics(fig, outputPdf, 'ContentType', 'image', 'Resolution', 600);
exportgraphics(fig, outputPng, 'Resolution', 600);
copyfile(outputPdf, outputManuscriptPdf);
close(fig)
end

function valueMatrix = buildNetExportMatrix(countryTable, yearList, scenarioList, countryList)
% 生成国家净出口矩阵：行是国家，列是 year-scenario 组合。

valueMatrix = zeros(numel(countryList), numel(yearList) * numel(scenarioList));
for iCountry = 1:numel(countryList)
    for iYear = 1:numel(yearList)
        for iScenario = 1:numel(scenarioList)
            columnIndex = (iYear - 1) * numel(scenarioList) + iScenario;
            rowIndex = countryTable.Year == yearList(iYear) ...
                & countryTable.Scenario == scenarioList(iScenario) ...
                & countryTable.Country == countryList(iCountry);
            valueMatrix(iCountry,columnIndex) = countryTable.NetExport_TWh(rowIndex);
        end
    end
end
end

function countryOrder = sortCountriesBy2050Integrated(valueMatrix, countryList)
% 按 2050 integrated 净出口排序，让主要出口国自然出现在 heatmap 顶部。

integrated2050Column = 6;
[~, countryOrder] = sort(valueMatrix(:,integrated2050Column), 'descend');
countryOrder = countryOrder(:).';
countryOrder = countryOrder(countryList(countryOrder) ~= "ITN");
end

function [topExporter, topExport, residualImport] = buildSummaryMatrices(summaryTable, ...
    yearList, scenarioList)
% 提取每个年份和模型的最大净出口国、对应净出口、外部进口缺口。

topExporter = strings(numel(yearList), numel(scenarioList));
topExport = zeros(numel(yearList), numel(scenarioList));
residualImport = zeros(numel(yearList), numel(scenarioList));

for iYear = 1:numel(yearList)
    for iScenario = 1:numel(scenarioList)
        rowIndex = summaryTable.Year == yearList(iYear) ...
            & summaryTable.Scenario == scenarioList(iScenario);
        topExporter(iYear,iScenario) = summaryTable.TopNetExporter(rowIndex);
        topExport(iYear,iScenario) = summaryTable.TopNetExport_TWh(rowIndex);
        residualImport(iYear,iScenario) = summaryTable.InternationalImport_TWh(rowIndex);
    end
end
end

function plotCountryBalanceHeatmap(ax, valueMatrix, countryLabel, yearList, ...
    scenarioLabel, topExporter, topExport, axisColor)
% 画国家净出口 heatmap。蓝色表示净出口，红色表示净进口。

axes(ax);
maxAbsValue = ceil(max(abs(valueMatrix), [], 'all') / 50) * 50;
imagesc(valueMatrix);
colormap(ax, makeDivergingMap(256));
clim(ax, [-maxAbsValue maxAbsValue]);
hold on

for splitX = [2.5 4.5]
    xline(splitX, '-', 'Color', [1 1 1], 'LineWidth', 2.2);
    xline(splitX, '-', 'Color', [0.78 0.78 0.78], 'LineWidth', 0.8);
end
for iRow = 1:size(valueMatrix,1)
    yline(iRow + 0.5, '-', 'Color', [1 1 1], 'LineWidth', 0.6);
end

set(ax, 'XTick', 1:6, 'XTickLabel', repmat(["Cost","Int."], 1, numel(yearList)), ...
    'YTick', 1:numel(countryLabel), 'YTickLabel', countryLabel, ...
    'TickLength', [0 0], 'YDir', 'reverse', 'FontName', 'Arial', ...
    'FontSize', 12, 'LineWidth', 0.8, 'XColor', axisColor, 'YColor', axisColor, ...
    'Box', 'off');
xtickangle(ax, 0);
text(ax, 0, 1.11, 'a', ...
    'Units', 'normalized', 'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'bottom', 'FontName', 'Arial', ...
    'FontSize', 14, 'FontWeight', 'bold', 'Color', axisColor, ...
    'Clipping', 'off');

for iYear = 1:numel(yearList)
    yearX = (((iYear - 1) * 2 + 1.5) - 0.5) / 6;
    text(ax, yearX, 1.03, string(yearList(iYear)), ...
        'Units', 'normalized', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
        'FontName', 'Arial', 'FontSize', 13, 'FontWeight', 'bold', ...
        'Color', axisColor, 'Clipping', 'off');
end

highlightLeadingExporter(ax, valueMatrix);
labelLeadingExporter(ax, yearList, scenarioLabel, topExporter, topExport, axisColor);

colorBar = colorbar(ax, 'Location', 'eastoutside');
colorBar.Label.String = 'Net export (TWh yr^{-1})';
colorBar.Label.FontName = 'Arial';
colorBar.Label.FontSize = 12.5;
colorBar.FontName = 'Arial';
colorBar.FontSize = 11.5;
end

function labelLeadingExporter(ax, yearList, scenarioLabel, topExporter, topExport, axisColor)
% 把原 panel b 的 leading-exporter 信息压缩到对应黑框内，并用折线箭头指向。

for iYear = 1:numel(yearList)
    yearCenter = (iYear - 1) * numel(scenarioLabel) + 1.5;
    for iScenario = 1:numel(scenarioLabel)
        columnIndex = (iYear - 1) * numel(scenarioLabel) + iScenario;
        rowIndex = find(topExporter(iYear,iScenario) == ax.YTickLabel, 1);
        plot(ax, [yearCenter columnIndex columnIndex], ...
            [0.08 0.08 rowIndex - 0.50], '-', ...
            'Color', [0.55 0.55 0.55], 'LineWidth', 0.7, ...
            'Clipping', 'off', 'HandleVisibility', 'off');
        plot(ax, columnIndex, rowIndex - 0.50, 'v', ...
            'MarkerSize', 3.5, 'MarkerFaceColor', [0.55 0.55 0.55], ...
            'MarkerEdgeColor', [0.55 0.55 0.55], ...
            'Clipping', 'off', 'HandleVisibility', 'off');
        text(ax, columnIndex, rowIndex, sprintf('%s %.0f', ...
            topExporter(iYear,iScenario), topExport(iYear,iScenario)), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
            'FontName', 'Arial', 'FontSize', 10, 'FontWeight', 'bold', ...
            'Color', axisColor, 'Clipping', 'on');
    end
end
end

function highlightLeadingExporter(ax, valueMatrix)
% 用细框标出每一列最大净出口国家，避免读者必须自己找最大值。

for iColumn = 1:size(valueMatrix,2)
    [~, rowIndex] = max(valueMatrix(:,iColumn));
    rectangle(ax, 'Position', [iColumn - 0.48, rowIndex - 0.48, 0.96, 0.96], ...
        'EdgeColor', [0.08 0.08 0.08], 'LineWidth', 1.2);
end
end

function plotResidualImport(ax, yearList, residualImport, blueColor, axisColor)
% 画 integrated model 暴露出的外部进口缺口。cost-only baseline 为零，不额外画成柱子。

axes(ax);
hold on
integratedImport = residualImport(:,2);
for iYear = 1:numel(yearList)
    plot([iYear iYear], [0 integratedImport(iYear)], '-', ...
        'Color', blueColor, 'LineWidth', 3.0);
    plot(iYear, integratedImport(iYear), 'o', 'MarkerSize', 7, ...
        'MarkerFaceColor', blueColor, 'MarkerEdgeColor', 'white', 'LineWidth', 0.8);
    text(iYear, integratedImport(iYear) + 10, sprintf('%.0f', integratedImport(iYear)), ...
        'HorizontalAlignment', 'center', 'FontName', 'Arial', 'FontSize', 8.5, ...
        'Color', axisColor);
end
set(ax, 'XTick', 1:numel(yearList), 'XTickLabel', string(yearList), ...
    'FontName', 'Arial', 'FontSize', 9.5, 'LineWidth', 0.8, ...
    'XColor', axisColor, 'YColor', axisColor, 'Box', 'off');
xlim(ax, [0.55 numel(yearList)+0.45]);
ylim(ax, [0 max(integratedImport) * 1.25 + 1]);
ylabel(ax, 'Outside import (TWh yr^{-1})');
title(ax, 'b  Residual outside imports', ...
    'FontSize', 11.5, 'FontWeight', 'normal', 'Color', axisColor);
grid(ax, 'on');
ax.GridAlpha = 0.14;
end

function colorMap = makeDivergingMap(nColor)
% 生成简洁的红-白-蓝发散色图，中心为零。

redColor = [0.68 0.13 0.18];
whiteColor = [0.97 0.97 0.95];
blueColor = [0.05 0.32 0.58];
nHalf = floor(nColor / 2);
lowerHalf = [linspace(redColor(1), whiteColor(1), nHalf)', ...
    linspace(redColor(2), whiteColor(2), nHalf)', ...
    linspace(redColor(3), whiteColor(3), nHalf)'];
upperHalf = [linspace(whiteColor(1), blueColor(1), nColor - nHalf)', ...
    linspace(whiteColor(2), blueColor(2), nColor - nHalf)', ...
    linspace(whiteColor(3), blueColor(3), nColor - nHalf)'];
colorMap = [lowerHalf; upperHalf];
end

function literatureAnchorPrice = makeLiteratureAnchorPrices(projectRoot, yearList)
% 用 IRENA 2050 delivered-import/domestic-cost ratio 换算各年份锚点。

rankTable = readtable(fullfile(projectRoot, 'results', 'tables', ...
    'NC_lcoh_rank_table.csv'), 'TextType', 'string');
anchorRatio = 43 / 33;
literatureAnchorPrice = zeros(numel(yearList), 1);
for iYear = 1:numel(yearList)
    rowIndex = rankTable.Year == yearList(iYear) ...
        & ismember(rankTable.Country, ["GB", "IE"]);
    literatureAnchorPrice(iYear) = mean(rankTable.MarginalLCOH_EURperMWh(rowIndex)) ...
        * anchorRatio;
end
end

function valueMatrix = makeSummaryMatrix(summaryTable, yearList, priceList, variableName)
% 取 year-price summary 矩阵。

valueMatrix = zeros(numel(yearList), numel(priceList));
for iYear = 1:numel(yearList)
    for iPrice = 1:numel(priceList)
        rowIndex = summaryTable.Year == yearList(iYear) ...
            & abs(summaryTable.ImportCost_EURperKgH2 - priceList(iPrice)) < 1e-6;
        valueMatrix(iYear,iPrice) = summaryTable.(variableName)(rowIndex);
    end
end
end

function valueMatrix = getCountryNetExport(countryTable, year, priceList, countryList)
% 取指定年份、价格和国家的净出口矩阵。

valueMatrix = zeros(numel(countryList), numel(priceList));
for iCountry = 1:numel(countryList)
    for iPrice = 1:numel(priceList)
        rowIndex = countryTable.Year == year ...
            & abs(countryTable.ImportCost_EURperKgH2 - priceList(iPrice)) < 1e-6 ...
            & countryTable.Country == countryList(iCountry);
        valueMatrix(iCountry,iPrice) = countryTable.NetExport_TWh(rowIndex);
    end
end
end

function valueArray = getCountryNetExportByYear(countryTable, yearList, priceList, countryList)
% 取所有年份、价格和国家的净出口矩阵。

valueArray = zeros(numel(countryList), numel(priceList), numel(yearList));
for iYear = 1:numel(yearList)
    valueArray(:,:,iYear) = getCountryNetExport(countryTable, yearList(iYear), ...
        priceList, countryList);
end
end

function plotCarbonOwnershipCurve(ax, priceMWhList, externalCarbon, europeCarbon, ...
    yearList, blueColor, axisColor)
% 画三个年份碳减排归因在外部进口价格扫描下的响应。

axes(ax);
hold on
offshoreShare = 100 .* europeCarbon ./ (externalCarbon + europeCarbon);
yearColor = [0.45 0.61 0.76; 0.17 0.44 0.70; blueColor];
yearWidth = 2.1;
xSmooth = linspace(min(priceMWhList), max(priceMWhList), 600);
thresholdY = 103;
for yLine = 25:25:100
    yline(ax, yLine, '-', 'Color', [0.88 0.88 0.88], 'LineWidth', 0.8);
end
for iYear = 1:numel(yearList)
    yRaw = cummax(offshoreShare(iYear,:));
    yPlot = smoothdata(yRaw, 'movmean', 5);
    yPlot([1 end]) = yRaw([1 end]);
    yPlot = cummax(yPlot);
    ySmooth = interp1(priceMWhList, yPlot, xSmooth, 'pchip');
    transitionStart = firstCrossingPrice(xSmooth, ySmooth, 25);
    transitionMid = firstCrossingPrice(xSmooth, ySmooth, 50);
    transitionEnd = firstCrossingPrice(xSmooth, ySmooth, 75);
    fill(ax, [transitionStart transitionEnd transitionEnd transitionStart], ...
        [0 0 100 100], yearColor(iYear,:), ...
        'FaceAlpha', 0.08, 'EdgeColor', 'none');
    plot(ax, xSmooth, ySmooth, '-', ...
        'Color', yearColor(iYear,:), 'LineWidth', yearWidth, ...
        'DisplayName', num2str(yearList(iYear)));
    plot(ax, [transitionMid transitionMid], [0 50], ':', ...
        'Color', 0.72 .* yearColor(iYear,:) + 0.28, 'LineWidth', 1.0);
    plot(ax, [transitionStart transitionEnd], [thresholdY thresholdY], '-', ...
        'Color', yearColor(iYear,:), 'LineWidth', 1.4);
    plot(ax, transitionMid, thresholdY, 'v', ...
        'MarkerFaceColor', yearColor(iYear,:), ...
        'MarkerEdgeColor', 'white', 'MarkerSize', 5.5);
    text(ax, transitionMid, thresholdY + 1.5, num2str(yearList(iYear)), ...
        'FontName', 'Arial', 'FontSize', 10, 'Color', yearColor(iYear,:), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
    text(ax, 107.5, ySmooth(end), num2str(yearList(iYear)), ...
        'FontName', 'Arial', 'FontSize', 11.5, 'Color', yearColor(iYear,:), ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
end
set(ax, 'XTick', 30:15:105, ...
    'XTickLabel', {'30', '45', '60', '', '90', '105'}, ...
    'TickLabelInterpreter', 'none', ...
    'YTick', 0:25:100, 'FontName', 'Arial', 'FontSize', 12, ...
    'LineWidth', 0.9, 'XColor', axisColor, 'Box', 'off');
xlim(ax, [28 112]);
ylim(ax, [0 106]);
text(ax, 75, -4.0, '75', 'FontName', 'Arial', 'FontSize', 12, ...
    'Color', axisColor, 'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'top', 'Clipping', 'off');
xlabel(ax, 'Imported hydrogen price (€ MWh^{-1})', 'FontSize', 12.5);
ylabel(ax, 'European offshore attribution (%)', 'FontSize', 12.5);
text(ax, 0, 1.04, 'b', 'Units', 'normalized', ...
    'FontName', 'Arial', 'FontSize', 14, 'FontWeight', 'bold', ...
    'Color', axisColor, 'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'bottom');
ax.Layer = 'top';
end

function price = firstCrossingPrice(xValue, yValue, target)
% 线性插值读取曲线第一次跨过指定占比的位置。

crossIndex = find(yValue >= target, 1, 'first');
x0 = xValue(crossIndex - 1);
x1 = xValue(crossIndex);
y0 = yValue(crossIndex - 1);
y1 = yValue(crossIndex);
price = x0 + (target - y0) .* (x1 - x0) ./ (y1 - y0);
end

function plotCountryYearSupplyMixResponse(ax, countryNetExportByYear, ...
    offshoreSupply, outsideImport, countryList, yearList, priceMWhList, ...
    literatureAnchorPrice, blueColor, orangeColor, axisColor)
% 画所有国家、所有年份在外部价格扫描下的净出口响应。

axes(ax);
hold on
priceMask = priceMWhList >= 30 & priceMWhList <= 105;
priceNow = priceMWhList(priceMask);
netExport = countryNetExportByYear(:,priceMask,:);
rowPosition = 1:numel(countryList);
yearOffset = linspace(-0.20, 0.20, numel(yearList));
trajectoryWidth = 1.8;
yearMarker = {'o', 's', '^'};
priceColorMap = makePriceColorMap();
priceRange = [min(priceNow) max(priceNow)];

for iCountry = 1:(numel(countryList) - 1)
    yline(ax, iCountry + 0.5, '-', 'Color', [0.88 0.88 0.88], ...
        'LineWidth', 0.7, 'HandleVisibility', 'off');
end

for iCountry = 1:numel(countryList)
    for iYear = 1:numel(yearList)
        yNow = rowPosition(iCountry) + yearOffset(iYear);
        xNow = squeeze(netExport(iCountry,:,iYear));
        drawGradientTrajectory(ax, xNow, yNow, priceNow, trajectoryWidth, ...
            priceColorMap, priceRange);
        plot(ax, xNow(1), yNow, yearMarker{iYear}, 'MarkerSize', 4.8, ...
            'MarkerFaceColor', valueToColor(priceNow(1), priceRange, priceColorMap), ...
            'MarkerEdgeColor', 'white', 'LineWidth', 0.4, 'HandleVisibility', 'off');
        plot(ax, xNow(end), yNow, yearMarker{iYear}, 'MarkerSize', 4.8, ...
            'MarkerFaceColor', valueToColor(priceNow(end), priceRange, priceColorMap), ...
            'MarkerEdgeColor', 'white', 'LineWidth', 0.4, 'HandleVisibility', 'off');
        anchorPrice = literatureAnchorPrice(iYear);
        if anchorPrice >= min(priceNow) && anchorPrice <= max(priceNow)
            anchorX = interp1(priceNow, xNow, anchorPrice, 'linear');
            plot(ax, anchorX * [1 1], yNow + [-0.13 0.13], '-', ...
                'Color', 'white', 'LineWidth', 2.4, 'HandleVisibility', 'off');
            plot(ax, anchorX * [1 1], yNow + [-0.13 0.13], '-', ...
                'Color', axisColor, 'LineWidth', 1.2, 'HandleVisibility', 'off');
        end
    end
end

xline(0, '-', 'Color', [0.20 0.20 0.20], 'LineWidth', 0.9, ...
    'HandleVisibility', 'off');
yearLegend = gobjects(numel(yearList), 1);
for iYear = 1:numel(yearList)
    yearLegend(iYear) = plot(NaN, NaN, '-', 'Color', axisColor, ...
        'LineWidth', trajectoryWidth, 'Marker', yearMarker{iYear}, ...
        'MarkerFaceColor', axisColor, 'MarkerEdgeColor', axisColor, ...
        'MarkerSize', 5.2, 'DisplayName', num2str(yearList(iYear)));
end
anchorLegend = plot(NaN, NaN, '|', 'Color', axisColor, ...
    'LineWidth', 1.4, 'MarkerSize', 8.5, ...
    'DisplayName', 'Projected imported hydrogen price');
colormap(ax, priceColorMap);
clim(ax, priceRange);
colorbarHandle = colorbar(ax, 'Location', 'eastoutside');
colorbarHandle.Ticks = 30:15:105;
colorbarHandle.Label.String = 'Imported hydrogen price range (€ MWh^{-1})';
colorbarHandle.Label.FontName = 'Arial';
colorbarHandle.Label.FontSize = 12.5;
colorbarHandle.FontSize = 11.5;
set(ax, 'YTick', rowPosition, 'YTickLabel', countryList, ...
    'YDir', 'reverse', 'FontName', 'Arial', 'FontSize', 12, ...
    'LineWidth', 0.9, 'XColor', axisColor, 'YColor', axisColor, 'Box', 'off');
xlim(ax, [-260 185]);
set(ax, 'XTick', [-250 -150 -50 50 150], ...
    'XTickLabel', {'-250', '-150', '-50', '50', '150'});
ylim(ax, [0.35 numel(countryList) + 0.75]);
xlabel(ax, 'Net export (TWh yr^{-1})', 'FontSize', 12.5);
text(ax, 0, 1.04, 'c', 'Units', 'normalized', ...
    'FontName', 'Arial', 'FontSize', 14, 'FontWeight', 'bold', ...
    'Color', axisColor, 'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'bottom');
legend(ax, [yearLegend; anchorLegend], 'Location', 'northwest', 'Box', 'off', ...
    'Orientation', 'horizontal', 'FontName', 'Arial', 'FontSize', 11);
grid(ax, 'off');
end

function priceColorMap = makePriceColorMap()
% 与 Fig. 3 一致的蓝-青-绿-黄-橙红连续色标。

anchorColor = [
    0.20 0.30 0.75
    0.20 0.63 0.82
    0.52 0.82 0.64
    0.96 0.78 0.38
    0.92 0.38 0.25
    ];
xAnchor = linspace(0, 1, size(anchorColor, 1));
xQuery = linspace(0, 1, 256);
priceColorMap = interp1(xAnchor, anchorColor, xQuery, 'linear');
end

function colorNow = valueToColor(valueNow, valueRange, priceColorMap)
% 用扫描价格决定线段颜色。

fraction = (valueNow - valueRange(1)) / diff(valueRange);
fraction = max(0, min(1, fraction));
colorIndex = 1 + fraction * (size(priceColorMap, 1) - 1);
colorNow = interp1(1:size(priceColorMap, 1), priceColorMap, colorIndex);
end

function drawGradientTrajectory(ax, xValues, yValue, priceValues, lineWidth, ...
    priceColorMap, priceRange)
% 按价格扫描区间画渐变线。

for iPoint = 1:(numel(xValues) - 1)
    colorNow = valueToColor(mean(priceValues(iPoint:iPoint + 1)), priceRange, priceColorMap);
    plot(ax, xValues(iPoint:iPoint + 1), yValue * [1 1], '-', ...
        'Color', colorNow, 'LineWidth', lineWidth, 'HandleVisibility', 'off');
end
end
