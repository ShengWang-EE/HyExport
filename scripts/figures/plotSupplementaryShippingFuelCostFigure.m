function plotSupplementaryShippingFuelCostFigure(projectRoot)
% Plot route-level shipping fuel costs for the Supplementary Information.

projectRoot = setupHyExport(projectRoot);
load(fullfile(projectRoot, 'results', 'checkpoints', 'stop3.mat'), 'solution');

countryLabels = {'BE','DK','FR','DE','IE','NL','NO','PT','ES','SE','GB'};
yearLabels = [2030 2040 2050];
costMatrices = cellfun(@(s) s.shipHyFuelCostMatrix, solution, 'UniformOutput', false);
maxCost = max(cellfun(@(x) max(x(:), [], 'omitnan'), costMatrices));
colorMax = ceil(maxCost * 20) / 20;

fig = figure('Color', 'w', 'Units', 'centimeters', 'Position', [2 2 18 6.3]);
layout = tiledlayout(fig, 1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
colormap(fig, blueCostMap(256));

for k = 1:3
    ax = nexttile(layout, k);
    matrixData = costMatrices{k};
    imagesc(ax, matrixData, 'AlphaData', ~isnan(matrixData));
    hold(ax, 'on');
    ax.Color = [0.90 0.90 0.90];
    clim(ax, [0 colorMax]);
    axis(ax, 'square');
    box(ax, 'on');

    for gridLine = 0.5:1:(numel(countryLabels) + 0.5)
        plot(ax, [0.5 numel(countryLabels) + 0.5], [gridLine gridLine], ...
            'Color', [1 1 1], 'LineWidth', 0.45);
        plot(ax, [gridLine gridLine], [0.5 numel(countryLabels) + 0.5], ...
            'Color', [1 1 1], 'LineWidth', 0.45);
    end

    xticks(ax, 1:numel(countryLabels));
    yticks(ax, 1:numel(countryLabels));
    xticklabels(ax, countryLabels);
    if k == 1
        yticklabels(ax, countryLabels);
    else
        yticklabels(ax, repmat({''}, size(countryLabels)));
    end
    ax.TickLength = [0 0];
    ax.FontName = 'Arial';
    ax.FontSize = 7.5;
    ax.LineWidth = 0.8;
    ax.XTickLabelRotation = 45;
    title(ax, string(yearLabels(k)), 'FontSize', 9.5, 'FontWeight', 'bold');
    text(ax, -0.16, 1.08, char('a' + k - 1), 'Units', 'normalized', ...
        'FontName', 'Arial', 'FontSize', 10, 'FontWeight', 'bold');
end

xlabel(layout, 'To country', 'FontName', 'Arial', 'FontSize', 9);
ylabel(layout, 'From country', 'FontName', 'Arial', 'FontSize', 9);

cb = colorbar(ax);
cb.Layout.Tile = 'east';
cb.Label.String = 'Fuel cost (€ MWh^{-1})';
cb.Label.FontName = 'Arial';
cb.Label.FontSize = 9;
cb.FontName = 'Arial';
cb.FontSize = 8;
cb.LineWidth = 0.8;

rootFigurePath = fullfile(projectRoot, 'figs', 'fig shipping fuel cost.pdf');
suppFigurePath = fullfile(projectRoot, 'manuscript', 'supplementary', ...
    'J14___Supplementary_Information_v0_2', 'figs', 'fig shipping fuel cost.pdf');
exportgraphics(fig, rootFigurePath, 'ContentType', 'vector', 'BackgroundColor', 'white');
exportgraphics(fig, suppFigurePath, 'ContentType', 'vector', 'BackgroundColor', 'white');
close(fig);
end

function cmap = blueCostMap(n)
anchors = [
    0.96 0.98 1.00
    0.78 0.88 0.95
    0.42 0.68 0.84
    0.13 0.43 0.68
    0.03 0.19 0.42
    ];
x = linspace(0, 1, size(anchors, 1));
xi = linspace(0, 1, n);
cmap = interp1(x, anchors, xi);
end
