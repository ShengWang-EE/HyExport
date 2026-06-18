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

fig = figure('Color', 'w', 'Units', 'pixels', 'Position', [100, 100, 600, 800], ...
    'Visible', 'off');
set(fig, 'DefaultAxesColorOrder', colors);

chordPositions = [
    0.00 0.67 0.50 0.30
    0.00 0.35 0.50 0.30
    0.00 0.03 0.50 0.30
];
barPositions = [
    0.55 0.69 0.35 0.27
    0.55 0.37 0.35 0.27
    0.55 0.05 0.35 0.27
];
panelLetters = ["a", "c", "e"; "b", "d", "f"];

for iYear = 1:3
    axes('Position', chordPositions(iYear, :));
    flowMatrix = buildHydrogenFlowMatrix(data.solution{iYear}, numel(nodeList));
    chart = biChordChart(flowMatrix, 'Arrow', 'on', 'Label', nodeList);
    chart.CData = colors;
    chart = chart.draw();
    chart.tickState('on');
    chart.setFont('FontName', 'Arial', 'FontSize', 8);
    chart.setLabelRadius(1.32);
    text(0.05, 0.07, panelLetters(1, iYear), 'Units', 'normalized', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', 'FontWeight', 'bold');
    text(0.55, 0.55, yearList(iYear), 'Units', 'normalized', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', 'FontWeight', 'bold');

    ax = axes('Position', barPositions(iYear, :));
    ax.ColorOrder = colors;
    bar(data.solution{iYear}.carbonReductionContributionMatrix', 'stacked', ...
        'BarWidth', 0.5, 'FaceAlpha', 0.75);
    ax.FontName = 'Arial';
    ax.FontSize = 8;
    ax.LineWidth = 0.8;
    ax.XTick = 1:numel(countryList);
    ax.XTickLabel = countryList;
    ylim([0, 60]);
    ylabel('CO_2 mitigation (Mt CO_2 yr^{-1})');
    text(-0.15, 0.01, panelLetters(2, iYear), 'Units', 'normalized', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', 'FontWeight', 'bold');
    if iYear == 1
        lgd = legend(nodeList, 'Location', 'north', 'NumColumns', 3);
        lgd.Box = 'off';
        lgd.FontName = 'Arial';
        lgd.FontSize = 8;
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
