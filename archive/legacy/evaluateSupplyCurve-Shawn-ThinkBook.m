function [LCOEcurve,LCOHcurve,LCOAcurve] = evaluateSupplyCurve(LCOE,LCOH,LCOA,minDistanceWT,spatiResolution,lonGrid_mesh,latGrid_mesh,excludedAreas,vesselDensity,ratedPower,nGrid)

powerPerGrid = deg2km(spatiResolution.lon)*1e3 * deg2km(spatiResolution.lat)*1e3 / minDistanceWT^2 * ratedPower; % MW

LCOEinColumn = reshape(LCOE,[nGrid^2,1]); LCOHinColumn = reshape(LCOH,[nGrid^2,1]); LCOAinColumn = reshape(LCOA,[nGrid^2,1]);
LCOEinColumn(isnan(LCOEinColumn)) = []; LCOHinColumn(isnan(LCOHinColumn)) = []; LCOAinColumn(isnan(LCOAinColumn)) = [];
powerinColumn = powerPerGrid * ones(size(LCOEinColumn,1),1);
LCOEinColumn = sort(LCOEinColumn); LCOHinColumn = sort(LCOHinColumn); LCOAinColumn = sort(LCOAinColumn);

% yValue = cumsum(LCOEinColumn .* powerinColumn);

LCOEcurve.xValue = cumsum(powerinColumn); LCOEcurve.yValue = LCOEinColumn;
LCOHcurve.xValue = cumsum(powerinColumn); LCOHcurve.yValue = LCOHinColumn;
LCOAcurve.xValue = cumsum(powerinColumn); LCOAcurve.yValue = LCOAinColumn;

%% modify power density according to vessel density
grid.lon.min = lonGrid_mesh - 0.5 * spatiResolution.lon; grid.lon.max = lonGrid_mesh + 0.5 * spatiResolution.lon;
grid.lat.min = lonGrid_mesh - 0.5 * spatiResolution.lat; grid.lat.max = lonGrid_mesh + 0.5 * spatiResolution.lat;

[WGSlonLimits, WGSlatLimits] = projinv(vesselDensity.info.ProjectedCRS, vesselDensity.info.XWorldLimits, vesselDensity.info.YWorldLimits);
[nLatRaster,nLonRaster] = size(vesselDensity.value);
[rasterCenterMeshedLon, rasterCenterMeshedLat] = meshgrid(linspace(WGSlonLimits(1),WGSlonLimits(2),nLonRaster),linspace(WGSlatLimits(1),WGSlatLimits(2),nLatRaster));

% calculate the vessel density per gird
vesselDensityGrid = zeros(nGrid,nGrid);
for iLat = 1:nGrid
    for iLon = 1:nGrid
        rasterLatIndex = find(rasterCenterMeshedLat<grid.lat.max(iLat,iLon) & rasterCenterMeshedLat>grid.lat.min(iLat,iLon));
        rasterLonIndex = find(rasterCenterMeshedLon<grid.lon.max(iLat,iLon) & rasterCenterMeshedLon>grid.lon.min(iLat,iLon));
        vesselDensityGrid(iLat,iLon) = mean(mean(vesselDensity.value(rasterLatIndex,rasterLonIndex)));
    end
end

% calculate the discount factor for power density per grid according to vessel density
probabilityOfHigherDensity = sum(sum(vesselDensity.value>vesselDensityGrid)) / sum(sum(~isnan(vesselDensity.value)));
powerPerGridNew = powerPerGrid .* probabilityOfHigherDensity;
end