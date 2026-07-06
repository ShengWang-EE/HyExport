function plotSupplementaryWakeEffectFigure(projectRoot)
if nargin == 0
    projectRoot = setupHyExport();
else
    projectRoot = setupHyExport(projectRoot);
end

fprintf('Render supplementary wake-effect figure: load historical wind speeds and directions\n');
siteLonLat = [
    -6.0392226, 53.8153670;
    -5.9810554, 52.6492857;
    -7.8880785, 51.7834268;
    -9.9732611, 53.263192
    ];
[windSpeedHistorical, directionDeg] = loadSiteWindData(siteLonLat);

fprintf('Render supplementary wake-effect figure: calculate annual-mean wake-loss field\n');
[~, windTurbine] = windTurbineModel(0, 15);
adoptedSpacing = 2310;
domainLimit = 2600;
resolution = 25;
xVector = -domainLimit:resolution:domainLimit;
yVector = -domainLimit:resolution:domainLimit;
[xGrid, yGrid] = meshgrid(xVector, yVector);

directionEdges = 0:5:360;
directionCenters = directionEdges(1:end-1) + diff(directionEdges) / 2;
deficitSamples = linspace(0, 0.95, 500);
[baselinePower, ~] = windTurbineModel(windSpeedHistorical, 15);
totalBaselinePower = sum(baselinePower, 'omitnan');

powerLossField = zeros(size(xGrid));
for iDirection = 1:numel(directionCenters)
    directionIndex = directionDeg >= directionEdges(iDirection) ...
        & directionDeg < directionEdges(iDirection + 1);
    speedNow = windSpeedHistorical(directionIndex);
    if isempty(speedNow)
        continue
    end

    [baselinePowerNow, ~] = windTurbineModel(speedNow, 15);
    wakeSpeedMatrix = speedNow(:) .* (1 - deficitSamples);
    [wakePowerMatrix, ~] = windTurbineModel(wakeSpeedMatrix, 15);
    lossByDeficit = sum(baselinePowerNow(:) - wakePowerMatrix, 1, 'omitnan');

    theta = directionCenters(iDirection);
    downstreamDistance = xGrid .* sind(theta) + yGrid .* cosd(theta);
    crosswindDistance = -xGrid .* cosd(theta) + yGrid .* sind(theta);
    wakeNow = calculateWakeFactor(windTurbine, downstreamDistance, crosswindDistance);
    powerLossField = powerLossField + interp1(deficitSamples, lossByDeficit, wakeNow, 'linear', 0);
end

wakeField = 100 * powerLossField ./ totalBaselinePower;
rotorDiameter = 2 * windTurbine.rotorRadius;
fprintf('  adopted spacing: %.2f km (%.1fD)\n', adoptedSpacing / 1000, adoptedSpacing / rotorDiameter);
fprintf('  annual-mean power loss at adopted spacing is below %.2f%% outside the centre region\n', ...
    max(wakeField(hypot(xGrid, yGrid) >= adoptedSpacing), [], 'omitnan'));

fprintf('Render supplementary wake-effect figure: calculate worst-direction wake field\n');
downstreamVector = 0:20:6500;
crosswindVector = -1200:20:1200;
[downstreamGrid, crosswindGrid] = meshgrid(downstreamVector, crosswindVector);
worstField = 100 * calculateWakeFactor(windTurbine, downstreamGrid, crosswindGrid);

fprintf('Render supplementary wake-effect figure: draw and export\n');
fig = figure('Color', 'w', 'Units', 'pixels', ...
    'Position', [100, 100, 1420, 650], 'Visible', 'off');

ax = axes(fig, 'Position', [0.07, 0.17, 0.34, 0.74]);
annualYShift = domainLimit / 1000;
contourf(ax, xGrid / 1000, yGrid / 1000 + annualYShift, wakeField, 18, 'LineStyle', 'none');
hold(ax, 'on');
contour(ax, xGrid / 1000, yGrid / 1000 + annualYShift, wakeField, [5, 5], ...
    'Color', [0.15 0.15 0.15], 'LineWidth', 1.5);
thetaCircle = linspace(0, 2 * pi, 360);
plot(ax, adoptedSpacing / 1000 * cos(thetaCircle), ...
    adoptedSpacing / 1000 * sin(thetaCircle) + annualYShift, 'k--', 'LineWidth', 1.3);
plot(ax, 0, annualYShift, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 5);
axis(ax, 'equal');
pbaspect(ax, [1 1 1]);
xlim(ax, [-domainLimit domainLimit] / 1000);
ylim(ax, [0 2 * annualYShift]);
annualYTicks = [-2 -1 1 2];
set(ax, 'YTick', annualYTicks + annualYShift, ...
    'YTickLabel', formatTickLabels(annualYTicks));
