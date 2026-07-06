function plotSupplementaryDistanceToPortFigure(projectRoot)
if nargin == 0
    projectRoot = setupHyExport();
else
    projectRoot = setupHyExport(projectRoot);
end

countryNames = ["Belgium", "Denmark", "France", "Germany", "Ireland", ...
    "Netherlands", "Norway", "Portugal", "Spain", "Sweden", "United Kingdom"];
nCountry = numel(countryNames);

fprintf('Render supplementary distance-to-port figure: load ports and EEZ boundaries\n');
[~, ferryPortShp, ~, ~] = loadFerryPort(resolveProjectFile('EMODnet_HA_Main_Ports_20231106.shp'), nCountry);
EUshpEEZ = getEUEEZ(resolveProjectFile('eez_v12.shp'), countryNames);
data = load(fullfile(projectRoot, 'results', 'checkpoints', 'stop3.mat'), ...
    'distanceToPort', 'latGrid_mesh', 'lonGrid_mesh');

EU.minLon = -16.1;
EU.maxLon = 36.5;
EU.minLat = 34.8;
EU.maxLat = 74.6;
portLon = [ferryPortShp.X];
portLat = [ferryPortShp.Y];

fprintf('Render supplementary distance-to-port figure: draw and export\n');
fig = figure('Color', 'w', 'Units', 'pixels', ...
    'Position', [100, 100, 980, 720], 'Visible', 'off');
ax = axes(fig, 'Position', [0.095, 0.12, 0.74, 0.78]);
hold(ax, 'on');

for iCountry = 1:nCountry
    distanceToPortKm = data.distanceToPort{iCountry} / 1000;
    countryEEZ = EUshpEEZ(strcmp(string({EUshpEEZ.TERRITORY1}), countryNames(iCountry)));
    inCountryEEZ = inpolygon(data.lonGrid_mesh{iCountry}, data.latGrid_mesh{iCountry}, ...
        countryEEZ.X, countryEEZ.Y);
    distanceToPortKm(~inCountryEEZ) = nan;
    surface(ax, data.lonGrid_mesh{iCountry}, data.latGrid_mesh{iCountry}, ...
        zeros(size(distanceToPortKm)), distanceToPortKm, ...
        'EdgeColor', 'none', 'FaceColor', 'texturemap', ...
        'AlphaData', ~isnan(distanceToPortKm), 'FaceAlpha', 'texturemap');
end
colormap(ax, distanceToPortColormap(256));
clim(ax, [0, 650]);

plotEEZBoundaries(ax, EUshpEEZ);
plotLandOutlines(ax);
scatter(ax, portLon, portLat, 18, 'o', ...
    'MarkerFaceColor', [0.08, 0.08, 0.08], ...
    'MarkerEdgeColor', 'w', 'LineWidth', 0.35, ...
    'MarkerFaceAlpha', 0.82, 'MarkerEdgeAlpha', 0.85);

hold(ax, 'off');
box(ax, 'on');
grid(ax, 'on');
set(ax, 'FontName', 'Arial', 'FontSize', 11, 'LineWidth', 0.9, ...
    'TickDir', 'out', 'Layer', 'top', 'GridColor', [0.82, 0.82, 0.82], ...
    'GridAlpha', 0.45, 'MinorGridAlpha', 0.2);
xlim(ax, [EU.minLon, EU.maxLon]);
ylim(ax, [EU.minLat, EU.maxLat]);
xticks(ax, -20:10:40);
yticks(ax, 35:10:75);
xlabel(ax, 'Longitude');
ylabel(ax, 'Latitude');
pbaspect(ax, [1.18, 1, 1]);

c = colorbar(ax);
c.Position = [0.865, 0.19, 0.026, 0.62];
c.Label.String = 'Distance to nearest major port (km)';
c.Label.FontName = 'Arial';
c.FontName = 'Arial';
c.FontSize = 10.5;
c.Ticks = 0:100:600;
c.TickLabels = {'0', '100', '200', '300', '400', '500', '>600'};

figureDir = fullfile(projectRoot, 'figs');
suppFigureDir = fullfile(projectRoot, 'manuscript', 'supplementary', ...
    'J14___Supplementary_Information_v0_2', 'figs');
if exist(figureDir, 'dir') ~= 7
    mkdir(figureDir);
end
if exist(suppFigureDir, 'dir') ~= 7
    mkdir(suppFigureDir);
end

outputPdf = fullfile(figureDir, 'fig distance to port.pdf');
outputPng = fullfile(figureDir, 'preview_distance_to_port.png');
suppPdf = fullfile(suppFigureDir, 'fig distance to port.pdf');
exportgraphics(fig, outputPdf, 'ContentType', 'image', 'Resolution', 600);
exportgraphics(fig, outputPng, 'Resolution', 300);
copyfile(outputPdf, suppPdf);
close(fig);
end

function cmap = distanceToPortColormap(n)
anchors = [
    0.10, 0.28, 0.74
    0.08, 0.62, 0.86
    0.26, 0.78, 0.67
    0.78, 0.86, 0.42
    0.98, 0.72, 0.28
    0.88, 0.24, 0.17
    ];
x = linspace(0, 1, size(anchors, 1));
xi = linspace(0, 1, n);
cmap = interp1(x, anchors, xi, 'pchip');
cmap = max(0, min(1, cmap));
end

function plotEEZBoundaries(ax, EUshpEEZ)
for iCountry = 1:numel(EUshpEEZ)
    [xBoundary, yBoundary] = cleanBoundaryLine(EUshpEEZ(iCountry).X, EUshpEEZ(iCountry).Y);
    plot(ax, xBoundary, yBoundary, '-', 'Color', [1, 1, 1], 'LineWidth', 0.9);
    plot(ax, xBoundary, yBoundary, '-', 'Color', [0.25, 0.25, 0.25], 'LineWidth', 0.25);
end
end

function [xClean, yClean] = cleanBoundaryLine(x, y)
segmentLength = hypot(diff(x), diff(y));
breakIndex = [false, segmentLength > 3.5 | isnan(segmentLength)];
xClean = x;
yClean = y;
xClean(breakIndex) = nan;
yClean(breakIndex) = nan;

keepIndex = false(size(xClean));
keepIndex(1:4:end) = true;
keepIndex(isnan(xClean) | isnan(yClean)) = true;
xClean = xClean(keepIndex);
yClean = yClean(keepIndex);
end

function plotLandOutlines(ax)
lonLim = xlim(ax);
latLim = ylim(ax);
landAreas = shaperead('landareas.shp', 'UseGeoCoords', true);
bounds = cat(3, landAreas.BoundingBox);
inView = squeeze(bounds(1, 1, :) <= lonLim(2) & bounds(2, 1, :) >= lonLim(1) & ...
    bounds(1, 2, :) <= latLim(2) & bounds(2, 2, :) >= latLim(1));
geoshow(ax, landAreas(inView), 'DisplayType', 'polygon', ...
    'FaceColor', [0.96, 0.96, 0.94], ...
    'EdgeColor', [0.30, 0.30, 0.30], 'LineWidth', 0.45);
xlim(ax, lonLim);
ylim(ax, latLim);
end
