function plotMainCostFigures(projectRoot)
if nargin == 0
    projectRoot = setupHyExport();
else
    projectRoot = setupHyExport(projectRoot);
end

checkpointFile = fullfile(projectRoot, 'results', 'checkpoints', 'stop3.mat');
mapFile = fullfile(projectRoot, 'results', 'checkpoints', 'fig1_lcoh_map_highres.mat');
data = load(checkpointFile, 'LCOH', 'latGrid_mesh', 'lonGrid_mesh');
mapData = load(mapFile, 'LCOH_map', 'latGrid_mesh_map', 'lonGrid_mesh_map');
data.LCOH = mapData.LCOH_map;
data.latGrid_mesh = mapData.latGrid_mesh_map;
data.lonGrid_mesh = mapData.lonGrid_mesh_map;

figureDir = fullfile(projectRoot, 'figs');
manuscriptFigureDir = fullfile(projectRoot, 'manuscript', 'figs');
if exist(figureDir, 'dir') ~= 7
    mkdir(figureDir);
end
if exist(manuscriptFigureDir, 'dir') ~= 7
    mkdir(manuscriptFigureDir);
end

countryNames = ["Belgium", "Denmark", "France", "Germany", "Ireland", ...
    "Netherlands", "Norway", "Portugal", "Spain", "Sweden", "United Kingdom"];
shortNames = ["BE", "DK", "FR", "DE", "IE", "NL", "NO", "PT", "ES", "SE", "GB"];
colors = generateColorData('gem12');

fprintf('Stage 4/5: render Fig. 1 LCOH map\n');
plotLCOHMap(data, countryNames, shortNames, colors, figureDir, manuscriptFigureDir);
fprintf('Stage 4/5: sync restored Fig. 2 LCOH supply curves\n');
syncRestoredCostSupplyFigure(figureDir, manuscriptFigureDir);
end

function plotLCOHMap(data, countryNames, shortNames, colors, figureDir, manuscriptFigureDir)
fprintf('Stage 4/5: load EEZ boundary for Fig. 1\n');
EUshpEEZ = getEUEEZ(resolveProjectFile('eez_v12.shp'), countryNames);

fig = figure('Color', 'w', 'Units', 'pixels', 'Position', [100, 100, 1040, 760], ...
    'Visible', 'off');

axMap = axes(fig, 'Position', [0.075, 0.30, 0.79, 0.64]);
hold(axMap, 'on');
colormap(axMap, nclCM(15, 100));
for iCountry = 1:numel(countryNames)
    fprintf('Stage 4/5: draw LCOH surface %s\n', shortNames(iCountry));
    geoshow(axMap, data.latGrid_mesh{iCountry}, data.lonGrid_mesh{iCountry}, ...
        data.LCOH{iCountry}, 'DisplayType', 'surface');
end
plotEEZBoundaries(axMap, EUshpEEZ);
plotCountryOutlines(axMap);
hold(axMap, 'off');

set(axMap, 'FontName', 'Arial', 'FontSize', 8, 'LineWidth', 0.8, ...
    'TickDir', 'out', 'Layer', 'top');
box(axMap, 'on');
grid(axMap, 'on');
xlabel(axMap, 'Longitude');
ylabel(axMap, 'Latitude');
clim(axMap, [90 200]);
c = colorbar(axMap);
c.Label.String = 'LCOH (€ MWh^{-1})';
c.Label.FontName = 'Arial';
c.FontName = 'Arial';
c.FontSize = 8;
c.Ticks = [90 110 130 150 170 190 200];
c.TickLabels = {'90', '110', '130', '150', '170', '190', '>200'};
c.Position = [0.895, 0.36, 0.018, 0.48];
axMap.Position = [0.075, 0.30, 0.79, 0.64];

countryLabelPositions = [
    0.37 0.50
    0.44 0.59
    0.22 0.39
    0.38 0.55
    0.10 0.50
    0.43 0.56
    0.38 0.77
    0.12 0.18
    0.12 0.30
    0.61 0.62
    0.30 0.62
    ];
for iCountry = 1:numel(countryNames)
    text(axMap, countryLabelPositions(iCountry, 1), countryLabelPositions(iCountry, 2), ...
        shortNames(iCountry), 'Units', 'normalized', 'VerticalAlignment', 'middle', ...
        'HorizontalAlignment', 'center', 'Color', 'white', 'FontWeight', 'bold', ...
        'FontName', 'Arial', 'FontSize', 8.5);
end
text(axMap, -0.055, 1.045, 'a', 'Units', 'normalized', ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', ...
    'FontWeight', 'bold', 'FontName', 'Arial', 'FontSize', 10);

annotation(fig, 'textbox', [0.055, 0.235, 0.03, 0.03], 'String', 'b', ...
    'EdgeColor', 'none', 'FontName', 'Arial', 'FontSize', 10, 'FontWeight', 'bold');
annotation(fig, 'textbox', [0.39, 0.015, 0.24, 0.03], ...
    'String', 'Wind speed (m s^{-1})', 'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', 'FontName', 'Arial', 'FontSize', 8);

