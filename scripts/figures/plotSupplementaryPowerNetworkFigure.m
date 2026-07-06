function plotSupplementaryPowerNetworkFigure()
projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(projectRoot);
projectRoot = setupHyExport(projectRoot);

dataFile = projectFile('tables', 'All Island Ten Year Transmission Statement-2021.xlsx');
outDir = projectFile('manuscript', 'supplementary', 'J14___Supplementary_Information_v0_2', 'figs');
outFile = fullfile(outDir, 'fig ireland power system2.pdf');

busData = readtable(dataFile, 'Sheet', 'bus name', 'Range', 'A2:D371', 'ReadVariableNames', false);
lineData = readtable(dataFile, 'Sheet', 'transmission system', 'Range', 'A4:N694', 'ReadVariableNames', false);

busCode = string(busData.Var1);
busLon = double(busData.Var3);
busLat = double(busData.Var4);

lineVoltage = double(lineData.Var1);
lineFrom = string(lineData.Var2);
lineTo = string(lineData.Var3);

hasEndpointCoordinates = ismember(lineFrom, busCode) & ismember(lineTo, busCode);
fprintf('Power network figure: %d circuit records, %d with endpoint coordinates, %d skipped because endpoint coordinates are missing.\n', ...
    height(lineData), nnz(hasEndpointCoordinates), nnz(~hasEndpointCoordinates));

fig = figure('Color', 'w', 'Units', 'centimeters', ...
    'Position', [3 3 12.8 13.2], 'Visible', 'off');
ax = axes(fig, 'Position', [0.12 0.16 0.78 0.78]);
hold(ax, 'on');
mapLonLim = [-10.8 -5.4];
mapLatLim = [51.25 55.45];

plotLandOutlines(ax, mapLonLim, mapLatLim);

voltages = [110 220 275 400];
lineColors = [0.78 0.78 0.78; 0.34 0.64 0.39; 0.30 0.48 0.78; 0.82 0.23 0.19];
lineWidths = [0.20 0.55 0.75 1.15];

for v = 1:numel(voltages)
    idx = find(lineVoltage == voltages(v) & hasEndpointCoordinates);
    for k = idx'
        if lineFrom(k) == lineTo(k)
            continue
        end
        fromIdx = find(busCode == lineFrom(k), 1);
        toIdx = find(busCode == lineTo(k), 1);
        if isempty(fromIdx) || isempty(toIdx)
            continue
        end
        lonPair = [busLon(fromIdx) busLon(toIdx)];
        latPair = [busLat(fromIdx) busLat(toIdx)];
        if any(lonPair < mapLonLim(1) | lonPair > mapLonLim(2) | latPair < mapLatLim(1) | latPair > mapLatLim(2))
            continue
        end
        plot(ax, lonPair, latPair, ...
            '-', 'Color', lineColors(v, :), 'LineWidth', lineWidths(v), 'Clipping', 'on');
    end
end

scatter(ax, busLon, busLat, 5.5, 'MarkerFaceColor', [0.10 0.10 0.10], ...
    'MarkerEdgeColor', 'w', 'LineWidth', 0.12);

labelCities(ax);
labelInterconnectors(ax);

legendHandles = gobjects(numel(voltages), 1);
for v = 1:numel(voltages)
    legendHandles(v) = plot(ax, nan, nan, '-', 'Color', lineColors(v, :), ...
        'LineWidth', max(lineWidths(v), 1.2));
end
legend(ax, legendHandles, {'110 kV', '220 kV', '275 kV', '400 kV'}, ...
    'Location', 'southoutside', 'Orientation', 'horizontal', ...
    'Box', 'off', 'FontSize', 7.5);

axis(ax, 'equal');
xlim(ax, mapLonLim);
ylim(ax, mapLatLim);
box(ax, 'on');
grid(ax, 'on');
ax.GridAlpha = 0.10;
ax.LineWidth = 0.7;
ax.FontName = 'Arial';
ax.FontSize = 7.5;
ax.TickDir = 'out';
xlabel(ax, 'Longitude');
ylabel(ax, 'Latitude');

exportgraphics(fig, outFile, 'ContentType', 'image', 'Resolution', 600);
exportgraphics(fig, replace(outFile, '.pdf', '.png'), 'Resolution', 300);
close(fig);
fprintf('Wrote %s\n', outFile);
end

function plotLandOutlines(ax, lonLim, latLim)
irl = shaperead(resolveProjectFile('gadm41_IRL_0.shp'));
gbr = shaperead(resolveProjectFile('gadm41_GBR_0.shp'));
mapshow(ax, [irl; gbr], 'DisplayType', 'polygon', ...
    'FaceColor', [0.97 0.97 0.95], ...
    'EdgeColor', 'none');
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
    plot(ax, x, y, '-', 'Color', [0.42 0.42 0.42], 'LineWidth', 0.30);
end
end

function labelCities(ax)
labels = {
    'Dublin', -6.02, 53.24
    'Belfast', -5.76, 54.70
    'Cork', -8.25, 51.78
    'Galway', -9.18, 53.24
    'Limerick', -8.72, 52.56
    };
for i = 1:size(labels, 1)
    text(ax, labels{i, 2}, labels{i, 3}, labels{i, 1}, 'FontSize', 5.6, ...
        'Color', [0.24 0.24 0.24], 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', 'Clipping', 'on');
end
end

function labelInterconnectors(ax)
text(ax, -5.94, 54.82, 'Moyle', 'FontSize', 5.0, 'Color', [0.28 0.28 0.28], ...
    'HorizontalAlignment', 'left', 'Clipping', 'on');
text(ax, -5.80, 53.48, 'EWIC', 'FontSize', 5.0, 'Color', [0.28 0.28 0.28], ...
    'HorizontalAlignment', 'left', 'Clipping', 'on');
end
