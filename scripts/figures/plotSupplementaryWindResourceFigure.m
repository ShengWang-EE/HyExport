function plotSupplementaryWindResourceFigure(projectRoot)
if nargin == 0
    projectRoot = setupHyExport();
else
    projectRoot = setupHyExport(projectRoot);
end

fprintf('Render supplementary wind-resource figure: load Ireland wind data\n');
countryNames = ["Belgium", "Denmark", "France", "Germany", "Ireland", ...
    "Netherlands", "Norway", "Portugal", "Spain", "Sweden", "United Kingdom"];
fprintf('  load EEZ shapefile\n');
EUshpEEZ = getEUEEZ(resolveProjectFile('eez_v12.shp'), countryNames);
countryEEZ = EUshpEEZ(strcmp(string({EUshpEEZ.TERRITORY1}), "Ireland"));
fprintf('  load mean wind surface\n');
[lonGrid, latGrid, meanWindSpeed, era5] = loadMeanWindSurface(countryEEZ, 300);
[maskLat, maskLon] = reducem(countryEEZ.Y(:), countryEEZ.X(:), 0.01);
inEEZ = inpolygon(lonGrid, latGrid, maskLon, maskLat);
meanWindSpeed(~inEEZ) = nan;
landMask = shapeMask(lonGrid, latGrid, resolveProjectFile('gadm41_IRL_0.shp'));
meanWindSpeed(landMask) = nan;

siteLonLat = [
    -6.0392226, 53.8153670;
    -5.9810554, 52.6492857;
    -7.8880785, 51.7834268;
    -9.9732611, 53.263192
    ];

[windSpeedBySite, windDirectionBySite] = loadSiteWindSeries(siteLonLat, era5);
mapColors = windSpeedMapColors(256);
roseColors = windSpeedMapColors(5);

fprintf('Render supplementary wind-resource figure: draw panels\n');
fig = figure('Color', 'w', 'Units', 'pixels', ...
    'Position', [100, 100, 1150, 780], 'Visible', 'off');
drawWindMap(fig, lonGrid, latGrid, meanWindSpeed, landMask, siteLonLat, mapColors);
drawWindRoseLegend(fig, roseColors);
drawWindRoses(fig, windSpeedBySite, windDirectionBySite, roseColors);
addPanelLabels(fig);

figureDir = fullfile(projectRoot, 'figs');
supplementaryFigureDir = fullfile(projectRoot, 'manuscript', 'supplementary', ...
    'J14___Supplementary_Information_v0_2', 'figs');
if exist(figureDir, 'dir') ~= 7
    mkdir(figureDir);
end
if exist(supplementaryFigureDir, 'dir') ~= 7
    mkdir(supplementaryFigureDir);
end

outputPdf = fullfile(figureDir, 'fig wind speed map.pdf');
supplementaryPdf = fullfile(supplementaryFigureDir, 'fig wind speed map.pdf');
fprintf('Render supplementary wind-resource figure: export PDF\n');
exportgraphics(fig, outputPdf, 'ContentType', 'image', 'Resolution', 450);
copyfile(outputPdf, supplementaryPdf);
fileattrib(outputPdf, '-x');
fileattrib(supplementaryPdf, '-x');
close(fig);
fprintf('Render supplementary wind-resource figure: done\n');
end

function [lonGrid, latGrid, meanWindSpeed, era5] = loadMeanWindSurface(countryEEZ, nGrid)
fileName = resolveProjectFile('EUclimate.nc');
fprintf('    read coordinate vectors\n');
lonAll = ncread(fileName, 'longitude');
latAllAscending = flip(ncread(fileName, 'latitude'));

minLonIndex = find(countryEEZ.minLon >= lonAll, 1, 'last');
maxLonIndex = find(countryEEZ.maxLon <= lonAll, 1, 'first');
minLatIndex = find(countryEEZ.minLat >= latAllAscending, 1, 'last');
maxLatIndex = find(countryEEZ.maxLat <= latAllAscending, 1, 'first');

nLon = maxLonIndex - minLonIndex + 1;
nLat = maxLatIndex - minLatIndex + 1;
rawLatStart = numel(latAllAscending) - maxLatIndex + 1;
sourceLon = lonAll(minLonIndex:maxLonIndex);
sourceLat = latAllAscending(minLatIndex:maxLatIndex);

fprintf('    read wind subset\n');
u100Raw = ncread(fileName, 'u100', [minLonIndex, rawLatStart, 1], [nLon, nLat, inf]);
v100Raw = ncread(fileName, 'v100', [minLonIndex, rawLatStart, 1], [nLon, nLat, inf]);
era5.lon = sourceLon;
era5.lat = sourceLat;
era5.u100 = flip(u100Raw, 2);
era5.v100 = flip(v100Raw, 2);
meanSource = mean(hypot(era5.u100, era5.v100), 3);

