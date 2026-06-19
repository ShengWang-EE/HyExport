function plotMainCostFigures(projectRoot)
if nargin == 0
    projectRoot = setupHyExport();
else
    projectRoot = setupHyExport(projectRoot);
end

checkpointFile = fullfile(projectRoot, 'results', 'checkpoints', 'stop3.mat');
data = load(checkpointFile, 'LCOH', 'latGrid_mesh', 'lonGrid_mesh', ...
    'LCOHcurve2030', 'LCOHcurve2040', 'LCOHcurve2050');

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
fprintf('Stage 4/5: render Fig. 2 LCOH supply curves\n');
plotCostSupplyCurves(data, countryNames, shortNames, colors, figureDir, manuscriptFigureDir);
end

function plotLCOHMap(data, countryNames, shortNames, colors, figureDir, manuscriptFigureDir)
fprintf('Stage 4/5: load EEZ boundary for Fig. 1\n');
EUshpEEZ = getEUEEZ(resolveProjectFile('eez_v12.shp'), countryNames);

fig = figure('Color', 'w', 'Units', 'pixels', 'Position', [100, 100, 1040, 760], ...
    'Visible', 'off');

axMap = axes(fig, 'Position', [0.075, 0.30, 0.79, 0.64]);
hold(axMap, 'on');
colormap(axMap, parula(100));
for iCountry = 1:numel(countryNames)
    fprintf('Stage 4/5: draw LCOH surface %s\n', shortNames(iCountry));
    geoshow(axMap, data.latGrid_mesh{iCountry}, data.lonGrid_mesh{iCountry}, ...
        data.LCOH{iCountry}, 'DisplayType', 'surface');
end
hold(axMap, 'off');

set(axMap, 'FontName', 'Arial', 'FontSize', 8, 'LineWidth', 0.8, ...
    'TickDir', 'out', 'Layer', 'top');
box(axMap, 'on');
grid(axMap, 'on');
xlabel(axMap, 'Longitude');
ylabel(axMap, 'Latitude');
clim(axMap, [90 200]);
c = colorbar(axMap);
c.Label.String = 'LCOH (€/MWh)';
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
fileName = resolveProjectFile("EUclimate.nc");
lon = ncread(fileName, 'longitude');
latRaw = ncread(fileName, 'latitude');
lat = flip(latRaw);

minLon = min([countryEEZ.minLon]);
maxLon = max([countryEEZ.maxLon]);
minLat = min([countryEEZ.minLat]);
maxLat = max([countryEEZ.maxLat]);
minLonIndex = find(minLon >= lon, 1, 'last');
maxLonIndex = find(maxLon <= lon, 1, 'first');
minLatIndex = find(minLat >= lat, 1, 'last');
maxLatIndex = find(maxLat <= lat, 1, 'first');

nLon = maxLonIndex - minLonIndex + 1;
nLat = maxLatIndex - minLatIndex + 1;
rawLatStart = numel(latRaw) - maxLatIndex + 1;
spatialStride = 3;
timeStride = 24;
info = ncinfo(fileName, 'u100');
nLonSample = floor((nLon - 1) / spatialStride) + 1;
nLatSample = floor((nLat - 1) / spatialStride) + 1;
nTimeSample = floor((info.Size(3) - 1) / timeStride) + 1;

u100 = double(ncread(fileName, 'u100', [minLonIndex, rawLatStart, 1], ...
    [nLonSample, nLatSample, nTimeSample], [spatialStride, spatialStride, timeStride]));
v100 = double(ncread(fileName, 'v100', [minLonIndex, rawLatStart, 1], ...
    [nLonSample, nLatSample, nTimeSample], [spatialStride, spatialStride, timeStride]));
windSpeed = reshape(sqrt(flip(u100, 2).^2 + flip(v100, 2).^2), [], 1);
windSpeed(isnan(windSpeed)) = [];
sampleStride = max(1, ceil(numel(windSpeed) / 50000));
windSpeed = windSpeed(1:sampleStride:end);
[density, windGrid] = ksdensity(windSpeed);
end

function plotCostSupplyCurves(data, countryNames, shortNames, colors, figureDir, manuscriptFigureDir)
fig = figure('Color', 'w', 'Units', 'pixels', 'Position', [100, 100, 820, 390], ...
    'Visible', 'off');

