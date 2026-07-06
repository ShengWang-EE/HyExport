function plotTradeAndCarbonFigure(projectRoot)
if nargin == 0
    projectRoot = pwd;
end

checkpointFile = fullfile(projectRoot, 'results', 'checkpoints', 'stop3.mat');
data = load(checkpointFile, 'solution');

figureDir = fullfile(projectRoot, 'figs');
manuscriptFigureDir = fullfile(projectRoot, 'manuscript', 'figs');
if exist(figureDir, 'dir') ~= 7
    mkdir(figureDir);
end
if exist(manuscriptFigureDir, 'dir') ~= 7
    mkdir(manuscriptFigureDir);
end

nodeList = ["BE", "DK", "FR", "DE", "IE", "NL", "NO", "PT", "ES", "SE", "GB", "ITN"];
countryList = ["BE", "DK", "FR", "DE", "IE", "NL", "NO", "PT", "ES", "SE", "GB"];
yearList = ["2030", "2040", "2050"];
colors = generateColorData('gem12');
axisFontSize = 8.5;
panelFontSize = 11;
flowLabelCounts = [4, 5, 5];

fig = figure('Color', 'w', 'Units', 'pixels', 'Position', [100, 100, 660, 820], ...
    'Visible', 'off');
set(fig, 'DefaultAxesColorOrder', colors);
annotation(fig, 'textbox', [0.05, 0.004, 0.44, 0.024], ...
    'String', 'Flow labels: TWh yr^{-1}', 'FontName', 'Arial', ...
    'FontSize', axisFontSize - 1, 'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', 'LineStyle', 'none', ...
    'Color', [0.28 0.28 0.28]);

chordPositions = [
    0.02 0.67 0.50 0.30
    0.02 0.35 0.50 0.30
    0.02 0.03 0.50 0.30
];
barPositions = [
    0.56 0.67 0.39 0.24
    0.56 0.36 0.39 0.24
    0.56 0.05 0.39 0.24
];
panelLetters = ["a", "c", "e"; "b", "d", "f"];

for iYear = 1:3
    axes('Position', chordPositions(iYear, :));
    flowMatrix = buildHydrogenFlowMatrix(data.solution{iYear}, numel(nodeList));
    labelMatrix = flowMatrix;
    if iYear == 1
        labelMatrix(6, 4) = sum(abs(data.solution{iYear}.tradingArray( ...
            data.solution{iYear}.tradingArray(:, 1) == 4 & ...
            data.solution{iYear}.tradingArray(:, 2) == 6, 4:5)));
    end
    chart = biChordChart(flowMatrix, 'Arrow', 'on', 'Label', nodeList, 'Sep', 0.075);
    chart.CData = colors;
    chart = chart.draw();
    chart.tickState('on');
    chart.setChordN(1:numel(nodeList), 'FaceAlpha', 0.38);
    chart.setFont('FontName', 'Arial', 'FontSize', 8.5);
    chart.setLabelRadius(1.27);
    chart.ax.XLim = [-1.44, 1.44];
    chart.ax.YLim = [-1.44, 1.44];
    set(chart.RTickHdl, 'Color', [0.25 0.25 0.25], 'LineWidth', 0.7);
    set(chart.thetaTickHdl, 'Color', [0.25 0.25 0.25], 'LineWidth', 0.5);
    labelKeyHydrogenFlows(chart, flowMatrix, labelMatrix, flowLabelCounts(iYear));
    text(-0.02, 1.02, panelLetters(1, iYear), 'Units', 'normalized', ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', ...
        'FontWeight', 'bold', 'FontSize', panelFontSize, 'Clipping', 'off');
    text(0.50, 0.50, yearList(iYear), 'Units', 'normalized', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'FontWeight', 'bold', 'FontSize', panelFontSize);

    ax = axes('Position', barPositions(iYear, :));
    ax.ColorOrder = colors;
    bars = bar(data.solution{iYear}.carbonReductionContributionMatrix', 'stacked', ...
        'BarWidth', 0.54, 'FaceAlpha', 0.86);
    set(bars, 'EdgeColor', [0.28 0.28 0.28], 'LineWidth', 0.25);
    ax.FontName = 'Arial';
    ax.FontSize = axisFontSize;
    ax.LineWidth = 0.9;
    ax.TickDir = 'out';
    ax.YGrid = 'on';
    ax.GridColor = [0.85 0.85 0.85];
    ax.GridAlpha = 0.45;
    ax.Layer = 'top';
    box(ax, 'off');
    ax.XTick = 1:numel(countryList);
    ax.XTickLabel = countryList;
    ax.YTick = 0:20:60;
    ax.XLim = [0.4 numel(countryList) + 0.6];
    ylim([0, 60]);
    xtickangle(ax, 35);
    ylabel('CO_2 mitigation (Mt CO_2 yr^{-1})', 'FontSize', axisFontSize);
    if iYear == 3
        xlabel('Destination / demand country', 'FontSize', axisFontSize);
    end
    totalMitigation = sum(data.solution{iYear}.carbonReductionContributionMatrix(:));
    text(0.97, 0.93, yearList(iYear), 'Units', 'normalized', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
        'FontName', 'Arial', 'FontWeight', 'bold', 'FontSize', panelFontSize - 1, ...
        'Clipping', 'off');
    text(0.97, 0.82, sprintf('Total = %.1f Mt CO_2 yr^{-1}', totalMitigation), ...
        'Units', 'normalized', 'HorizontalAlignment', 'right', ...
        'VerticalAlignment', 'top', 'FontName', 'Arial', ...
        'FontSize', axisFontSize - 1, 'Color', [0.28 0.28 0.28], ...
        'Clipping', 'off');
    text(-0.16, 1.02, panelLetters(2, iYear), 'Units', 'normalized', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
        'FontWeight', 'bold', 'FontSize', panelFontSize, 'Clipping', 'off');
    if iYear == 1
        lgd = legend(nodeList, 'NumColumns', 4);
        lgd.Box = 'off';
        lgd.FontName = 'Arial';
        lgd.FontSize = axisFontSize;
        lgd.Units = 'normalized';
        lgd.Position = [0.56, 0.915, 0.39, 0.07];
    end
