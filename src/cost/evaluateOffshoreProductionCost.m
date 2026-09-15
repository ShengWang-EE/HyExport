function [LCOE,LCOH_energy,LCOA_hyEnergy,distanceToPort,waterDepth,capacityFactor,spatiResolution,lonGrid_mesh, latGrid_mesh, hydrogenCostByYear] ...
    = evaluateOffshoreProductionCost(countryName,nGrid,EUcitiesCoordinates,OWFcapacity,...
    ratedPower,EUshpEEZ,minDistanceWT,windTurbine)
% 矩阵行是lat，列是lon
% specify assessment zone (take EEZ as reference)
countryEEZ = EUshpEEZ(strcmp(string({EUshpEEZ.TERRITORY1}), string(countryName)));
% obtain wind velocity (and unify the resolution)
[climate,spatiResolution,lonGrid_mesh, latGrid_mesh] = loadCountryClimate(countryEEZ,nGrid);
% get bathymetry
bathymetry = loadCountryBathymetry(countryEEZ,countryName,nGrid);
bathymetry.elevation(find(bathymetry.elevation>=0)) = nan;
onshoreIndex = find(isnan(bathymetry.elevation));

% port and electric bus
if strcmp(string(countryName), "Ireland")
    busName = readtable(projectFile('data','tables','All Island Ten Year Transmission Statement-2021.xlsx'),...
        'sheet','bus name','range','A1:D371');
    EbusCoordinate = table2array(busName(1:end,3:4));
else
    EbusCoordinate = EUcitiesCoordinates;
end
nb = size(EbusCoordinate,1);
ferryPortShp = readshp(resolveProjectFile('EMODnet_HA_Main_Ports_20231106.shp'));
nPort = size(ferryPortShp,1);

% capacity and distances
historicalWindGeneration = windTurbineModel(climate.windSpeed,ratedPower);
capacityFactor = mean(historicalWindGeneration,3) / ratedPower;
loadFactor = 0.95;

%% LCOE
[LCOE,distanceToConnectPoint,distanceToPort,waterDepth] = deal(zeros(nGrid,nGrid));

for iLon = 1:nGrid
    for iLat = 1:nGrid
        lon = bathymetry.lon(iLon); lat = bathymetry.lat(iLat); 
        distanceToConnectPoint(iLat,iLon) = 1e3 * min(deg2km(geoDistance(repmat([lon,lat],[nb,1]),EbusCoordinate))); %km->m
        distanceToPort(iLat,iLon) = 1e3 * min(deg2km(geoDistance(repmat([lon,lat],[nPort,1]),[[ferryPortShp.X]',[ferryPortShp.Y]']))); %km->m
        waterDepth(iLat,iLon) = - bathymetry.elevation(iLat,iLon);
    end
end

costInd = cell(nGrid,nGrid);
for iLon = 1:nGrid
    for iLat = 1:nGrid
        if ~isnan(waterDepth(iLat,iLon)) && waterDepth(iLat,iLon) > 0
            if waterDepth(iLat,iLon) <= 30
                OWFtype(iLat,iLon) = 1;
            elseif waterDepth(iLat,iLon) <= 60
                OWFtype(iLat,iLon) = 1;
            else
                OWFtype(iLat,iLon) = 3;
            end
            [LCOE(iLat,iLon),costInd{iLat,iLon}] = evaluateOWFelectricityCost(OWFtype(iLat,iLon),capacityFactor(iLat,iLon),loadFactor,windTurbine,...
                        waterDepth(iLat,iLon),distanceToConnectPoint(iLat,iLon),minDistanceWT,distanceToPort(iLat,iLon),OWFcapacity);
            cost.foundation(iLat,iLon) = costInd{iLat,iLon}.foundation;
            cost.installation(iLat,iLon) = costInd{iLat,iLon}.installation;
            cost.CAPEX(iLat,iLon) = costInd{iLat,iLon}.CAPEX/1e10;
            cost.OPEX(iLat,iLon) = costInd{iLat,iLon}.OPEX/1e10;
            cost.DEVEX(iLat,iLon) = costInd{iLat,iLon}.DEVEX/1e10;
            cost.DECEX(iLat,iLon) = costInd{iLat,iLon}.DECEX/1e10;
            cost.totalCost(iLat,iLon) = costInd{iLat,iLon}.totalCost;
        end
    end
