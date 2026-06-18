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

yearList = [2030 2040 2050];
scenarioList = ["LCOH-only baseline", "Integrated model"];
scenarioLabel = ["Cost-only", "Integrated"];
europeCountry = ["BE","DK","FR","DE","IE","NL","NO","PT","ES","SE","GB"];

netExportMatrix = buildNetExportMatrix(countryTable, yearList, scenarioList, europeCountry);
countryOrder = sortCountriesBy2050Integrated(netExportMatrix, europeCountry);
netExportMatrix = netExportMatrix(countryOrder,:);
countryLabel = europeCountry(countryOrder);

[topExporter, topExport, residualImport] = buildSummaryMatrices(summaryTable, ...
    yearList, scenarioList);

blueColor = [0.02 0.24 0.47];
greyColor = [0.60 0.60 0.60];
axisColor = [0.18 0.18 0.18];

fig = figure('Color', 'white', 'Position', [100 100 1240 800]);

% panel a：国家净出口平衡是主证据，模仿能源系统文章常用的 country-balance heatmap。
heatmapAx = axes('Parent', fig, 'Position', [0.08 0.16 0.56 0.60]);
plotCountryBalanceHeatmap(heatmapAx, netExportMatrix, countryLabel, yearList, ...
    axisColor);

% panel b：把 heatmap 中最重要的 ranking change 提取出来，减少读者负担。
switchAx = axes('Parent', fig, 'Position', [0.71 0.54 0.23 0.27]);
plotTopExporterSwitch(switchAx, yearList, scenarioLabel, topExporter, topExport, ...
    greyColor, blueColor, axisColor);

% panel c：integrated model 显示 residual outside-import need，这是 cost-only view 隐藏掉的缺口。
importAx = axes('Parent', fig, 'Position', [0.71 0.16 0.23 0.27]);
plotResidualImport(importAx, yearList, residualImport, blueColor, axisColor);

outputPdf = fullfile(figureDir, 'fig_nc_lcoh_counterfactual.pdf');
outputPng = fullfile(figureDir, 'fig_nc_lcoh_counterfactual.png');
outputManuscriptPdf = fullfile(manuscriptFigureDir, 'fig_nc_lcoh_counterfactual.pdf');

exportgraphics(fig, outputPdf, 'ContentType', 'vector');
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

function plotCountryBalanceHeatmap(ax, valueMatrix, countryLabel, yearList, axisColor)
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
    'FontSize', 9.5, 'LineWidth', 0.8, 'XColor', axisColor, 'YColor', axisColor, ...
    'Box', 'off');
xtickangle(ax, 0);
text(ax, 0, 1.11, 'a  Country net-export balance', ...
    'Units', 'normalized', 'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'bottom', 'FontName', 'Arial', ...
    'FontSize', 11.5, 'FontWeight', 'normal', 'Color', axisColor, ...
    'Clipping', 'off');

for iYear = 1:numel(yearList)
    yearX = (((iYear - 1) * 2 + 1.5) - 0.5) / 6;
    text(ax, yearX, 1.03, string(yearList(iYear)), ...
        'Units', 'normalized', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
        'FontName', 'Arial', 'FontSize', 10.5, 'FontWeight', 'bold', ...
        'Color', axisColor, 'Clipping', 'off');
end

highlightLeadingExporter(ax, valueMatrix);

colorBar = colorbar(ax, 'Location', 'eastoutside');
colorBar.Label.String = 'Net export (TWh yr^{-1})';
colorBar.Label.FontName = 'Arial';
colorBar.FontName = 'Arial';
colorBar.FontSize = 9;
end

function highlightLeadingExporter(ax, valueMatrix)
% 用细框标出每一列最大净出口国家，避免读者必须自己找最大值。

for iColumn = 1:size(valueMatrix,2)
    [~, rowIndex] = max(valueMatrix(:,iColumn));
    rectangle(ax, 'Position', [iColumn - 0.48, rowIndex - 0.48, 0.96, 0.96], ...
        'EdgeColor', [0.08 0.08 0.08], 'LineWidth', 1.2);
end
end

function plotTopExporterSwitch(ax, yearList, scenarioLabel, topExporter, topExport, ...
    greyColor, blueColor, axisColor)
% 把 top exporter 的变化用简洁的左右对照表画出来。

axes(ax);
axis(ax, 'off');
hold on
xlim(ax, [0 1]);
ylim(ax, [0.4 numel(yearList)+0.8]);
title(ax, 'b  Leading exporter switches', ...
    'FontSize', 11.5, 'FontWeight', 'normal', 'Color', axisColor);

text(0.18, numel(yearList)+0.48, scenarioLabel(1), 'HorizontalAlignment', 'center', ...
    'FontName', 'Arial', 'FontSize', 9.5, 'Color', greyColor);
text(0.82, numel(yearList)+0.48, scenarioLabel(2), 'HorizontalAlignment', 'center', ...
    'FontName', 'Arial', 'FontSize', 9.5, 'Color', blueColor);

for iYear = 1:numel(yearList)
    yValue = numel(yearList) - iYear + 1;
    text(0.00, yValue, string(yearList(iYear)), 'HorizontalAlignment', 'left', ...
        'FontName', 'Arial', 'FontSize', 9.5, 'Color', axisColor);
    plot([0.30 0.70], [yValue yValue], '-', 'Color', [0.82 0.82 0.82], ...
        'LineWidth', 0.8);
    text(0.24, yValue + 0.10, topExporter(iYear,1), 'HorizontalAlignment', 'center', ...
        'FontName', 'Arial', 'FontSize', 13, 'FontWeight', 'bold', 'Color', greyColor);
    text(0.76, yValue + 0.10, topExporter(iYear,2), 'HorizontalAlignment', 'center', ...
        'FontName', 'Arial', 'FontSize', 13, 'FontWeight', 'bold', 'Color', blueColor);
    text(0.24, yValue - 0.17, sprintf('%.0f', topExport(iYear,1)), ...
        'HorizontalAlignment', 'center', 'FontName', 'Arial', 'FontSize', 8.5, ...
        'Color', axisColor);
    text(0.76, yValue - 0.17, sprintf('%.0f', topExport(iYear,2)), ...
        'HorizontalAlignment', 'center', 'FontName', 'Arial', 'FontSize', 8.5, ...
        'Color', axisColor);
end
text(0.52, 0.48, 'TWh yr^{-1}', 'HorizontalAlignment', 'center', ...
    'FontName', 'Arial', 'FontSize', 8.5, 'Color', [0.45 0.45 0.45]);
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
title(ax, 'c  Residual outside imports', ...
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
