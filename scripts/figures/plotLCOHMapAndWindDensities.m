function plotLCOHMapAndWindDensities(projectRoot)
if nargin == 0
    projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
end

projectRoot = setupHyExport(projectRoot);
sourcePdf = fullfile(projectRoot, 'figs', 'fig LCOH map manu side source.pdf');
figureDir = fullfile(projectRoot, 'figs');
manuscriptFigureDir = fullfile(projectRoot, 'manuscript', 'figs');
tempFigureDir = fullfile(tempdir, 'hyexport_fig1_reflow');
if exist(tempFigureDir, 'dir') ~= 7
    mkdir(tempFigureDir);
end

sourcePng = fullfile(tempFigureDir, 'fig1_source.png');
gsCommand = sprintf('gs -dSAFER -dBATCH -dNOPAUSE -sDEVICE=png16m -r300 -sOutputFile="%s" "%s"', ...
    sourcePng, sourcePdf);
[status, output] = system(gsCommand);
if status ~= 0
    error('Ghostscript failed while rendering Fig. 1 source PDF: %s', output);
end

source = imread(sourcePng);
reflowed = reflowSidePanelsBelowMap(source);

fig = figure('Visible', 'off', 'Color', 'w', 'Units', 'pixels', ...
    'Position', [100, 100, size(reflowed, 2), size(reflowed, 1)]);
image(reflowed);
axis off
axis image
text(90, size(reflowed, 1) - 320, 'b', 'FontWeight', 'bold', ...
    'FontSize', 28, 'FontName', 'Arial');
text(size(reflowed, 2) / 2, size(reflowed, 1) - 20, 'Wind speed (m/s)', ...
    'HorizontalAlignment', 'center', 'FontSize', 18, 'FontName', 'Arial');

outputPdf = fullfile(figureDir, 'fig LCOH map manu.pdf');
exportgraphics(fig, outputPdf, 'ContentType', 'image', 'Resolution', 600);
copyfile(outputPdf, fullfile(manuscriptFigureDir, 'fig_LCOH_map_manu.pdf'));
close(fig);
end

function canvas = reflowSidePanelsBelowMap(source)
[sourceHeight, sourceWidth, ~] = size(source);

mapCrop = source(:, 1:round(0.865 * sourceWidth), :);
mapWidth = 2200;
mapHeight = round(size(mapCrop, 1) * mapWidth / size(mapCrop, 2));
mapImage = imresize(mapCrop, [mapHeight, mapWidth]);

panelCount = 11;
panelSource = cell(1, panelCount);
panelSourceLeft = round(0.901 * sourceWidth);
panelSourceRight = round(0.988 * sourceWidth);
firstPanelTop = round(0.028 * sourceHeight);
panelPitch = round(0.083 * sourceHeight);
panelSourceHeight = round(0.066 * sourceHeight);

for iPanel = 1:panelCount
    yTop = firstPanelTop + (iPanel - 1) * panelPitch;
    yBottom = yTop + panelSourceHeight;
    panelSource{iPanel} = source(yTop:yBottom, panelSourceLeft:panelSourceRight, :);
end

canvasWidth = 2400;
panelWidth = 310;
panelHeight = 120;
panelGap = 45;
leftMargin = round((canvasWidth - 6 * panelWidth - 5 * panelGap) / 2);
rowY = [mapHeight + 85, mapHeight + 230];
canvasHeight = mapHeight + 395;
canvas = uint8(255 * ones(canvasHeight, canvasWidth, 3));

mapLeft = round((canvasWidth - mapWidth) / 2);
canvas(1:mapHeight, mapLeft + (1:mapWidth), :) = mapImage;

for iPanel = 1:panelCount
    rowIndex = ceil(iPanel / 6);
    columnIndex = iPanel - (rowIndex - 1) * 6;
    left = leftMargin + (columnIndex - 1) * (panelWidth + panelGap);
    top = rowY(rowIndex);
    panelImage = imresize(panelSource{iPanel}, [panelHeight, panelWidth]);
    panelImage(:, 1:12, :) = 255;
    canvas(top + (1:panelHeight), left + (1:panelWidth), :) = panelImage;
end
end
