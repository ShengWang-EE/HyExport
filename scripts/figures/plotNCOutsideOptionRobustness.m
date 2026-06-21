function plotNCOutsideOptionRobustness(projectRoot)
% Plot the outside-option threshold scan for the NC story.
%
% 目的：
% 把外部低碳氢/氨进口价格扫描整理成更接近 Nature Communications / Nature Energy
% 风格的主文候选图。图件表达的是阈值：很低外部进口价格会挤出欧洲 offshore
% supply；价格高于约 4 EUR kg-H2-eq 后，Ireland/GB strategic-exporter 结论恢复。
%
% 入口：
% - 统一从 main.m 调用。
%
% 输出：
% - results/figures/fig_nc_outside_option_robustness.pdf
% - results/figures/fig_nc_outside_option_robustness.png
% - manuscript/figs/fig_nc_outside_option_robustness.pdf

projectRoot = setupHyExport(projectRoot);

tableFile = fullfile(projectRoot, 'results', 'tables', 'NC_outside_option_sensitivity.csv');
countryTableFile = fullfile(projectRoot, 'results', 'tables', ...
    'NC_outside_option_sensitivity_country.csv');
figureDir = fullfile(projectRoot, 'results', 'figures');
manuscriptFigureDir = fullfile(projectRoot, 'manuscript', 'figs');
if ~exist(figureDir, 'dir')
    mkdir(figureDir);
end
if ~exist(manuscriptFigureDir, 'dir')
    mkdir(manuscriptFigureDir);
end

summaryTable = readtable(tableFile, 'TextType', 'string');
countryTable = readtable(countryTableFile, 'TextType', 'string');
yearList = unique(summaryTable.Year, 'stable');
priceList = unique(summaryTable.ImportCost_EURperKgH2, 'stable');

headlineYear = 2050;
summary2050 = summaryTable(summaryTable.Year == headlineYear,:);

offshoreSupply = makeSummaryMatrix(summaryTable, yearList, priceList, ...
    'EuropeanOffshoreSupply_TWh');
outsideImport = makeSummaryMatrix(summaryTable, yearList, priceList, ...
    'InternationalImport_TWh');
europeCarbon = summary2050.EuropeanOffshoreCarbonContribution_Mt;
externalCarbon = summary2050.TotalCarbonReduction_Mt - europeCarbon;

countryList = unique(countryTable.Country(countryTable.Country ~= "ITN"), 'stable');
countryNetExport = getCountryNetExport(countryTable, headlineYear, priceList, countryList);
[~, price35Index] = min(abs(priceList - 3.5));
[~, countryOrder] = sort(countryNetExport(:, price35Index), 'descend');
countryList = countryList(countryOrder);
countryNetExport = countryNetExport(countryOrder, :);

blueColor = [0.04 0.30 0.55];
orangeColor = [0.78 0.34 0.12];
axisColor = [0.18 0.18 0.18];

fig = figure('Color', 'white', 'Position', [100 100 1180 820]);

supplyAx = axes('Parent', fig, 'Position', [0.08 0.58 0.42 0.31]);
plotSupplyRegimeRibbons(supplyAx, outsideImport, offshoreSupply, yearList, ...
    priceList, blueColor, orangeColor, axisColor);

carbonAx = axes('Parent', fig, 'Position', [0.61 0.58 0.31 0.31]);
plotCarbonOwnershipCurve(carbonAx, priceList, externalCarbon, europeCarbon, ...
    blueColor, orangeColor, axisColor);

countryAx = axes('Parent', fig, 'Position', [0.11 0.13 0.74 0.32]);
plotCountryThresholdSlope(countryAx, countryNetExport, countryList, priceList, ...
    blueColor, orangeColor, axisColor);

outputPdf = fullfile(figureDir, 'fig_nc_outside_option_robustness.pdf');
outputPng = fullfile(figureDir, 'fig_nc_outside_option_robustness.png');
exportgraphics(fig, outputPdf, 'ContentType', 'vector');
exportgraphics(fig, outputPng, 'Resolution', 600);
copyfile(outputPdf, fullfile(manuscriptFigureDir, 'fig_nc_outside_option_robustness.pdf'));
close(fig)
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

function plotSupplyRegimeRibbons(ax, outsideImport, offshoreSupply, yearList, ...
    priceList, blueColor, orangeColor, axisColor)
% 用组成带展示不同年份下外部进口和欧洲 offshore supply 的阈值切换。

