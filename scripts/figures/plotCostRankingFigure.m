function plotCostRankingFigure(projectRoot)
if nargin == 0
    projectRoot = setupHyExport();
else
    projectRoot = setupHyExport(projectRoot);
end

sourceTable = readtable(fullfile(projectRoot, 'results', 'tables', ...
    'NC_lcoh_rank_table.csv'), 'TextType', 'string');

figureDir = fullfile(projectRoot, 'figs');
manuscriptFigureDir = fullfile(projectRoot, 'manuscript', 'main', 'figs');
if exist(figureDir, 'dir') ~= 7
    mkdir(figureDir);
end
if exist(manuscriptFigureDir, 'dir') ~= 7
    mkdir(manuscriptFigureDir);
end

countryList = ["BE", "DK", "FR", "DE", "IE", "NL", "NO", "PT", "ES", "SE", "GB"];
yearList = [2030, 2040, 2050];

fig = figure('Color', 'w', 'Units', 'pixels', 'Position', [100, 100, 920, 610], ...
    'Visible', 'off');

panelPositions = [
    0.08 0.28 0.23 0.62
    0.36 0.28 0.23 0.62
    0.64 0.28 0.23 0.62
    ];
axisColor = [0.18 0.18 0.18];
costMap = makeCostMap(256);

for iYear = 1:numel(yearList)
    ax = axes(fig, 'Position', panelPositions(iYear, :));
    yearRows = sourceTable(sourceTable.Year == yearList(iYear), :);
    yearRows = orderRows(yearRows, countryList);

    costMatrix = [
        yearRows.AverageLCOH_EURperMWh, ...
        yearRows.MarginalLCOH_EURperMWh, ...
        nan(height(yearRows), 1)
        ];
    rankMatrix = [
        yearRows.AverageRank, ...
        yearRows.MarginalRank
        ];
    capacity = yearRows.LowPriceHydrogenCapacity_GW;

    drawCostCells(ax, costMatrix, [45, 95], costMap);
    colormap(ax, costMap);
    clim(ax, [45, 95]);
    ax.Color = 'w';
    hold(ax, 'on');

    for iRow = 1:numel(countryList)
        for iCol = 1:2
            text(ax, iCol, iRow, sprintf('%d', rankMatrix(iRow, iCol)), ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                'FontName', 'Arial', 'FontSize', 11, 'FontWeight', 'bold', ...
                'Color', [0.05 0.05 0.05]);
        end
        scatter(ax, 3, iRow, capacityMarkerSize(capacity(iRow)), ...
            'MarkerFaceColor', 'w', 'MarkerEdgeColor', [0.12 0.12 0.12], ...
            'LineWidth', 0.9);
    end

    drawCellGrid(ax, 3, numel(countryList));
    hold(ax, 'off');

    ax.FontName = 'Arial';
    ax.FontSize = 8.5;
    ax.LineWidth = 0.9;
    ax.TickDir = 'out';
    ax.Layer = 'top';
    ax.Box = 'on';
    ax.XTick = 1:3;
    ax.XTickLabel = {'Avg. rank', 'Marg. rank', '< blue hydrogen cap.'};
    ax.XTickLabelRotation = 24;
    ax.YTick = 1:numel(countryList);
    ax.YDir = 'reverse';
    if iYear == 1
        ax.YTickLabel = countryList;
    else
        ax.YTickLabel = [];
    end
    ax.XLim = [0.5 3.5];
    ax.YLim = [0.5 numel(countryList) + 0.5];
    title(ax, string(yearList(iYear)), 'FontName', 'Arial', 'FontSize', 12, ...
        'FontWeight', 'bold');
    text(ax, -0.16, 1.03, char('a' + iYear - 1), 'Units', 'normalized', ...
        'FontName', 'Arial', 'FontSize', 10, 'FontWeight', 'bold');
end