end

outputPdf = fullfile(figureDir, 'fig hy am flow sankey.pdf');
manuscriptPdf = fullfile(manuscriptFigureDir, 'fig_hy_am_flow_sankey.pdf');
exportgraphics(fig, outputPdf, 'ContentType', 'vector');
copyfile(outputPdf, manuscriptPdf);
fileattrib(outputPdf, '-x');
fileattrib(manuscriptPdf, '-x');
close(fig);
end

function labelKeyHydrogenFlows(chart, flowMatrix, labelMatrix, nLabels)
[flowValues, flowOrder] = sort(flowMatrix(:), 'descend');
labelCount = 0;
for iFlow = 1:numel(flowOrder)
    if flowValues(iFlow) <= 0 || labelCount == nLabels
        break
    end
    [fromNode, toNode] = ind2sub(size(flowMatrix), flowOrder(iFlow));
    sourceTheta = mean(chart.thetaFullSet(fromNode, [toNode, toNode + 1]));
    labelRadius = 0.62;
    labelPoint = labelRadius .* [cos(sourceTheta), sin(sourceTheta)];
    labelColor = chart.CData(fromNode, :) .* 0.55;
    text(labelPoint(1), labelPoint(2), sprintf('%.0f', labelMatrix(fromNode, toNode)), ...
        'FontName', 'Arial', 'FontSize', 6.2, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'Color', labelColor, 'Clipping', 'off');
    labelCount = labelCount + 1;
end
end

function flowMatrix = buildHydrogenFlowMatrix(solution, nNode)
flowMatrix = zeros(nNode);
for iLine = 1:size(solution.tradingArray, 1)
    fromNode = solution.tradingArray(iLine, 1);
    toNode = solution.tradingArray(iLine, 2);
    hydrogenFlow = solution.tradingArray(iLine, 4);
    if hydrogenFlow > 0
        flowMatrix(fromNode, toNode) = hydrogenFlow;
    else
        flowMatrix(toNode, fromNode) = -hydrogenFlow;
    end
end
for iNode = 1:nNode
    flowMatrix(iNode, iNode) = 0;
end
end