axes(ax);
hold on
rowHeight = 0.72;
totalSupply = outsideImport + offshoreSupply;
offshoreFrac = offshoreSupply ./ totalSupply;
[~, boundaryIndex] = min(abs(offshoreFrac(end,:) - 0.5));
boundaryPrice = priceList(boundaryIndex);
for iYear = 1:numel(yearList)
    yBase = numel(yearList) - iYear + 1;
    yLow = yBase - rowHeight/2;
    yHigh = yBase + rowHeight/2;
    ySplit = yLow + (1 - offshoreFrac(iYear,:)) * rowHeight;
    ySplit = ySplit(:);
    patch(ax, [priceList; flip(priceList)], ...
        [yLow * ones(size(priceList)); flip(ySplit)], ...
        orangeColor, 'FaceAlpha', 0.94, 'EdgeColor', 'none', ...
        'HandleVisibility', 'off');
    patch(ax, [priceList; flip(priceList)], ...
        [ySplit; yHigh * ones(size(priceList))], ...
        blueColor, 'FaceAlpha', 0.96, 'EdgeColor', 'none', ...
        'HandleVisibility', 'off');
    plot(ax, priceList, ySplit, '-', 'Color', [1 1 1], 'LineWidth', 1.0, ...
        'HandleVisibility', 'off');
    text(6.34, yBase, sprintf('%.0f TWh', totalSupply(iYear,end)), ...
        'FontName', 'Arial', 'FontSize', 8.8, 'Color', axisColor, ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
end
xline(boundaryPrice, '-', 'Color', [0.18 0.18 0.18], 'LineWidth', 1.2, ...
    'HandleVisibility', 'off');
text(boundaryPrice + 0.04, numel(yearList) + 0.54, 'boundary', ...
    'FontName', 'Arial', 'FontSize', 8.8, 'Color', axisColor, ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
plot(NaN, NaN, 's', 'MarkerSize', 8, 'MarkerFaceColor', orangeColor, ...
    'MarkerEdgeColor', 'none', 'DisplayName', 'Outside option');
plot(NaN, NaN, 's', 'MarkerSize', 8, 'MarkerFaceColor', blueColor, ...
    'MarkerEdgeColor', 'none', 'DisplayName', 'European offshore');
set(ax, 'XTick', 2:1:6, 'XTickLabel', string(2:1:6), ...
    'YTick', 1:numel(yearList), 'YTickLabel', flip(string(yearList)), ...
    'FontName', 'Arial', 'FontSize', 10, 'LineWidth', 0.9, ...
    'XColor', axisColor, 'YColor', axisColor, 'Box', 'off');
xlim(ax, [1.92 6.65]);
ylim(ax, [0.45 numel(yearList) + 0.75]);
xlabel(ax, 'Outside option (EUR kg^{-1} H_2-eq.)');
ylabel(ax, 'Model year');
title(ax, 'a  Supply regime shifts from imports to offshore', ...
    'FontSize', 11.5, 'FontWeight', 'normal', 'Color', axisColor);
legend(ax, 'Location', 'southoutside', 'Orientation', 'horizontal', ...
    'Box', 'off', 'FontName', 'Arial', 'FontSize', 9.2);
end

function plotCarbonOwnershipCurve(ax, priceList, externalCarbon, europeCarbon, ...
    blueColor, orangeColor, axisColor)
% 画 2050 碳减排归因由外部进口转向欧洲 offshore 的 ownership curve。

axes(ax);
hold on
offshoreShare = 100 .* europeCarbon ./ (externalCarbon + europeCarbon);
upperBound = 100 .* ones(size(priceList));
patch(ax, [priceList; flip(priceList)], [offshoreShare; flip(upperBound)], ...
    orangeColor, 'FaceAlpha', 0.28, 'EdgeColor', 'none', ...
    'HandleVisibility', 'off');
areaHandle = area(ax, priceList, offshoreShare, ...
    'FaceColor', blueColor, 'FaceAlpha', 0.90, 'EdgeColor', blueColor, ...
    'LineWidth', 1.2);
areaHandle.HandleVisibility = 'off';
[~, boundaryIndex] = min(abs(offshoreShare - 50));
boundaryPrice = priceList(boundaryIndex);
plot(ax, priceList, offshoreShare, 'o', 'MarkerSize', 3.0, ...
    'MarkerFaceColor', blueColor, 'MarkerEdgeColor', 'white', ...
    'LineWidth', 0.6, 'HandleVisibility', 'off');
xline(boundaryPrice, '-', 'Color', [0.18 0.18 0.18], 'LineWidth', 1.2, ...
    'HandleVisibility', 'off');
plot(NaN, NaN, 's', 'MarkerSize', 8, 'MarkerFaceColor', orangeColor, ...
    'MarkerEdgeColor', 'none', 'DisplayName', 'External share');
plot(NaN, NaN, 's', 'MarkerSize', 8, 'MarkerFaceColor', blueColor, ...
    'MarkerEdgeColor', 'none', 'DisplayName', 'European offshore share');
set(ax, 'XTick', 2:1:6, 'XTickLabel', string(2:1:6), ...
    'YTick', 0:25:100, 'FontName', 'Arial', 'FontSize', 10, ...
    'LineWidth', 0.9, 'XColor', axisColor, 'Box', 'off');
xlim(ax, [1.92 6.08]);
ylim(ax, [0 100]);
xlabel(ax, 'Delivered outside option (EUR kg^{-1} H_2-eq.)');
ylabel(ax, 'European offshore attribution (%)');
title(ax, 'b  2050 mitigation value changes ownership', ...
    'FontSize', 11.5, 'FontWeight', 'normal', 'Color', axisColor);
legend(ax, 'Location', 'northoutside', 'Orientation', 'horizontal', ...
    'Box', 'off', 'FontName', 'Arial', 'FontSize', 8.8);
grid(ax, 'on');
ax.GridAlpha = 0.12;
end

function plotCountryThresholdSlope(ax, countryNetExport, countryList, priceList, ...
    blueColor, orangeColor, axisColor)
% 画所有国家在外部价格阈值两侧的净出口翻转。

axes(ax);
hold on
lowPrice = 3.0;
highPrice = 3.5;
[~, lowIndex] = min(abs(priceList - lowPrice));
[~, highIndex] = min(abs(priceList - highPrice));
lowValue = countryNetExport(:, lowIndex);
highValue = countryNetExport(:, highIndex);
rowPosition = 1:numel(countryList);
for iCountry = 1:numel(countryList)
    lineColor = [0.65 0.65 0.65];
    if highValue(iCountry) > 0
        lineColor = [0.38 0.55 0.66];
    end
    plot([lowValue(iCountry), highValue(iCountry)], ...
        [rowPosition(iCountry), rowPosition(iCountry)], '-', ...
        'Color', lineColor, 'LineWidth', 1.5);
    plot(lowValue(iCountry), rowPosition(iCountry), 'o', 'MarkerSize', 5.8, ...
        'MarkerFaceColor', orangeColor, 'MarkerEdgeColor', 'white', 'LineWidth', 0.5);
    plot(highValue(iCountry), rowPosition(iCountry), 'o', 'MarkerSize', 5.8, ...
        'MarkerFaceColor', blueColor, 'MarkerEdgeColor', 'white', 'LineWidth', 0.5);
end
xline(0, '-', 'Color', [0.20 0.20 0.20], 'LineWidth', 0.9);
text(-102, 0.55, sprintf('%.1f EUR kg^{-1}', lowPrice), ...
    'FontName', 'Arial', 'FontSize', 9.4, 'Color', orangeColor, ...
    'HorizontalAlignment', 'left');
text(101, 0.55, sprintf('%.1f EUR kg^{-1}', highPrice), ...
    'FontName', 'Arial', 'FontSize', 9.4, 'Color', blueColor, ...
    'HorizontalAlignment', 'left');
labelCountry = ismember(countryList, ["GB", "IE", "DK", "DE", "FR", "ES"]);
for iCountry = find(labelCountry)'
    text(highValue(iCountry) + 7, rowPosition(iCountry), ...
        sprintf('%s %.0f', countryList(iCountry), highValue(iCountry)), ...
        'FontName', 'Arial', 'FontSize', 8.4, 'Color', axisColor, ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
end
set(ax, 'YTick', rowPosition, 'YTickLabel', countryList, ...
    'YDir', 'reverse', 'FontName', 'Arial', 'FontSize', 9.4, ...
    'LineWidth', 0.9, 'XColor', axisColor, 'YColor', axisColor, 'Box', 'off');
xlim(ax, [-270 190]);
ylim(ax, [0.35 numel(countryList) + 0.75]);
xlabel(ax, '2050 net export (TWh yr^{-1})');
title(ax, 'c  Export roles flip across the price boundary', ...
    'FontSize', 11.5, 'FontWeight', 'normal', 'Color', axisColor);
grid(ax, 'on');
ax.GridAlpha = 0.10;
end
