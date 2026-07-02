function plotDomesticAbsorptionAndExportPotential(projectRoot)
if nargin == 0
    projectRoot = pwd;
end

figureDir = fullfile(projectRoot, 'figs');
manuscriptFigureDir = fullfile(projectRoot, 'manuscript', 'figs');
if exist(figureDir, 'dir') ~= 7
    mkdir(figureDir);
end
if exist(manuscriptFigureDir, 'dir') ~= 7
    mkdir(manuscriptFigureDir);
end

syncMainFigure(figureDir, manuscriptFigureDir, ...
    'fig unit commitment main.pdf', 'fig_unit_commitment_main.pdf');
plotExportPotentialMatrix(projectRoot, figureDir, manuscriptFigureDir);
end

function syncMainFigure(figureDir, manuscriptFigureDir, sourceName, targetName)
copyfile(fullfile(figureDir, sourceName), fullfile(manuscriptFigureDir, targetName));
end

function plotExportPotentialMatrix(projectRoot, figureDir, manuscriptFigureDir)
sourceTable = readtable(fullfile(projectRoot, 'results', 'tables', 'NC_domestic_export_potential.csv'));
years = [2030, 2040, 2050];
componentVariables = {'PowerSystemUse_TWh', 'GasSystemUse_TWh', ...
    'AvailableExport_TWh', 'ResidualCurtailment_TWh'};
componentLabels = {'Power system', 'Gas system', 'Available export', 'Residual curtailment'};
componentColors = [
    0.47 0.69 0.82
    0.88 0.59 0.47
    0.93 0.78 0.49
    0.66 0.49 0.69
];

countryNames = string(sourceTable.Country(sourceTable.Year == 2050));
data2050 = extractYearData(sourceTable, 2050, countryNames, componentVariables);
[~, order] = sort(sum(data2050, 2), 'descend');
countryNames = countryNames(order);
nCountries = numel(countryNames);

maxTotal = 700;
fig = figure('Color', 'w', 'Units', 'centimeters', 'Position', [2, 2, 18.6, 9.2]);
axisPositions = [
    0.075 0.18 0.275 0.67
    0.385 0.18 0.275 0.67
    0.695 0.18 0.275 0.67
];

for iYear = 1:numel(years)
    ax = axes('Parent', fig, 'Position', axisPositions(iYear, :));
    yearData = extractYearData(sourceTable, years(iYear), countryNames, componentVariables);
    barHandles = barh(ax, 1:nCountries, yearData, 0.72, 'stacked', ...
        'LineWidth', 0.35, 'EdgeColor', [0.24 0.24 0.24]);
    for iComponent = 1:numel(barHandles)
        barHandles(iComponent).FaceColor = componentColors(iComponent, :);
    end
    hold(ax, 'on');
    totalWind = sum(yearData, 2);
    scatter(ax, totalWind, 1:nCountries, 18, 'o', ...
        'MarkerFaceColor', 'w', 'MarkerEdgeColor', [0.2 0.2 0.2], ...
        'LineWidth', 0.8);
    labelLargeExportSegments(ax, yearData);
    hold(ax, 'off');

    ax.Box = 'off';
    ax.FontName = 'Arial';
    ax.FontSize = 7.5;
    ax.LineWidth = 0.75;
    ax.XLim = [0, maxTotal];
    ax.XTick = [0, 200, 400, 600, 700];
    ax.YLim = [0.35, nCountries + 0.65];
    ax.YDir = 'reverse';
    ax.YTick = 1:nCountries;
    ax.XGrid = 'on';
    ax.YGrid = 'off';
    ax.GridColor = [0.82 0.82 0.82];
    ax.GridAlpha = 0.45;
    title(ax, string(years(iYear)), 'FontName', 'Arial', 'FontSize', 9, ...
        'FontWeight', 'bold');
    if iYear == 1
        ax.YTickLabel = countryNames;
    else
        ax.YTickLabel = [];
    end
    text(ax, -0.13, 1.03, char('a' + iYear - 1), 'Units', 'normalized', ...
        'FontName', 'Arial', 'FontSize', 9, 'FontWeight', 'bold');
end

drawAllocationLegend(fig, componentColors, componentLabels);
annotation(fig, 'textbox', [0.37 0.055 0.32 0.035], ...
    'String', 'Annual offshore wind allocation (TWh yr^{-1})', ...
    'FontName', 'Arial', 'FontSize', 8, 'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', 'LineStyle', 'none');

outputPdf = fullfile(figureDir, 'fig wind decomposition.pdf');
exportgraphics(fig, outputPdf, 'ContentType', 'vector');
copyfile(outputPdf, fullfile(manuscriptFigureDir, 'fig_wind_decomposition.pdf'));
close(fig);
end