for iCountry = 1:numel(countryNames)
    countryEEZ = EUshpEEZ(strcmp(string({EUshpEEZ.TERRITORY1}), countryNames(iCountry)));
    fprintf('Stage 4/5: wind-speed density %s\n', shortNames(iCountry));
    [density, windGrid] = countryWindSpeedDensity(countryEEZ);

    columnIndex = mod(iCountry - 1, 6);
    rowIndex = floor((iCountry - 1) / 6);
    left = 0.08 + columnIndex * 0.135 + rowIndex * 0.0675;
    bottom = 0.175 - rowIndex * 0.105;
    axDensity = axes(fig, 'Position', [left, bottom, 0.118, 0.060]);
    hold(axDensity, 'on');
    densityArea = area(axDensity, windGrid, density);
    densityArea.FaceColor = colors(iCountry, :);
    densityArea.FaceAlpha = 0.15;
    densityArea.EdgeColor = colors(iCountry, :);
    densityArea.LineWidth = 0.8;
    [maxDensity, maxIndex] = max(density);
    plot(axDensity, [windGrid(maxIndex), windGrid(maxIndex)], [0, maxDensity], ...
        '-', 'LineWidth', 0.5, 'Color', [0.45, 0.45, 0.45]);
    text(axDensity, 0.97, 0.92, shortNames(iCountry), 'Units', 'normalized', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
        'FontName', 'Arial', 'FontSize', 7, 'FontWeight', 'bold');
    hold(axDensity, 'off');

    set(axDensity, 'FontName', 'Arial', 'FontSize', 6.5, 'LineWidth', 0.55, ...
        'TickDir', 'out', 'YTick', []);
    box(axDensity, 'off');
    xlim(axDensity, [0, 20]);
    ylim(axDensity, [0, 0.15]);
    axDensity.XTick = [0, 10, 20];
    if rowIndex == 0
        axDensity.XTickLabel = [];
    end
end

outputPdf = fullfile(figureDir, 'fig LCOH map manu.pdf');
manuscriptPdf = fullfile(manuscriptFigureDir, 'fig_LCOH_map_manu.pdf');
fprintf('Stage 4/5: export Fig. 1\n');
exportgraphics(fig, outputPdf, 'ContentType', 'image', 'Resolution', 600);
copyfile(outputPdf, manuscriptPdf);
fileattrib(outputPdf, '-x');
fileattrib(manuscriptPdf, '-x');
close(fig);
end

function [density, windGrid] = countryWindSpeedDensity(countryEEZ)
climate = loadCountryClimate(countryEEZ, 100);
windSpeed = reshape(climate.windSpeed, [], 1);
windSpeed(isnan(windSpeed)) = [];
[density, windGrid] = ksdensity(windSpeed);
end

function plotCountryOutlines(axMap)
lonLim = xlim(axMap);
latLim = ylim(axMap);
landAreas = shaperead('landareas.shp', 'UseGeoCoords', true);
bounds = cat(3, landAreas.BoundingBox);
inView = squeeze(bounds(1, 1, :) <= lonLim(2) & bounds(2, 1, :) >= lonLim(1) & ...
    bounds(1, 2, :) <= latLim(2) & bounds(2, 2, :) >= latLim(1));
geoshow(axMap, landAreas(inView), 'DisplayType', 'polygon', 'FaceColor', 'none', ...
    'EdgeColor', [0.22, 0.22, 0.22], 'LineWidth', 0.45);
xlim(axMap, lonLim);
ylim(axMap, latLim);
end

function plotEEZBoundaries(axMap, EUshpEEZ)
lonLim = xlim(axMap);
latLim = ylim(axMap);
for iCountry = 1:numel(EUshpEEZ)
    plot(axMap, EUshpEEZ(iCountry).X, EUshpEEZ(iCountry).Y, '-', ...
        'Color', [1, 1, 1], 'LineWidth', 0.8);
end
xlim(axMap, lonLim);
ylim(axMap, latLim);
end

function [latFine, lonFine, lcohFine] = interpolateLCOHMap(latGrid, lonGrid, lcohGrid, scaleFactor)
[nRow, nCol] = size(lcohGrid);
[colGrid, rowGrid] = meshgrid(1:nCol, 1:nRow);
[colFine, rowFine] = meshgrid(linspace(1, nCol, (nCol - 1) * scaleFactor + 1), ...
    linspace(1, nRow, (nRow - 1) * scaleFactor + 1));

latFine = interp2(colGrid, rowGrid, latGrid, colFine, rowFine, 'linear');
lonFine = interp2(colGrid, rowGrid, lonGrid, colFine, rowFine, 'linear');
valid = ~isnan(lcohGrid);
computedFine = interp2(colGrid, rowGrid, double(valid), colFine, rowFine, 'nearest') > 0;
lcohFine = interp2(colGrid, rowGrid, lcohGrid, colFine, rowFine, 'nearest');

neighbourCount = conv2(double(valid), ones(3), 'same');
fillableBlank = ~valid & neighbourCount >= 5;
fillableFine = interp2(colGrid, rowGrid, double(fillableBlank), colFine, rowFine, 'nearest') > 0;
fillableFine = fillableFine & ~computedFine;

if any(fillableFine(:))
    fillInterpolant = scatteredInterpolant(colGrid(valid), rowGrid(valid), lcohGrid(valid), ...
        'natural', 'none');
    colFill = colFine(fillableFine);
    rowFill = rowFine(fillableFine);
    fillValues = fillInterpolant(colFill, rowFill);
    missingFill = isnan(fillValues);
    if any(missingFill)
        nearestInterpolant = scatteredInterpolant(colGrid(valid), rowGrid(valid), lcohGrid(valid), ...
        'nearest', 'nearest');
        fillValues(missingFill) = nearestInterpolant(colFill(missingFill), rowFill(missingFill));
    end
    lcohFine(fillableFine) = fillValues;
end
lcohFine(~(computedFine | fillableFine)) = nan;
end

function syncRestoredCostSupplyFigure(figureDir, manuscriptFigureDir)
sourcePdf = fullfile(figureDir, 'fig LCOH curves manu.pdf');
manuscriptPdf = fullfile(manuscriptFigureDir, 'fig_LCOH_curves_manu.pdf');
copyfile(sourcePdf, manuscriptPdf);
fileattrib(manuscriptPdf, '-x');
end
