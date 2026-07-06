function plotSupplementaryGasNetworkFigure()
projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(projectRoot);
projectRoot = setupHyExport(projectRoot);

load(projectFile('results', 'checkpoints', 'mpcIreland.mat'), 'mpc');
busTable = readtable(projectFile('tables', 'Irish energy system data.xlsx'), ...
    'Sheet', 'Gbus', 'Range', 'A1:I145');

lon = table2array(busTable(:, 8));
lat = table2array(busTable(:, 9));
demand = mpc.Gbus(:, 3);

outDir = projectFile('manuscript', 'supplementary', ...
    'J14___Supplementary_Information_v0_2', 'figs');
outFile = fullfile(outDir, 'fig ireland gas system.pdf');

fig = figure('Color', 'w', 'Units', 'centimeters', ...
    'Position', [3 3 11.6 9.4], 'Visible', 'off');
ax = axes(fig, 'Position', [0.105 0.135 0.715 0.805]);
hold(ax, 'on');

lonLim = [-10.45 -5.45];
latLim = [51.45 55.35];
plotLandOutlines(ax, lonLim, latLim);
plotGasPipelines(ax, mpc.Gline, lon, lat, lonLim, latLim);
plotGasNodes(ax, lon, lat, demand);
labelMajorDemandNodes(ax);
labelExternalImport(ax);

axis(ax, 'equal');
xlim(ax, lonLim);
ylim(ax, latLim);
box(ax, 'on');
grid(ax, 'on');
ax.GridAlpha = 0.07;
ax.LineWidth = 0.65;
ax.FontName = 'Arial';
ax.FontSize = 7.2;
ax.TickDir = 'out';
xlabel(ax, 'Longitude');
ylabel(ax, 'Latitude');
colormap(ax, gasDemandColormap(256));
clim(ax, [0 4.2]);

c = colorbar(ax);
c.Position = [0.855 0.235 0.028 0.575];
c.Label.String = 'Gas demand (Mm^3 day^{-1})';
c.Label.FontName = 'Arial';
c.FontName = 'Arial';
c.FontSize = 7.0;
c.Ticks = 0:1:4;

exportgraphics(fig, outFile, 'ContentType', 'image', 'Resolution', 600);
exportgraphics(fig, replace(outFile, '.pdf', '.png'), 'Resolution', 300);
copyfile(outFile, projectFile('figs', 'fig ireland gas system.pdf'));
close(fig);
fprintf('Wrote %s\n', outFile);
end

function plotLandOutlines(ax, lonLim, latLim)
irl = shaperead(resolveProjectFile('gadm41_IRL_0.shp'));
gbr = shaperead(resolveProjectFile('gadm41_GBR_0.shp'));
mapshow(ax, [irl; gbr], 'DisplayType', 'polygon', ...
    'FaceColor', [0.975 0.975 0.960], 'EdgeColor', 'none');
plotShapeBoundaries(ax, [irl; gbr]);
xlim(ax, lonLim);
ylim(ax, latLim);
end

function plotShapeBoundaries(ax, shapes)
for iShape = 1:numel(shapes)
    x = shapes(iShape).X;
    y = shapes(iShape).Y;
    segmentLength = hypot(diff(x), diff(y));
    breakIndex = [false, segmentLength > 0.35 | isnan(segmentLength)];
    x(breakIndex) = nan;
    y(breakIndex) = nan;
    plot(ax, x, y, '-', 'Color', [0.48 0.48 0.48], 'LineWidth', 0.24);
end
end

function plotGasPipelines(ax, gasLines, lon, lat, lonLim, latLim)
for iLine = 1:size(gasLines, 1)
    fromBus = gasLines(iLine, 1);
    toBus = gasLines(iLine, 2);
    lonPair = [lon(fromBus), lon(toBus)];
    latPair = [lat(fromBus), lat(toBus)];
    outside = any(lonPair < lonLim(1) | lonPair > lonLim(2) | latPair < latLim(1) | latPair > latLim(2));
    if outside
        plot(ax, lonPair, latPair, '--', 'Color', [0.68 0.70 0.72], ...
            'LineWidth', 0.48, 'Clipping', 'on');
    else
        plot(ax, lonPair, latPair, '-', 'Color', [0.35 0.38 0.40], ...
            'LineWidth', 0.52, 'Clipping', 'on');
    end
end
end

function plotGasNodes(ax, lon, lat, demand)
isDemand = demand > 0;
scatter(ax, lon(~isDemand), lat(~isDemand), 10, ...
    'MarkerFaceColor', [0.18 0.18 0.18], ...
    'MarkerEdgeColor', 'w', 'LineWidth', 0.15);

nodeSize = 14 + 58 * sqrt(demand(isDemand) ./ max(demand));
scatter(ax, lon(isDemand), lat(isDemand), nodeSize, demand(isDemand), ...
    'filled', 'MarkerEdgeColor', [0.12 0.12 0.12], ...
    'LineWidth', 0.25);
end

function labelMajorDemandNodes(ax)
labels = {
    'Dublin', -5.98, 53.34
    'Belfast', -5.82, 54.63
    'Cork', -8.36, 51.84
    'Limerick', -8.86, 52.56
    'Galway', -9.24, 53.22
    };
for i = 1:size(labels, 1)
    text(ax, labels{i, 2}, labels{i, 3}, labels{i, 1}, ...
        'FontName', 'Arial', 'FontSize', 5.6, 'FontWeight', 'bold', ...
        'Color', [0.18 0.18 0.18], 'HorizontalAlignment', 'center', ...
        'Clipping', 'on');
end
end

function labelExternalImport(ax)
text(ax, -5.52, 55.10, 'to Moffat', ...
    'FontName', 'Arial', 'FontSize', 5.6, 'FontWeight', 'bold', ...
    'Color', [0.36 0.38 0.40], 'HorizontalAlignment', 'right', ...
    'Clipping', 'on');
end

function cmap = gasDemandColormap(n)
anchors = [
    0.92 0.96 1.00
    0.60 0.78 0.92
    0.26 0.55 0.76
    0.96 0.70 0.35
    0.82 0.22 0.18
    ];
x = linspace(0, 1, size(anchors, 1));
xi = linspace(0, 1, n);
cmap = interp1(x, anchors, xi, 'pchip');
cmap = max(0, min(1, cmap));
end
