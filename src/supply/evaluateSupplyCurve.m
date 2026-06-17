function [LCOEcurve,LCOHcurve,LCOAcurve,waterDepthColumn,vesselDensityGrid,powerPerGridNew,probabilityOfHigherDensity, ...
    powerPerGirdDiscountFactor,lonColumn,latColumn] = evaluateSupplyCurve(LCOE,LCOH,LCOA,...
    minDistanceWT,spatiResolution,lonGrid_mesh,latGrid_mesh,waterDepth,excludedAreas,vesselDensity,ratedPower,nGrid)
%% modify power density according to vessel density
grid.lon.min = lonGrid_mesh - 0.02; grid.lon.max = lonGrid_mesh + 0.02;
grid.lat.min = latGrid_mesh - 0.02; grid.lat.max = latGrid_mesh + 0.02;

[WGSlonLimits,WGSlatLimits] = deal(vesselDensity.info.LongitudeLimits, vesselDensity.info.LatitudeLimits);
% [WGSlatLimits,WGSlonLimits] = projinv(vesselDensity.info.ProjectedCRS,vesselDensity.info.XWorldLimits, vesselDensity.info.YWorldLimits);

[nLatRaster,nLonRaster] = size(vesselDensity.value);

[rasterCenterLon, rasterCenterLat] = deal(linspace(WGSlonLimits(1),WGSlonLimits(2),nLonRaster),linspace(WGSlatLimits(1),WGSlatLimits(2),nLatRaster));

vesselDensity.value = flip(vesselDensity.value,1); % 纬度又是倒过来的
lonmin = lonGrid_mesh(1,1); lonmax = lonGrid_mesh(1,end);
latmin = latGrid_mesh(1,1); latmax = latGrid_mesh(end,1);
rangeLon = find(rasterCenterLon>lonmin & rasterCenterLon<lonmax);
rangeLat = find(rasterCenterLat>latmin & rasterCenterLat<latmax);
% vesselDensityEEZ = vesselDensity.value(rangeLat,rangeLon); % 检查完毕


% calculate the vessel density per gird
% vesselDensity.value(isnan(vesselDensity.value)) = 0;
vesselDensityGrid = zeros(nGrid,nGrid);
totalVesselDensity = sum(sum(~isnan(vesselDensity.value)));
probabilityOfHigherDensity = zeros(nGrid,nGrid);
for iLat = 1:nGrid
    for iLon = 1:nGrid
        rasterLatIndex = find(rasterCenterLat<grid.lat.max(iLat,iLon) & rasterCenterLat>grid.lat.min(iLat,iLon));
        rasterLonIndex = find(rasterCenterLon<grid.lon.max(iLat,iLon) & rasterCenterLon>grid.lon.min(iLat,iLon));
        valueInGrid = vesselDensity.value(rasterLatIndex,rasterLonIndex);
        vesselDensityGrid(iLat,iLon) = mean(mean(valueInGrid));
        probabilityOfHigherDensity(iLat,iLon) = sum(sum(vesselDensity.value>=vesselDensityGrid(iLat,iLon))) / totalVesselDensity;
        if isnan(vesselDensityGrid(iLat,iLon))
            probabilityOfHigherDensity(iLat,iLon) = nan;
        end
    end
end

% calculate the discount factor for power density per grid according to vessel density
powerPerGirdDiscountFactor = sqrt(probabilityOfHigherDensity);
%% new curve
area = minDistanceWT^2*sqrt(3)/4; % 等边三角形
powerPerGrid = deg2km(spatiResolution.lon)*1e3 * deg2km(spatiResolution.lat)*1e3 / area * ratedPower; % MW
powerPerGridNew = powerPerGrid*0.5 +  powerPerGrid*0.5.* powerPerGirdDiscountFactor; % 一半的功率密度受影响
powerinColumn = reshape(powerPerGridNew .* ones(nGrid,nGrid),[nGrid^2,1]);

LCOEinColumn = reshape(LCOE,[nGrid^2,1]); LCOHinColumn = reshape(LCOH,[nGrid^2,1]); LCOAinColumn = reshape(LCOA,[nGrid^2,1]);
waterDepthinColumn = reshape(waterDepth,[nGrid^2,1]);
lonInColumn = reshape(lonGrid_mesh,[nGrid^2,1]); latInColumn = reshape(latGrid_mesh,[nGrid^2,1]);

onshoreIndex = [find(isnan(powerinColumn));find(isnan(LCOEinColumn))];
LCOEinColumn(onshoreIndex) = []; LCOHinColumn(onshoreIndex) = []; LCOAinColumn(onshoreIndex) = [];
waterDepthinColumn(onshoreIndex) = []; lonInColumn(onshoreIndex) = []; latInColumn(onshoreIndex) = [];
powerinColumn(onshoreIndex) = [];
LCOEcurve = [powerinColumn,LCOEinColumn,lonInColumn,latInColumn];
LCOHcurve = [powerinColumn,LCOHinColumn,waterDepthinColumn];
LCOAcurve = [powerinColumn,LCOAinColumn];

LCOEcurve = sortrows(LCOEcurve,2); LCOHcurve = sortrows(LCOHcurve,2); LCOAcurve = sortrows(LCOAcurve,2);
LCOEcurve(:,1) = cumsum(LCOEcurve(:,1)); LCOHcurve(:,1) = cumsum(LCOHcurve(:,1)); LCOAcurve(:,1) = cumsum(LCOAcurve(:,1));

waterDepthColumn = LCOHcurve(:,3);LCOHcurve(:,3) = [];
lonColumn = LCOEcurve(:,3); latColumn = LCOEcurve(:,4); LCOEcurve(:,3:4) = [];
end