curveSet = {data.LCOHcurve2030, data.LCOHcurve2040, data.LCOHcurve2050};
yearNames = ["2030", "2040", "2050"];
panelLetters = ["a", "b", "c"];
panelPositions = [
    0.075 0.19 0.275 0.61
    0.390 0.19 0.275 0.61
    0.705 0.19 0.275 0.61
    ];
highlightCountries = [2, 5, 6, 11];
targetCountries = [5, 11];
targetCapacities = [
    5 55
    20 80
    37 125
    ];

legendHandles = gobjects(1, numel(countryNames) + 1);
for iYear = 1:3
    ax = axes(fig, 'Position', panelPositions(iYear, :));
    hold(ax, 'on');
    bandHandle = fill(ax, [0, 130, 130, 0], [40, 40, 68.92, 68.92], ...
        [0.88, 0.88, 0.88], 'EdgeColor', 'none', 'FaceAlpha', 0.35, ...
        'DisplayName', 'Blue H_2 benchmark');

    countryHandles = gobjects(1, numel(countryNames));
    for iCountry = 1:numel(countryNames)
        lineWidth = 1.05;
        if ismember(iCountry, highlightCountries)
            lineWidth = 1.75;
        end
        countryHandles(iCountry) = plot(ax, curveSet{iYear}{iCountry}(:, 1) / 1e3, ...
            curveSet{iYear}{iCountry}(:, 2), 'LineWidth', lineWidth, ...
            'Color', colors(iCountry, :), 'DisplayName', char(shortNames(iCountry)));
    end

    for iTarget = 1:numel(targetCountries)
        iCountry = targetCountries(iTarget);
        capacityGW = targetCapacities(iYear, iTarget);
        curveNow = curveSet{iYear}{iCountry};
        [~, index] = min(abs(curveNow(:, 1) - capacityGW * 1e3));
        xValue = curveNow(index, 1) / 1e3;
        yValue = curveNow(index, 2);
        plot(ax, [xValue, xValue], [40, yValue], '--', 'LineWidth', 0.55, ...
            'Color', [0.45, 0.45, 0.45], 'HandleVisibility', 'off');
        plot(ax, [0, xValue], [yValue, yValue], '--', 'LineWidth', 0.55, ...
            'Color', [0.45, 0.45, 0.45], 'HandleVisibility', 'off');
        plot(ax, xValue, yValue, 'o', 'MarkerSize', 4.2, ...
            'MarkerEdgeColor', colors(iCountry, :), 'MarkerFaceColor', 'white', ...
            'LineWidth', 1, 'HandleVisibility', 'off');
    end

    set(ax, 'FontName', 'Arial', 'FontSize', 8, 'LineWidth', 0.8, ...
        'TickDir', 'out', 'YGrid', 'on', 'GridColor', [0.86, 0.86, 0.86], ...
        'GridAlpha', 0.45, 'Layer', 'top');
    box(ax, 'off');
    xlim(ax, [0, 130]);
    ylim(ax, [40, 140]);
    title(ax, yearNames(iYear), 'FontWeight', 'normal', 'FontName', 'Arial', 'FontSize', 9);
    text(ax, 0.02, 1.04, panelLetters(iYear), 'Units', 'normalized', ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', ...
        'FontWeight', 'bold', 'FontName', 'Arial', 'FontSize', 10);
    if iYear == 1
        ylabel(ax, 'LCOH (€/MWh)');
        legendHandles = [bandHandle, countryHandles];
    else
        ax.YTickLabel = [];
    end
    if iYear == 2
        xlabel(ax, 'Hydrogen production capacity (GW)');
    end
    hold(ax, 'off');
end

lgd = legend(legendHandles, ['Blue H_2 benchmark', cellstr(shortNames)], ...
    'NumColumns', 6, 'Box', 'off', 'FontName', 'Arial', 'FontSize', 7.2);
lgd.Units = 'normalized';
lgd.Position = [0.12, 0.845, 0.80, 0.075];

outputPdf = fullfile(figureDir, 'fig LCOH curves manu.pdf');
manuscriptPdf = fullfile(manuscriptFigureDir, 'fig_LCOH_curves_manu.pdf');
fprintf('Stage 4/5: export Fig. 2\n');
exportgraphics(fig, outputPdf, 'ContentType', 'vector');
copyfile(outputPdf, manuscriptPdf);
fileattrib(outputPdf, '-x');
fileattrib(manuscriptPdf, '-x');
close(fig);
end