colorbarAx = axes(fig, 'Position', [0.895 0.32 0.018 0.53], 'Visible', 'off');
colormap(colorbarAx, costMap);
clim(colorbarAx, [45, 95]);
c = colorbar(colorbarAx);
c.Position = [0.895 0.32 0.018 0.53];
c.Label.String = 'Underlying LCOH (€ MWh^{-1})';
c.Label.FontName = 'Arial';
c.FontName = 'Arial';
c.FontSize = 8.5;

legendAx = axes(fig, 'Position', [0.70 0.030 0.22 0.085]);
hold(legendAx, 'on');
legendAx.Visible = 'off';
legendValues = [0, 50, 100];
legendX = [0.12, 0.45, 0.78];
for iLegend = 1:numel(legendValues)
    scatter(legendAx, legendX(iLegend), 0.52, capacityMarkerSize(legendValues(iLegend)), ...
        'MarkerFaceColor', 'w', 'MarkerEdgeColor', [0.12 0.12 0.12], ...
        'LineWidth', 0.9);
end
text(legendAx, legendX, [0.10 0.10 0.10], {'0', '50', '>100'}, ...
    'HorizontalAlignment', 'center', 'FontName', 'Arial', 'FontSize', 8);
text(legendAx, 0.45, 0.90, 'Capacity < blue hydrogen (GW)', ...
    'HorizontalAlignment', 'center', 'FontName', 'Arial', 'FontSize', 8);
legendAx.XLim = [0 1];
legendAx.YLim = [0 1];

outputPdf = fullfile(figureDir, 'fig cost table.pdf');
manuscriptPdf = fullfile(manuscriptFigureDir, 'fig_cost_table.pdf');
exportgraphics(fig, outputPdf, 'ContentType', 'vector');
copyfile(outputPdf, manuscriptPdf);
fileattrib(outputPdf, '-x');
fileattrib(manuscriptPdf, '-x');
close(fig);
end

function orderedTable = orderRows(sourceTable, countryList)
orderedTable = sourceTable([], :);
for iCountry = 1:numel(countryList)
    orderedTable = [orderedTable; sourceTable(sourceTable.Country == countryList(iCountry), :)];
end
end

function markerSize = capacityMarkerSize(capacity)
capacity = min(capacity, 100);
markerSize = 18 + 135 * sqrt(capacity / 100);
end

function drawCellGrid(ax, nCol, nRow)
for x = 0.5:1:(nCol + 0.5)
    plot(ax, [x x], [0.5 nRow + 0.5], '-', 'Color', [1 1 1], 'LineWidth', 0.9);
end
for y = 0.5:1:(nRow + 0.5)
    plot(ax, [0.5 nCol + 0.5], [y y], '-', 'Color', [1 1 1], 'LineWidth', 0.9);
end
plot(ax, [2.5 2.5], [0.5 nRow + 0.5], '-', 'Color', [0.65 0.65 0.65], ...
    'LineWidth', 0.8);
end

function drawCostCells(ax, costMatrix, colorLimits, costMap)
nColor = size(costMap, 1);
for iRow = 1:size(costMatrix, 1)
    for iCol = 1:size(costMatrix, 2)
        if isnan(costMatrix(iRow, iCol))
            continue
        end
        colorIndex = round((costMatrix(iRow, iCol) - colorLimits(1)) / ...
            diff(colorLimits) * (nColor - 1)) + 1;
        colorIndex = min(max(colorIndex, 1), nColor);
        rectangle(ax, 'Position', [iCol - 0.5, iRow - 0.5, 1, 1], ...
            'FaceColor', costMap(colorIndex, :), 'EdgeColor', 'none');
    end
end
end

function cmap = makeCostMap(nColor)
anchor = [
    0.20 0.30 0.75
    0.20 0.63 0.82
    0.52 0.82 0.64
    0.96 0.78 0.38
    0.92 0.38 0.25
    ];
xAnchor = linspace(0, 1, size(anchor, 1));
xQuery = linspace(0, 1, nColor);
cmap = interp1(xAnchor, anchor, xQuery, 'linear');
end