box(ax, 'on');
grid(ax, 'off');
set(ax, 'FontName', 'Arial', 'FontSize', 12, 'LineWidth', 0.8, ...
    'GridColor', [0.85 0.85 0.85], 'GridAlpha', 0.7);
ax.XAxisLocation = 'bottom';
ax.YAxisLocation = 'left';
ax.XAxis.Visible = 'off';
addXAxisLabels(ax, -2:1:2, 'East-west distance from turbine (km)');
ylabel(ax, 'North-south distance from turbine (km)');
c = colorbar(ax);
c.Label.String = 'Annual mean power loss (%)';
c.FontName = 'Arial';
c.FontSize = 11;
colormap(ax, wakeColorMap(256));
clim(ax, [0, max(6, ceil(max(wakeField(:))))]);

text(ax, 0.02, 0.96, 'adopted spacing = 2.31 km (9.8D)', ...
    'Units', 'normalized', ...
    'FontName', 'Arial', 'FontSize', 11, 'FontWeight', 'bold', ...
    'VerticalAlignment', 'middle', 'BackgroundColor', 'w', 'Margin', 2);
text(ax, 0.02, 0.90, '5% contour', 'Units', 'normalized', ...
    'FontName', 'Arial', 'FontSize', 11, 'FontWeight', 'bold', ...
    'BackgroundColor', 'w', 'Margin', 2);
text(ax, -0.12, 1.03, 'a', 'Units', 'normalized', ...
    'FontName', 'Arial', 'FontSize', 16, 'FontWeight', 'bold');

axWorst = axes(fig, 'Position', [0.56, 0.17, 0.34, 0.74]);
worstYShift = 1.2;
contourf(axWorst, downstreamGrid / 1000, crosswindGrid / 1000 + worstYShift, ...
    worstField, 18, 'LineStyle', 'none');
hold(axWorst, 'on');
contour(axWorst, downstreamGrid / 1000, crosswindGrid / 1000 + worstYShift, worstField, [5, 5], ...
    'Color', [0.15 0.15 0.15], 'LineWidth', 1.5);
plot(axWorst, [adoptedSpacing adoptedSpacing] / 1000, [0 2 * worstYShift], 'k--', 'LineWidth', 1.3);
plot(axWorst, 0, worstYShift, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 5);
xlim(axWorst, [0 6.5]);
ylim(axWorst, [0 2 * worstYShift]);
pbaspect(axWorst, [1 1 1]);
worstYTicks = [-1 -0.5 0.5 1];
set(axWorst, 'YTick', worstYTicks + worstYShift, ...
    'YTickLabel', formatTickLabels(worstYTicks));
box(axWorst, 'on');
grid(axWorst, 'off');
set(axWorst, 'FontName', 'Arial', 'FontSize', 12, 'LineWidth', 0.8, ...
    'GridColor', [0.85 0.85 0.85], 'GridAlpha', 0.7);
axWorst.XAxisLocation = 'bottom';
axWorst.YAxisLocation = 'left';
axWorst.XAxis.Visible = 'off';
addXAxisLabels(axWorst, 0:1:6, 'Downstream distance from turbine (km)');
ylabel(axWorst, 'Cross-wind distance from turbine (km)');
cWorst = colorbar(axWorst);
cWorst.Label.String = 'Worst-direction wake-effect factor (%)';
cWorst.FontName = 'Arial';
cWorst.FontSize = 11;
colormap(axWorst, wakeColorMap(256));
clim(axWorst, [0, ceil(max(worstField(:)))]);
text(axWorst, adoptedSpacing / 1000 + 0.08, 0.96 + worstYShift, '2.31 km (9.8D)', ...
    'FontName', 'Arial', 'FontSize', 11, 'FontWeight', 'bold', ...
    'VerticalAlignment', 'middle', 'BackgroundColor', 'w', 'Margin', 2);
text(axWorst, 5.05, 0.28 + worstYShift, '5% contour', ...
    'FontName', 'Arial', 'FontSize', 11, 'FontWeight', 'bold', ...
    'BackgroundColor', 'w', 'Margin', 2);
text(axWorst, -0.14, 1.16, 'b', 'Units', 'normalized', ...
    'FontName', 'Arial', 'FontSize', 16, 'FontWeight', 'bold');

outputPdf = fullfile(projectRoot, 'figs', 'fig wake effect single.pdf');
outputPng = fullfile(projectRoot, 'figs', 'preview_wake_effect_annual_worst.png');
supplementaryPdf = fullfile(projectRoot, 'manuscript', 'supplementary', ...
    'J14___Supplementary_Information_v0_2', 'figs', 'fig wake effect single.pdf');
set(fig, 'PaperUnits', 'inches', 'PaperPosition', [0 0 14.2 6.5], ...
    'PaperSize', [14.2 6.5]);
