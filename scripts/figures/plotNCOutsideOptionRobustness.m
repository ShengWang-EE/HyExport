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
priceList = unique(summaryTable.ImportCost_EURperKgH2, 'stable');
priceLabel = round(priceList);

headlineYear = 2050;
summary2050 = summaryTable(summaryTable.Year == headlineYear,:);
offshoreSupply = summary2050.EuropeanOffshoreSupply_TWh;
outsideImport = summary2050.InternationalImport_TWh;

focusCountry = ["IE", "GB", "DK"];
focusLabel = ["Ireland", "GB", "Denmark"];
countryNetExport = getCountryNetExport(countryTable, headlineYear, priceList, focusCountry);

blueColor = [0.04 0.30 0.55];
orangeColor = [0.78 0.34 0.12];
axisColor = [0.18 0.18 0.18];

fig = figure('Color', 'white', 'Position', [100 100 1120 610]);

% panel a：用堆叠柱展示外部进口和欧洲 offshore supply 的替代关系，比两条线更直接。
supplyAx = axes('Parent', fig, 'Position', [0.08 0.18 0.47 0.62]);
plotSupplyStack(supplyAx, priceList, priceLabel, offshoreSupply, outsideImport, ...
    blueColor, orangeColor, axisColor);

% panel b：关键国家的净出口响应做成小 heatmap，减少折线图的视觉噪音。
countryAx = axes('Parent', fig, 'Position', [0.61 0.27 0.30 0.43]);
plotExporterHeatmap(countryAx, countryNetExport, focusLabel, priceLabel, axisColor);

outputPdf = fullfile(figureDir, 'fig_nc_outside_option_robustness.pdf');
outputPng = fullfile(figureDir, 'fig_nc_outside_option_robustness.png');
exportgraphics(fig, outputPdf, 'ContentType', 'vector');
exportgraphics(fig, outputPng, 'Resolution', 600);
copyfile(outputPdf, fullfile(manuscriptFigureDir, 'fig_nc_outside_option_robustness.pdf'));
close(fig)
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

function plotSupplyStack(ax, priceList, priceLabel, offshoreSupply, outsideImport, ...
    blueColor, orangeColor, axisColor)
% 画 2050 供应来源替代关系。左侧是外部进口主导，右侧是欧洲 offshore supply 主导。

axes(ax);
hold on
barHandle = bar(priceList, [outsideImport offshoreSupply], 'stacked', ...
    'BarWidth', 0.66, 'LineWidth', 0.5);
barHandle(1).FaceColor = orangeColor;
barHandle(1).EdgeColor = 'none';
barHandle(2).FaceColor = blueColor;
barHandle(2).EdgeColor = 'none';

xline(3.5, '-', 'Color', [0.25 0.25 0.25], 'LineWidth', 0.9, ...
    'HandleVisibility', 'off');
text(3.56, 880, 'threshold', 'FontName', 'Arial', 'FontSize', 9.5, ...
    'Color', axisColor, 'VerticalAlignment', 'top');
text(2.5, 900, 'import-dominated', 'FontName', 'Arial', 'FontSize', 9.5, ...
    'HorizontalAlignment', 'center', 'Color', orangeColor);
text(5.0, 900, 'offshore-retained', 'FontName', 'Arial', 'FontSize', 9.5, ...
    'HorizontalAlignment', 'center', 'Color', blueColor);

set(ax, 'XTick', priceList, 'XTickLabel', string(priceLabel), ...
    'FontName', 'Arial', 'FontSize', 10, 'LineWidth', 0.9, ...
    'XColor', axisColor, 'YColor', axisColor, 'Box', 'off');
xlim(ax, [1.45 6.55]);
ylim(ax, [0 950]);
xlabel(ax, 'Delivered outside option (EUR kg^{-1} H_2-eq.)');
ylabel(ax, '2050 supply to modelled demand (TWh yr^{-1})');
title(ax, 'a  External price shifts the supply mix', ...
    'FontSize', 11.5, 'FontWeight', 'normal', 'Color', axisColor);
text(6, outsideImport(end) / 2, 'Import', 'FontName', 'Arial', ...
    'FontSize', 9.5, 'Color', 'white', 'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle');
text(6, outsideImport(end) + offshoreSupply(end) / 2, ...
    'Offshore', 'FontName', 'Arial', 'FontSize', 9.5, ...
    'Color', 'white', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
grid(ax, 'on');
ax.GridAlpha = 0.12;
end

function plotExporterHeatmap(ax, countryNetExport, focusLabel, priceLabel, axisColor)
% 画 Ireland、GB、Denmark 的净出口阈值响应。

axes(ax);
imagesc(countryNetExport);
colormap(ax, makeDivergingMap(256));
clim(ax, [-170 170]);
hold on
xline(2.5, '-', 'Color', [0.25 0.25 0.25], 'LineWidth', 0.9);
for iColumn = 1:size(countryNetExport,2)
    for iRow = 1:size(countryNetExport,1)
        valueNow = countryNetExport(iRow,iColumn);
        labelColor = [0.10 0.10 0.10];
        if abs(valueNow) > 95
            labelColor = [1 1 1];
        end
        text(iColumn, iRow, sprintf('%.0f', valueNow), ...
            'HorizontalAlignment', 'center', 'FontName', 'Arial', ...
            'FontSize', 8.8, 'Color', labelColor);
    end
end

set(ax, 'XTick', 1:numel(priceLabel), 'XTickLabel', string(priceLabel), ...
    'YTick', 1:numel(focusLabel), 'YTickLabel', focusLabel, ...
    'TickLength', [0 0], 'FontName', 'Arial', 'FontSize', 10, ...
    'LineWidth', 0.9, 'XColor', axisColor, 'YColor', axisColor, 'Box', 'off');
xlabel(ax, 'Outside option (EUR kg^{-1} H_2-eq.)');
title(ax, 'b  Exporter response at 2050', ...
    'FontSize', 11.5, 'FontWeight', 'normal', 'Color', axisColor);

colorBar = colorbar(ax, 'Location', 'eastoutside');
colorBar.Label.String = 'Net export (TWh yr^{-1})';
colorBar.FontName = 'Arial';
colorBar.FontSize = 9;
colorBar.Label.FontName = 'Arial';
end

function colorMap = makeDivergingMap(nColor)
% 生成简洁红-白-蓝发散色图，中心为零。

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
