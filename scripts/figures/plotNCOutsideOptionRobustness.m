function plotNCOutsideOptionRobustness(projectRoot)
% Plot the international import-price sensitivity scan for the NC story.
%
% 目的：
% 把外部低碳氢/氨进口价格扫描整理成更接近 Nature Communications / Nature Energy
% 风格的主文候选图。图件表达的是进口价格压力测试下欧洲 offshore supply
% 和 Ireland/GB strategic-exporter 结论的稳定性。
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
priceKgList = unique(summaryTable.ImportCost_EURperKgH2, 'stable');
priceMWhList = round(unique(summaryTable.ImportCost_EURperMWh, 'stable'));
literatureAnchorPrice = makeLiteratureAnchorPrices(projectRoot, yearList);

headlineYear = 2050;
offshoreSupply = makeSummaryMatrix(summaryTable, yearList, priceKgList, ...
    'EuropeanOffshoreSupply_TWh');
outsideImport = makeSummaryMatrix(summaryTable, yearList, priceKgList, ...
    'InternationalImport_TWh');
europeCarbon = makeSummaryMatrix(summaryTable, yearList, priceKgList, ...
    'EuropeanOffshoreCarbonContribution_Mt');
totalCarbon = makeSummaryMatrix(summaryTable, yearList, priceKgList, ...
    'TotalCarbonReduction_Mt');
externalCarbon = totalCarbon - europeCarbon;

countryList = unique(countryTable.Country(countryTable.Country ~= "ITN"), 'stable');
countryNetExport2050 = getCountryNetExport(countryTable, headlineYear, priceKgList, countryList);
[~, price35Index] = min(abs(priceKgList - 3.5));
[~, countryOrder] = sort(countryNetExport2050(:, price35Index), 'descend');
countryList = countryList(countryOrder);
countryNetExportByYear = getCountryNetExportByYear(countryTable, yearList, ...
    priceKgList, countryList);

blueColor = [0.04 0.30 0.55];
orangeColor = [0.78 0.34 0.12];
axisColor = [0.18 0.18 0.18];

fig = figure('Color', 'white', 'Position', [100 100 1180 760]);

carbonAx = axes('Parent', fig, 'Position', [0.13 0.64 0.70 0.26]);
plotCarbonOwnershipCurve(carbonAx, priceMWhList, externalCarbon, europeCarbon, ...
    yearList, blueColor, axisColor);

countryAx = axes('Parent', fig, 'Position', [0.13 0.12 0.68 0.41]);
plotCountryYearSupplyMixResponse(countryAx, countryNetExportByYear, ...
    offshoreSupply, outsideImport, countryList, yearList, priceMWhList, ...
    literatureAnchorPrice, blueColor, orangeColor, axisColor);

outputPdf = fullfile(figureDir, 'fig_nc_outside_option_robustness.pdf');
outputPng = fullfile(figureDir, 'fig_nc_outside_option_robustness.png');
exportgraphics(fig, outputPdf, 'ContentType', 'image', 'Resolution', 600);
exportgraphics(fig, outputPng, 'Resolution', 600);
copyfile(outputPdf, fullfile(manuscriptFigureDir, 'fig_nc_outside_option_robustness.pdf'));
close(fig)
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

function plotSupplyRegimeRibbons(ax, outsideImport, offshoreSupply, yearList, ...
    priceMWhList, blueColor, orangeColor, axisColor)
% 用组成带展示不同年份下外部进口和欧洲 offshore supply 的份额变化。

