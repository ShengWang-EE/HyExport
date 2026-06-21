function buildHighResolutionLCOHMapData(projectRoot, nGridMap)
if nargin == 0
    projectRoot = setupHyExport();
else
    projectRoot = setupHyExport(projectRoot);
end
if nargin < 2
    nGridMap = 300;
end

checkpointDir = fullfile(projectRoot, 'results', 'checkpoints');
source = load(fullfile(checkpointDir, 'stop3.mat'), 'EUcountryList', ...
    'EUcitiesCoordinates', 'OWFcapacity', 'ratedPower', 'EUshpEEZ', ...
    'minDistanceWT', 'windTurbine');

nCountry = numel(source.EUcountryList);
LCOH_map = cell(1, nCountry);
latGrid_mesh_map = cell(1, nCountry);
lonGrid_mesh_map = cell(1, nCountry);

for iCountry = 1:nCountry
    countryName = char(source.EUcountryList(iCountry));
    fprintf('Stage 4/5: high-resolution LCOH map %d/%d %s, nGrid=%d\n', ...
        iCountry, nCountry, countryName, nGridMap);
    [~, LCOH_map{iCountry}, ~, ~, ~, ~, ~, lonGrid_mesh_map{iCountry}, ...
        latGrid_mesh_map{iCountry}] = evaluateOffshoreProductionCost( ...
        countryName, nGridMap, source.EUcitiesCoordinates, source.OWFcapacity, ...
        source.ratedPower, source.EUshpEEZ, source.minDistanceWT, source.windTurbine);
end

countryNames = source.EUcountryList;
save(fullfile(checkpointDir, 'fig1_lcoh_map_highres.mat'), ...
    'LCOH_map', 'latGrid_mesh_map', 'lonGrid_mesh_map', 'countryNames', 'nGridMap', '-v7.3');
end