function yearData = extractYearData(sourceTable, year, countryNames, componentVariables)
yearData = zeros(numel(countryNames), numel(componentVariables));
for iCountry = 1:numel(countryNames)
    row = sourceTable(sourceTable.Year == year & string(sourceTable.Country) == countryNames(iCountry), :);
    for iComponent = 1:numel(componentVariables)
        yearData(iCountry, iComponent) = row.(componentVariables{iComponent});
    end
end
end

function labelLargeExportSegments(ax, yearData)
exportPotential = yearData(:, 3);
exportStart = yearData(:, 1) + yearData(:, 2);
for iCountry = 1:size(yearData, 1)
    if exportPotential(iCountry) >= 80
        text(ax, exportStart(iCountry) + exportPotential(iCountry) / 2, iCountry, ...
            sprintf('%.0f', exportPotential(iCountry)), ...
            'FontName', 'Arial', 'FontSize', 6.5, 'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
            'Color', [0.18 0.18 0.18]);
    end
end
end

function drawAllocationLegend(fig, componentColors, componentLabels)
legendX = [0.10, 0.315, 0.525, 0.745];
for iComponent = 1:numel(componentLabels)
    annotation(fig, 'rectangle', [legendX(iComponent), 0.925, 0.025, 0.018], ...
        'FaceColor', componentColors(iComponent, :), ...
        'EdgeColor', [0.24 0.24 0.24], 'LineWidth', 0.35);
    annotation(fig, 'textbox', [legendX(iComponent) + 0.032, 0.914, 0.17, 0.04], ...
        'String', componentLabels{iComponent}, 'FontName', 'Arial', ...
        'FontSize', 7.5, 'LineStyle', 'none', ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
end
end

function plotCurtailmentSummary(data, figureDir, manuscriptFigureDir)
yearNames = {'2030', '2040', '2050'};
seasonNames = {'Summer', 'Winter'};
scenarioLabels = strings(1, 6);
curtailNoExport = zeros(1, 6);
curtailExport = zeros(1, 6);

k = 1;
for iYear = 1:3
    for iSeason = 1:2
        scenarioLabels(k) = sprintf('%s %s', yearNames{iYear}, seasonNames{iSeason});
        curtailNoExport(k) = 100 * mean(data.curtailmentRateNoExport{iYear, iSeason});
        curtailExport(k) = 100 * mean(data.curtailmentRateExport{iYear, iSeason});
        k = k + 1;
    end
end

usedNoExport = sum(data.electricityGenerationNoExport{3, 1}(:, 9) + data.electricityGenerationNoExport{3, 1}(:, 10)) / 1e3;
curtailedNoExport = sum(data.windCurtailmentNoExport{3, 1}) / 1e3;
usedExport = sum(data.electricityGenerationExport{3, 1}(:, 9) + data.electricityGenerationExport{3, 1}(:, 10)) / 1e3;
curtailedExport = sum(data.windCurtailmentExport{3, 1}) / 1e3;

fig = figure('Color', 'w', 'Units', 'centimeters', 'Position', [2, 2, 18, 9]);
tiledlayout(fig, 1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
barHandle = bar(1:6, [curtailNoExport(:), curtailExport(:)], 'grouped', 'LineWidth', 0.6);
barHandle(1).FaceColor = [0.72 0.22 0.18];
barHandle(2).FaceColor = [0.18 0.45 0.70];
ax = gca;
ax.Box = 'off';
ax.LineWidth = 0.8;
ax.FontName = 'Arial';
ax.FontSize = 8;
ax.XTick = 1:6;
ax.XTickLabel = scenarioLabels;
ax.XTickLabelRotation = 35;
ylabel('Mean wind-curtailment rate (%)');
ylim([0, 90]);
legend(barHandle, {'Without export', 'With export'}, 'Location', 'northwest', 'Box', 'off');
text(0.01, 1.03, 'a', 'Units', 'normalized', 'FontWeight', 'bold', 'FontName', 'Arial');

nexttile;
barHandle = bar([usedNoExport, curtailedNoExport; usedExport, curtailedExport], 'stacked', 'LineWidth', 0.6);
barHandle(1).FaceColor = [0.29 0.57 0.42];
barHandle(2).FaceColor = [0.72 0.72 0.72];
ax = gca;
ax.Box = 'off';
ax.LineWidth = 0.8;
ax.FontName = 'Arial';
ax.FontSize = 8;
ax.XTickLabel = {'Without export', 'With export'};
ylabel('2050 summer wind energy (GWh over 72 h)');
legend(barHandle, {'Used by power system', 'Curtailed'}, 'Location', 'northeast', 'Box', 'off');
ylim([0, max([usedNoExport + curtailedNoExport, usedExport + curtailedExport]) * 1.18]);
text(0.01, 1.03, 'b', 'Units', 'normalized', 'FontWeight', 'bold', 'FontName', 'Arial');

outputPdf = fullfile(figureDir, 'fig unit commitment summary.pdf');
exportgraphics(fig, outputPdf, 'ContentType', 'vector');
copyfile(outputPdf, fullfile(manuscriptFigureDir, 'fig_unit_commitment_summary.pdf'));
close(fig);
end

function plotExportPotentialSummary(data, figureDir, manuscriptFigureDir)
countryNames = ["BE", "DK", "FR", "DE", "IE", "NL", "NO", "PT", "ES", "SE", "GB"];
yearNames = {'2030', '2040', '2050'};
componentNames = {'Power-system use', 'Gas-system use', 'Available export', 'Residual curtailment'};
componentColors = [
    0.22 0.45 0.70
    0.35 0.66 0.55
    0.90 0.62 0.18
    0.70 0.70 0.70
];

[~, order] = sort(data.EUwindConsump_new{3}(:, 3), 'descend');
orderedNames = countryNames(order);
maxTotal = 0;
for iYear = 1:3
    maxTotal = max(maxTotal, max(sum(data.EUwindConsump_new{iYear}, 2)));
end

fig = figure('Color', 'w', 'Units', 'centimeters', 'Position', [2, 2, 18, 13]);
tiledlayout(fig, 2, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

for iYear = 1:3
    nexttile;
    barHandle = bar(data.EUwindConsump_new{iYear}(order, :), 'stacked', 'LineWidth', 0.4);
    for iComponent = 1:numel(barHandle)
        barHandle(iComponent).FaceColor = componentColors(iComponent, :);
    end
    ax = gca;
    ax.Box = 'off';
    ax.LineWidth = 0.8;
    ax.FontName = 'Arial';
    ax.FontSize = 8;
    ax.XTick = 1:numel(orderedNames);
    ax.XTickLabel = orderedNames;
    ax.XTickLabelRotation = 0;
    ylim([0, maxTotal * 1.08]);
    ylabel('TWh yr^{-1}');
    title(yearNames{iYear}, 'FontWeight', 'normal');
    text(0.01, 1.03, char('a' + iYear - 1), 'Units', 'normalized', ...
        'FontWeight', 'bold', 'FontName', 'Arial');
    if iYear == 1
        legend(componentNames, 'Location', 'northoutside', 'Orientation', 'horizontal', ...
            'NumColumns', 2, 'Box', 'off');
    end
end

nexttile;
hold on;
keyCountryIndex = [11, 5, 6, 2];
keyColors = [
    0.18 0.45 0.70
    0.84 0.37 0.20
    0.35 0.61 0.38
    0.55 0.40 0.70
];
labelOffsets = [0, 0, 8, -8];
for iCountry = 1:numel(keyCountryIndex)
    exportPotential = zeros(1, 3);
    for iYear = 1:3
        exportPotential(iYear) = data.EUwindConsump_new{iYear}(keyCountryIndex(iCountry), 3);
    end
    plot(1:3, exportPotential, '-o', 'LineWidth', 1.5, 'MarkerSize', 4, ...
        'Color', keyColors(iCountry, :), 'MarkerFaceColor', keyColors(iCountry, :));
    text(3.05, exportPotential(3) + labelOffsets(iCountry), char(countryNames(keyCountryIndex(iCountry))), ...
        'FontName', 'Arial', 'FontSize', 8, 'Color', keyColors(iCountry, :), ...
        'VerticalAlignment', 'middle');
end
hold off;
ax = gca;
ax.Box = 'off';
ax.LineWidth = 0.8;
ax.FontName = 'Arial';
ax.FontSize = 8;
ax.XLim = [0.85, 3.35];
ax.XTick = 1:3;
ax.XTickLabel = yearNames;
ylabel('Available export potential (TWh yr^{-1})');
text(0.01, 1.03, 'd', 'Units', 'normalized', 'FontWeight', 'bold', 'FontName', 'Arial');

outputPdf = fullfile(figureDir, 'fig wind decomposition summary.pdf');
exportgraphics(fig, outputPdf, 'ContentType', 'vector');
copyfile(outputPdf, fullfile(manuscriptFigureDir, 'fig_wind_decomposition_summary.pdf'));
close(fig);
end