axes(ax);
hold on
rowHeight = 0.72;
totalSupply = outsideImport + offshoreSupply;
offshoreFrac = offshoreSupply ./ totalSupply;
xDisplayMax = 105;
    for iYear = 1:numel(yearList)
    yBase = numel(yearList) - iYear + 1;
    yLow = yBase - rowHeight/2;
    yHigh = yBase + rowHeight/2;
    ySplit = yLow + (1 - offshoreFrac(iYear,:)) * rowHeight;
    ySplit = ySplit(:);
    patch(ax, [priceMWhList; flip(priceMWhList)], ...
        [yLow * ones(size(priceMWhList)); flip(ySplit)], ...
        orangeColor, 'FaceAlpha', 0.94, 'EdgeColor', 'none', ...
        'HandleVisibility', 'off');
    patch(ax, [priceMWhList; flip(priceMWhList)], ...
        [ySplit; yHigh * ones(size(priceMWhList))], ...
        blueColor, 'FaceAlpha', 0.96, 'EdgeColor', 'none', ...
        'HandleVisibility', 'off');
    plot(ax, priceMWhList, ySplit, '-', 'Color', [1 1 1], 'LineWidth', 1.0, ...
        'HandleVisibility', 'off');
    text(xDisplayMax + 7, yBase, sprintf('%.0f TWh', totalSupply(iYear,end)), ...
        'FontName', 'Arial', 'FontSize', 8.8, 'Color', axisColor, ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
end
    plot(NaN, NaN, 's', 'MarkerSize', 8, 'MarkerFaceColor', orangeColor, ...
        'MarkerEdgeColor', 'none', 'DisplayName', 'International imports');
plot(NaN, NaN, 's', 'MarkerSize', 8, 'MarkerFaceColor', blueColor, ...
    'MarkerEdgeColor', 'none', 'DisplayName', 'European offshore');
set(ax, 'XTick', 45:15:xDisplayMax, 'XTickLabel', string(45:15:xDisplayMax), ...
    'YTick', 1:numel(yearList), 'YTickLabel', flip(string(yearList)), ...
    'FontName', 'Arial', 'FontSize', 10, 'LineWidth', 0.9, ...
    'XColor', axisColor, 'YColor', axisColor, 'Box', 'off');
xlim(ax, [43 116]);
ylim(ax, [0.45 numel(yearList) + 0.75]);
xlabel(ax, 'International hydrogen-equivalent import price (€ MWh^{-1})');
ylabel(ax, 'Model year');
    title(ax, 'a  Supply mix response to import price', ...
        'FontSize', 11.5, 'FontWeight', 'normal', 'Color', axisColor);
legend(ax, 'Location', 'southoutside', 'Orientation', 'horizontal', ...
    'Box', 'off', 'FontName', 'Arial', 'FontSize', 9.2);
end

function plotCarbonOwnershipCurve(ax, priceMWhList, externalCarbon, europeCarbon, ...
    yearList, blueColor, axisColor)
% 画三个年份碳减排归因在外部进口价格扫描下的响应。

axes(ax);
hold on
offshoreShare = 100 .* europeCarbon ./ (externalCarbon + europeCarbon);
yearColor = [0.45 0.61 0.76; 0.17 0.44 0.70; blueColor];
yearWidth = 1.7;
yearHandle = gobjects(numel(yearList), 1);
xSmooth = linspace(min(priceMWhList), max(priceMWhList), 600);
thresholdPrice = NaN(numel(yearList), 1);
for iYear = 1:numel(yearList)
    yRaw = cummax(offshoreShare(iYear,:));
    yPlot = smoothdata(yRaw, 'movmean', 5);
    yPlot([1 end]) = yRaw([1 end]);
    yPlot = cummax(yPlot);
    ySmooth = interp1(priceMWhList, yPlot, xSmooth, 'pchip');
    yearHandle(iYear) = plot(ax, xSmooth, ySmooth, '-', ...
        'Color', yearColor(iYear,:), 'LineWidth', yearWidth, ...
        'DisplayName', num2str(yearList(iYear)));
    thresholdIndex = find(ySmooth >= 50, 1, 'first');
    if ~isempty(thresholdIndex) && thresholdIndex > 1
        thresholdPrice(iYear) = interp1(ySmooth(thresholdIndex-1:thresholdIndex), ...
            xSmooth(thresholdIndex-1:thresholdIndex), 50, 'linear');
    end
end
for iYear = 1:numel(yearList)
    if ~isnan(thresholdPrice(iYear))
        xline(ax, thresholdPrice(iYear), '--', 'Color', yearColor(iYear,:), ...
            'LineWidth', 0.9, 'HandleVisibility', 'off');
    end
end
set(ax, 'XTick', 30:15:105, ...
    'XTickLabel', {'30', '45', '60', '', '90', '105'}, ...
    'TickLabelInterpreter', 'none', ...
    'YTick', 0:25:100, 'FontName', 'Arial', 'FontSize', 10, ...
    'LineWidth', 0.9, 'XColor', axisColor, 'Box', 'off');
xlim(ax, [28 107]);
ylim(ax, [0 110]);
text(ax, 75, -4.0, '75', 'FontName', 'Arial', 'FontSize', 10, ...
    'Color', axisColor, 'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'top', 'Clipping', 'off');
text(ax, thresholdPrice(2), 104, 'import-price threshold', 'FontName', 'Arial', ...
    'FontSize', 8.4, 'Color', axisColor, 'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'bottom');
xlabel(ax, 'International hydrogen-equivalent import price (€ MWh^{-1})');
ylabel(ax, 'European offshore attribution (%)');
text(ax, 0, 1.04, 'a', 'Units', 'normalized', ...
    'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold', ...
    'Color', axisColor, 'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'bottom');
legend(ax, yearHandle, 'Location', 'southeast', 'Box', 'off', ...
    'Orientation', 'horizontal', 'FontName', 'Arial', 'FontSize', 8.8);
grid(ax, 'on');
ax.GridAlpha = 0.12;
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
colormap(ax, priceColorMap);
clim(ax, priceRange);
colorbarHandle = colorbar(ax, 'Location', 'eastoutside');
colorbarHandle.Ticks = 30:15:105;
colorbarHandle.Label.String = 'International hydrogen-equivalent import price (€ MWh^{-1})';
colorbarHandle.Label.FontName = 'Arial';
colorbarHandle.Label.FontSize = 8.8;
set(ax, 'YTick', rowPosition, 'YTickLabel', countryList, ...
    'YDir', 'reverse', 'FontName', 'Arial', 'FontSize', 9.4, ...
    'LineWidth', 0.9, 'XColor', axisColor, 'YColor', axisColor, 'Box', 'off');
xlim(ax, [-260 185]);
set(ax, 'XTick', [-250 -150 -50 50 150]);
ylim(ax, [0.35 numel(countryList) + 0.75]);
xlabel(ax, 'Net export (TWh yr^{-1})');
text(ax, 0, 1.04, 'b', 'Units', 'normalized', ...
    'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold', ...
    'Color', axisColor, 'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'bottom');
text(ax, 0.34, 1.04, sprintf('vertical ticks: import-price anchors %.1f/%.1f/%.1f € MWh^{-1}', ...
    literatureAnchorPrice(1), literatureAnchorPrice(2), literatureAnchorPrice(3)), 'Units', 'normalized', ...
    'FontName', 'Arial', 'FontSize', 8.2, 'Color', axisColor, ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');
text(ax, -250, 0.58, 'price direction: 30 \rightarrow 105 € MWh^{-1}', ...
    'FontName', 'Arial', 'FontSize', 8.2, 'Color', axisColor, ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
legend(ax, yearLegend, 'Location', 'northwest', 'Box', 'off', ...
    'Orientation', 'horizontal', ...
    'FontName', 'Arial', 'FontSize', 8.8);
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
% 按价格扫描区间画渐变线，避免导出时产生过多对象。

for iPoint = 1:(numel(xValues) - 1)
    colorNow = valueToColor(mean(priceValues(iPoint:iPoint + 1)), priceRange, priceColorMap);
    plot(ax, xValues(iPoint:iPoint + 1), yValue * [1 1], '-', ...
        'Color', colorNow, 'LineWidth', lineWidth, 'HandleVisibility', 'off');
end
end