lonGridVector = linspace(countryEEZ.minLon, countryEEZ.maxLon, nGrid);
latGridVector = linspace(countryEEZ.minLat, countryEEZ.maxLat, nGrid);
[lonGrid, latGrid] = meshgrid(lonGridVector, latGridVector);

[sourceLonGrid, sourceLatGrid] = meshgrid(sourceLon, sourceLat);
fprintf('    interpolate mean wind surface\n');
meanWindSpeed = interp2(sourceLonGrid, sourceLatGrid, meanSource', lonGrid, latGrid);
end

function drawWindMap(fig, lonGrid, latGrid, meanWindSpeed, landMask, siteLonLat, mapColors)
fprintf('  draw wind-speed map\n');
minLon = min(lonGrid, [], 'all');
maxLon = max(lonGrid, [], 'all');
minLat = min(latGrid, [], 'all');
maxLat = max(latGrid, [], 'all');

ax = axes(fig, 'Position', [0.055, 0.165, 0.56, 0.735]);
colormap(ax, mapColors);
hold(ax, 'on');

windSurface = surface(ax, lonGrid, latGrid, zeros(size(meanWindSpeed)), meanWindSpeed, ...
    'EdgeColor', 'none', 'FaceColor', 'texturemap');
set(windSurface, 'AlphaData', double(~isnan(meanWindSpeed)), ...
    'FaceAlpha', 'texturemap', 'AlphaDataMapping', 'none');
clim(ax, [7.0, 12.0]);

% The wind surface and land mask define the study region. Planning-area
% polygons are drawn manually so multi-part shapefiles do not create spurious
% lines during PDF export.
contour(ax, lonGrid, latGrid, double(landMask), [0.5, 0.5], ...
    'Color', [0.25, 0.25, 0.25], 'LineWidth', 0.65);
drawAreaPatches(ax, resolveProjectFile('AquacultureSites.shp'), ...
    [0.78, 0.78, 0.78], 0.65);
drawAreaPatches(ax, resolveProjectFile('EMODnet_HA_MilitaryAreas_pg_20221216.shp'), ...
    [0.78, 0.78, 0.78], 0.65);
drawAreaOutlines(ax, resolveProjectFile('offshore areas (early planning).shp'), ...
    [0.03, 0.03, 0.03], 1.35);

plot(ax, siteLonLat(:, 1), siteLonLat(:, 2), 'o', 'MarkerSize', 10, ...
    'MarkerFaceColor', 'white', 'MarkerEdgeColor', [0.05, 0.05, 0.05], ...
    'LineWidth', 1.0);
for iSite = 1:size(siteLonLat, 1)
    text(ax, siteLonLat(iSite, 1), siteLonLat(iSite, 2), string(iSite), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'FontName', 'Arial', 'FontSize', 13, 'FontWeight', 'bold', ...
        'Color', [0.05, 0.05, 0.05]);
end
xlim(ax, [minLon, maxLon]);
ylim(ax, [minLat, maxLat]);
midLat = mean([minLat, maxLat]);
daspect(ax, [1 / cosd(midLat), 1, 1]);
box(ax, 'on');
grid(ax, 'on');
set(ax, 'FontName', 'Arial', 'FontSize', 16, 'LineWidth', 1.0, ...
    'GridLineStyle', ':', 'GridColor', [0.78, 0.78, 0.78], 'GridAlpha', 0.55, ...
    'TickDir', 'out');
ax.XTick = -15:2:-7;
ax.YTick = 50:2.5:55;
ax.XTickLabel = compose('%d° W', abs(ax.XTick));
ax.YTickLabel = compose('%.1f° N', ax.YTick);

c = colorbar(ax, 'southoutside');
c.Position = [0.205, 0.055, 0.29, 0.025];
title(c, 'Wind speed (m s^{-1})', 'FontName', 'Arial', 'FontSize', 15);
c.FontName = 'Arial';
c.FontSize = 16;
c.Ticks = 7:1:12;
hold(ax, 'off');
end

function mask = shapeMask(lonGrid, latGrid, fileName)
shapes = shaperead(fileName);
mask = false(size(lonGrid));
for iShape = 1:numel(shapes)
    x = shapes(iShape).X;
    y = shapes(iShape).Y;
    nanBreaks = [0, find(isnan(x) | isnan(y)), numel(x) + 1];
    for iPart = 1:numel(nanBreaks) - 1
        idx = nanBreaks(iPart) + 1:nanBreaks(iPart + 1) - 1;
        if numel(idx) >= 3
            mask = mask | inpolygon(lonGrid, latGrid, x(idx), y(idx));
        end
    end
end
end

function drawAreaPatches(ax, fileName, faceColor, faceAlpha)
shapes = shaperead(fileName);
lonLim = xlim(ax);
latLim = ylim(ax);
for iShape = 1:numel(shapes)
    x = shapes(iShape).X;
    y = shapes(iShape).Y;
    if max(x, [], 'omitnan') < lonLim(1) || min(x, [], 'omitnan') > lonLim(2) || ...
            max(y, [], 'omitnan') < latLim(1) || min(y, [], 'omitnan') > latLim(2)
        continue
    end
    nanBreaks = [0, find(isnan(x) | isnan(y)), numel(x) + 1];
    for iPart = 1:numel(nanBreaks) - 1
        idx = nanBreaks(iPart) + 1:nanBreaks(iPart + 1) - 1;
        if numel(idx) >= 3
            patch(ax, x(idx), y(idx), faceColor, 'EdgeColor', 'none', ...
                'FaceAlpha', faceAlpha);
        end
    end
end
end

function drawAreaOutlines(ax, fileName, edgeColor, lineWidth)
shapes = shaperead(fileName);
for iShape = 1:numel(shapes)
    x = shapes(iShape).X;
    y = shapes(iShape).Y;
    nanBreaks = [0, find(isnan(x) | isnan(y)), numel(x) + 1];
    for iPart = 1:numel(nanBreaks) - 1
        idx = nanBreaks(iPart) + 1:nanBreaks(iPart + 1) - 1;
        if numel(idx) >= 2
            plot(ax, x(idx), y(idx), '-', 'Color', edgeColor, 'LineWidth', lineWidth);
        end
    end
end
end

function drawWindRoseLegend(fig, roseColors)
ax = axes(fig, 'Position', [0.610, 0.560, 0.080, 0.330]);
axis(ax, 'off');
xlim(ax, [0, 1]);
ylim(ax, [0, 1]);
speedLabels = {'<7', '7-8', '8-9', '9-10', '>10'};
text(ax, 0.02, 1.00, 'Wind speed', 'Units', 'normalized', ...
    'FontName', 'Arial', 'FontSize', 13, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
text(ax, 0.02, 0.91, '(m s^{-1})', 'Units', 'normalized', ...
    'FontName', 'Arial', 'FontSize', 13, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
for iSpeed = 1:numel(speedLabels)
    y0 = 0.73 - (iSpeed - 1) * 0.15;
    patch(ax, [0.04, 0.22, 0.22, 0.04], [y0, y0, y0 + 0.09, y0 + 0.09], ...
        roseColors(iSpeed, :), 'EdgeColor', 'none');
    text(ax, 0.31, y0 + 0.045, speedLabels{iSpeed}, 'Units', 'normalized', ...
        'FontName', 'Arial', 'FontSize', 13, 'VerticalAlignment', 'middle');
end
end

function drawWindRoses(fig, windSpeedBySite, windDirectionBySite, roseColors)
fprintf('  draw wind roses\n');
rosePositions = [
    0.698, 0.698, 0.178, 0.178;
    0.698, 0.500, 0.178, 0.178;
    0.698, 0.302, 0.178, 0.178;
    0.698, 0.104, 0.178, 0.178
    ];
speedEdges = [0, 7, 8, 9, 10, inf];
for iSite = 1:4
    ax = axes(fig, 'Position', rosePositions(iSite, :));
    plotWindRose(ax, windDirectionBySite(:, iSite), windSpeedBySite(:, iSite), ...
        speedEdges, roseColors);
    text(ax, -1.10, 1.10, string(iSite), 'FontName', 'Arial', 'FontSize', 16, ...
        'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'top');
end
end

function addPanelLabels(fig)
annotation(fig, 'textbox', [0.010, 0.925, 0.03, 0.035], ...
    'String', 'a', 'EdgeColor', 'none', 'FontName', 'Arial', ...
    'FontSize', 18, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
annotation(fig, 'textbox', [0.610, 0.925, 0.03, 0.035], ...
    'String', 'b', 'EdgeColor', 'none', 'FontName', 'Arial', ...
    'FontSize', 18, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
end

function [windSpeedBySite, windDirectionBySite] = loadSiteWindSeries(siteLonLat, era5)
fprintf('  interpolate site wind series\n');
nHour = size(era5.u100, 3);
nSite = size(siteLonLat, 1);
windSpeedBySite = zeros(nHour, nSite);
windDirectionBySite = zeros(nHour, nSite);
for iSite = 1:nSite
    lonNow = siteLonLat(iSite, 1);
    latNow = siteLonLat(iSite, 2);
    iLon = find(era5.lon <= lonNow, 1, 'last');
    iLat = find(era5.lat <= latNow, 1, 'last');
    lonWeight = (lonNow - era5.lon(iLon)) / (era5.lon(iLon + 1) - era5.lon(iLon));
    latWeight = (latNow - era5.lat(iLat)) / (era5.lat(iLat + 1) - era5.lat(iLat));

    uNow = bilinearTimeSeries(era5.u100, iLon, iLat, lonWeight, latWeight);
    vNow = bilinearTimeSeries(era5.v100, iLon, iLat, lonWeight, latWeight);
    windSpeedBySite(:, iSite) = hypot(uNow, vNow);
    windDirectionBySite(:, iSite) = mod(atan2d(uNow, vNow), 360);
end
end

function series = bilinearTimeSeries(data, iLon, iLat, lonWeight, latWeight)
series = (1 - lonWeight) * (1 - latWeight) * squeeze(data(iLon, iLat, :)) + ...
    lonWeight * (1 - latWeight) * squeeze(data(iLon + 1, iLat, :)) + ...
    (1 - lonWeight) * latWeight * squeeze(data(iLon, iLat + 1, :)) + ...
    lonWeight * latWeight * squeeze(data(iLon + 1, iLat + 1, :));
end

function plotWindRose(ax, directionDeg, windSpeed, speedEdges, roseColors)
directionEdges = linspace(0, 360, 17);
freq = zeros(numel(directionEdges) - 1, numel(speedEdges) - 1);
valid = ~isnan(directionDeg) & ~isnan(windSpeed);
directionDeg = mod(directionDeg(valid), 360);
windSpeed = windSpeed(valid);
for iDir = 1:size(freq, 1)
    inDirection = directionDeg >= directionEdges(iDir) & directionDeg < directionEdges(iDir + 1);
    for iSpeed = 1:size(freq, 2)
        inSpeed = windSpeed >= speedEdges(iSpeed) & windSpeed < speedEdges(iSpeed + 1);
        freq(iDir, iSpeed) = 100 * sum(inDirection & inSpeed) / numel(windSpeed);
    end
end

cla(ax);
hold(ax, 'on');
axis(ax, 'equal');
axis(ax, 'off');
rMax = ceil(max(sum(freq, 2)) / 5) * 5;
thetaGrid = linspace(0, 360, 181);
for r = linspace(rMax / 3, rMax, 3)
    plot(ax, r * sind(thetaGrid), r * cosd(thetaGrid), '-', ...
        'Color', [0.78, 0.78, 0.78], 'LineWidth', 0.45);
end
for theta = 0:45:315
    plot(ax, [0, rMax * 1.05 * sind(theta)], [0, rMax * 1.05 * cosd(theta)], '-', ...
        'Color', [0.86, 0.86, 0.86], 'LineWidth', 0.45);
end

for iDir = 1:size(freq, 1)
    rInner = 0;
    theta = linspace(directionEdges(iDir), directionEdges(iDir + 1), 8);
    for iSpeed = 1:size(freq, 2)
        rOuter = rInner + freq(iDir, iSpeed);
        if rOuter > rInner
            x = [rInner * sind(theta), fliplr(rOuter * sind(theta))];
            y = [rInner * cosd(theta), fliplr(rOuter * cosd(theta))];
            patch(ax, x, y, roseColors(iSpeed, :), 'EdgeColor', 'white', ...
                'LineWidth', 0.15, 'FaceAlpha', 0.88);
        end
        rInner = rOuter;
    end
end
text(ax, 0, rMax * 1.17, 'N', 'HorizontalAlignment', 'center', ...
    'FontName', 'Arial', 'FontSize', 15);
text(ax, rMax * 1.17, 0, 'E', 'HorizontalAlignment', 'center', ...
    'FontName', 'Arial', 'FontSize', 15);
text(ax, 0, -rMax * 1.17, 'S', 'HorizontalAlignment', 'center', ...
    'FontName', 'Arial', 'FontSize', 15);
text(ax, -rMax * 1.17, 0, 'W', 'HorizontalAlignment', 'center', ...
    'FontName', 'Arial', 'FontSize', 15);
xlim(ax, [-rMax, rMax] * 1.30);
ylim(ax, [-rMax, rMax] * 1.30);
hold(ax, 'off');
end

function colors = windSpeedMapColors(nColor)
stops = [
    0.16, 0.28, 0.74
    0.12, 0.62, 0.90
    0.18, 0.80, 0.72
    0.55, 0.84, 0.42
    0.98, 0.86, 0.35
    0.96, 0.47, 0.24
    0.80, 0.05, 0.05
    ];
x = linspace(0, 1, size(stops, 1));
xi = linspace(0, 1, nColor);
colors = interp1(x, stops, xi, 'pchip');
colors = max(min(colors, 1), 0);
end
