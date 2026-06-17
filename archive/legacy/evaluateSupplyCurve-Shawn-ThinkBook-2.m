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
grid.lon.min = lonGrid_mesh - 0.01; grid.lon.max = lonGrid_mesh + 0.01;
grid.lat.min = latGrid_mesh - 0.01; grid.lat.max = latGrid_mesh + 0.01;

[WGSlonLimits,WGSlatLimits] = deal(vesselDensity.info.LongitudeLimits, vesselDensity.info.LatitudeLimits);
[WGSlonLimits,WGSlatLimits] = projinv(vesselDensity.info.worldLimitsX, vesselDensity.info.worldLimitsY);

[nLatRaster,nLonRaster] = size(vesselDensity.value);

[rasterCenterLon, rasterCenterLat] = deal(linspace(WGSlonLimits(1),WGSlonLimits(2),nLonRaster),linspace(WGSlatLimits(1),WGSlatLimits(2),nLatRaster));

lonmin = lonGrid_mesh(1,1); lonmax = lonGrid_mesh(1,end);
latmin = latGrid_mesh(1,1); latmax = latGrid_mesh(end,1);
rangeLon = find(rasterCenterLon>lonmin & rasterCenterLon<lonmax);
rangeLat = find(rasterCenterLat>latmin & rasterCenterLat<latmax);
vesselDensityEEZ = vesselDensity.value(rangeLat,rangeLon);


% calculate the vessel density per gird
vesselDensity.value(isnan(vesselDensity.value)) = 0;
vesselDensityGrid = zeros(nGrid,nGrid);
for iLat = 1:nGrid
    for iLon = 1:nGrid
        rasterLatIndex = find(rasterCenterLat<grid.lat.max(iLat,iLon) & rasterCenterLat>grid.lat.min(iLat,iLon));
        rasterLonIndex = find(rasterCenterLon<grid.lon.max(iLat,iLon) & rasterCenterLon>grid.lon.min(iLat,iLon));
        vesselDensityGrid(iLat,iLon) = mean(mean(vesselDensity.value(rasterLatIndex,rasterLonIndex)));
    end
end

% calculate the discount factor for power density per grid according to vessel density
probabilityOfHigherDensity = sum(sum(vesselDensity.value>vesselDensityGrid)) / sum(sum(~isnan(vesselDensity.value)));
powerPerGridNew = powerPerGrid .* probabilityOfHigherDensity;
end