print(fig, outputPdf, '-dpdf', '-painters');
print(fig, supplementaryPdf, '-dpdf', '-painters');
print(fig, outputPng, '-dpng', '-r220');
close(fig);
end

function [windSpeedHistorical, directionDeg] = loadSiteWindData(siteLonLat)
fileName = resolveProjectFile('EUclimate.nc');
lonAll = double(ncread(fileName, 'longitude'));
latRaw = double(ncread(fileName, 'latitude'));
latAll = flip(latRaw);
nSite = size(siteLonLat, 1);
directionCell = cell(nSite, 1);
speedCell = cell(nSite, 1);

for iSite = 1:nSite
    lonNow = siteLonLat(iSite, 1);
    latNow = siteLonLat(iSite, 2);
    iLon = find(lonAll <= lonNow, 1, 'last');
    iLatAsc = find(latAll <= latNow, 1, 'last');
    lonWeight = (lonNow - lonAll(iLon)) / (lonAll(iLon + 1) - lonAll(iLon));
    latWeight = (latNow - latAll(iLatAsc)) / (latAll(iLatAsc + 1) - latAll(iLatAsc));
    rawLatLow = numel(latAll) - iLatAsc + 1;
    rawLatHigh = numel(latAll) - (iLatAsc + 1) + 1;

    uSeries = readBilinearSeries(fileName, 'u100', iLon, rawLatLow, rawLatHigh, lonWeight, latWeight);
    vSeries = readBilinearSeries(fileName, 'v100', iLon, rawLatLow, rawLatHigh, lonWeight, latWeight);
    speedCell{iSite} = hypot(uSeries, vSeries);
    directionCell{iSite} = mod(atan2d(uSeries, vSeries), 360);
end

directionDeg = vertcat(directionCell{:});
windSpeedHistorical = vertcat(speedCell{:});
validIndex = ~isnan(directionDeg) & ~isnan(windSpeedHistorical);
directionDeg = directionDeg(validIndex);
windSpeedHistorical = windSpeedHistorical(validIndex);
end

function series = readBilinearSeries(fileName, variableName, iLon, rawLatLow, rawLatHigh, lonWeight, latWeight)
dataLow = double(squeeze(ncread(fileName, variableName, [iLon, rawLatLow, 1], [2, 1, inf])));
dataHigh = double(squeeze(ncread(fileName, variableName, [iLon, rawLatHigh, 1], [2, 1, inf])));
seriesLow = (1 - lonWeight) .* dataLow(1, :)' + lonWeight .* dataLow(2, :)';
seriesHigh = (1 - lonWeight) .* dataHigh(1, :)' + lonWeight .* dataHigh(2, :)';
series = (1 - latWeight) .* seriesLow + latWeight .* seriesHigh;
end

function wakeFactor = calculateWakeFactor(windTurbine, downstreamDistance, crosswindDistance)
wakeFactor = zeros(size(downstreamDistance));
inWake = downstreamDistance > 0;
sigma = 0.5 .* (windTurbine.rotorRadius + ...
    0.56 ./ log(windTurbine.hubHeight ./ windTurbine.roughness) .* downstreamDistance(inWake));
wakeFactor(inWake) = (1 - sqrt(1 - windTurbine.C_T ./ 2 ./ ...
    (sigma ./ windTurbine.rotorRadius).^2)) .* ...
    exp(-crosswindDistance(inWake).^2 ./ 2 ./ sigma.^2);
wakeFactor = real(wakeFactor);
end

function cmap = wakeColorMap(nColor)
anchor = [
    1.00 0.98 0.91
    0.99 0.86 0.46
    0.96 0.55 0.20
    0.82 0.18 0.12
    0.45 0.03 0.08
    ];
x = linspace(0, 1, size(anchor, 1));
xi = linspace(0, 1, nColor);
cmap = interp1(x, anchor, xi, 'pchip');
cmap = max(0, min(1, cmap));
end

function labels = formatTickLabels(values)
labels = arrayfun(@(x) sprintf('%g', x), values, 'UniformOutput', false);
end

function addXAxisLabels(ax, ticks, labelText)
yLimits = ylim(ax);
yRange = diff(yLimits);
tickBottom = yLimits(1);
tickTop = yLimits(1) + 0.035 * yRange;
for tick = ticks
    plot(ax, [tick tick], [tickBottom tickTop], 'k-', ...
        'LineWidth', 0.8, 'Clipping', 'off');
    text(ax, tick, yLimits(1) - 0.055 * yRange, sprintf('%g', tick), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
        'FontName', 'Arial', 'FontSize', 12, 'Clipping', 'off');
end
text(ax, mean(xlim(ax)), yLimits(1) - 0.18 * yRange, labelText, ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
    'FontName', 'Arial', 'FontSize', 13, 'Clipping', 'off');
end