end

%% LCOH
% distance to gas bus
if strcmp(string(countryName), "Ireland")
    GbusCoordinate = table2array(readtable(projectFile('data','tables','Irish energy system data.xlsx'),...
        'sheet','Gbus','range','H2:I145'));
else
    GbusCoordinate = EUcitiesCoordinates;
end
nGb = size(GbusCoordinate,1);

%
[LCOH_energy,LCOH_volume,LCOH_mass,LCOA_hyVolume,LCOA_hyEnergy,LCOA_hyMass, ...
    distanceToGasBus] = deal(zeros(nGrid,nGrid));

modelYears = [2030 2040 2050];
windReductionRate = table2array(readtable(projectFile('data','tables','offshore wind cost reduction.xlsx'),'Range','O11:P14'));
if nargout < 10
    modelYears = 2030; % High-resolution map only requests the baseline.
end
sizing = cell(numel(modelYears),1);
for iYear = 1:numel(modelYears)
    sizing{iYear} = electrolyzerSizing(OWFcapacity,modelYears(iYear));
end
hydrogenCostByYear.years = modelYears;
hydrogenCostByYear.H = nan(nGrid,nGrid,numel(modelYears));
hydrogenCostByYear.A = nan(nGrid,nGrid,numel(modelYears));

for iLon = 1:nGrid
    for iLat = 1:nGrid
        if ~isnan(waterDepth(iLat,iLon)) && waterDepth(iLat,iLon) > 0 
            lon = bathymetry.lon(iLon); lat = bathymetry.lat(iLat);
            distanceToGasBus(iLat,iLon) =  min(deg2km(geoDistance(repmat([lon,lat],[nGb,1]),GbusCoordinate))); %km
            for iYear = 1:numel(modelYears)
                x = sizing{iYear}; % P_bt, P_cp, P_el, P_wpd, water mass, Q_hy, Q_hy_scf.
                foundationColumn = 1 + (waterDepth(iLat,iLon) > 60);
                windCostFactor = 1 - windReductionRate(iYear+1,foundationColumn);
                [hydrogenCostByYear.H(iLat,iLon,iYear),~,~,~,hydrogenCostByYear.A(iLat,iLon,iYear)] ...
                    = evaluateHydrogenCost(OWFcapacity,x(1),x(2),x(3),x(4),x(6), ...
                    distanceToGasBus(iLat,iLon),costInd{iLat,iLon},capacityFactor(iLat,iLon),loadFactor,modelYears(iYear),windCostFactor);
            end
        end
    end
end

% Baseline grids are retained for existing map consumers.
LCOH_energy = hydrogenCostByYear.H(:,:,1);
LCOA_hyEnergy = hydrogenCostByYear.A(:,:,1);
%%
LCOE(onshoreIndex) = nan; LCOE(LCOE>300) = nan; % 太贵了就干脆不要了
LCOH_energy(onshoreIndex) = nan; LCOH_energy(LCOH_energy>600) = nan; 
LCOA_hyEnergy(onshoreIndex) = nan; LCOA_hyEnergy(LCOA_hyEnergy>700) = nan; 
% only include points within EEZ
inEEZindex = inpolygon(lonGrid_mesh,latGrid_mesh,countryEEZ.X,countryEEZ.Y);
LCOE(~inEEZindex) = nan; LCOH_energy(~inEEZindex) = nan; LCOA_hyEnergy(~inEEZindex) = nan;
for iYear = 1:numel(modelYears)
    h = hydrogenCostByYear.H(:,:,iYear);
    a = hydrogenCostByYear.A(:,:,iYear);
    h(onshoreIndex) = nan; a(onshoreIndex) = nan;
    h(~inEEZindex | h>600) = nan;
    a(~inEEZindex | a>700) = nan;
    hydrogenCostByYear.H(:,:,iYear) = h;
    hydrogenCostByYear.A(:,:,iYear) = a;
end

end
