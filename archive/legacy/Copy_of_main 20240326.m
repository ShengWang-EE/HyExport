%% obtain the DMAP
clear
clc

[colorData] = colorData();

IrelandShp.country = readshp('gadm41_IRL_0.shp');                         % load basemap
IrelandShp.county = readshp('gadm41_IRL_1.shp');
UKshp.country = readshp('gadm41_GBR_0.shp');

IrelandShp.EES = readshp('Maritime_Boundary_Exclusive_Economic_Zone.shp'); % load Exclusive Economic Zone
IrelandShp.studyArea = readshp('OREDP_Study_Area.shp');
IrelandShp.assessmentZone = readshp('OREDP_Assessment_Zone.shp');         % conduct assessment in this area

% IrelandShp.OWFapproved = readshp('Energy_Offshore_Renewable.shp');       % areas of offshore wind under foreshore process
IrelandShp.OWFforeshore = readshp('offshore areas (early planning).shp');

% excluded areas
IrelandShp.aquacultureSites = readshp('AquacultureSites.shp');            % Aquaculture Sites
IrelandShp.protectedMarineSites = readshp('Protected_Marine_Sites.shp');  % Special Area of Conservation
IrelandShp.militaryAreas = readshp('EMODnet_HA_MilitaryAreas_pg_20221216.shp');  % militaryAreas

% penalized areas
% inshore fishing
IrelandShp.dredgeFishing = readshp('Dredge_Fishing.shp');
IrelandShp.lineFishing = readshp('Line_Fishing.shp');
IrelandShp.midwaterTrawlFishing = readshp('Midwater_Trawl_Fishing.shp');
IrelandShp.netsFishing = readshp('Nets_Fishing.shp');
IrelandShp.bottomTrawlFishing = readshp('Bottom_Trawl_Fishing.shp');
IrelandShp.potFishing = readshp('Pot_Fishing.shp');
% offshore fishing
IrelandShp.offshoreFishing = readshp('Fishing_Method_All_Gears.shp');
% vessel density
[A,R] = readgeoraster('vesseldensity_all_2022.tif');


% obtain wind velocity
boundingBoxMatrix = [IrelandShp.assessmentZone.BoundingBox];
boundingBoxPositive = boundingBoxMatrix(boundingBoxMatrix > 0);
boundingBoxNegtive = boundingBoxMatrix(boundingBoxMatrix < 0);
[boundingBoxOfAssessmentZone.minLon, boundingBoxOfAssessmentZone.maxLon, ...
    boundingBoxOfAssessmentZone.minLat, boundingBoxOfAssessmentZone.maxLat] ...
    = deal(min(min(boundingBoxNegtive)),max(max(boundingBoxNegtive)), ...
    min(min(boundingBoxPositive)), max(max(boundingBoxPositive))) ;
IrelandShp.boundingBox.X = [boundingBoxOfAssessmentZone.minLon, boundingBoxOfAssessmentZone.minLon,boundingBoxOfAssessmentZone.maxLon,boundingBoxOfAssessmentZone.maxLon,boundingBoxOfAssessmentZone.minLon,NaN];
IrelandShp.boundingBox.Y = [boundingBoxOfAssessmentZone.minLat,boundingBoxOfAssessmentZone.maxLat,boundingBoxOfAssessmentZone.maxLat,boundingBoxOfAssessmentZone.minLat,boundingBoxOfAssessmentZone.minLat,NaN];

% read the wind data from nc file
fileNameList = dir('.\wind data\');
[windMatrix,numDays] = loadWindDataFromNC(fileNameList); % load wind data from nc file
windMatrix.speedHist = reshape(windMatrix.SPEED,[size(windMatrix.SPEED,1)*size(windMatrix.SPEED,2),1]);
windMatrix.meanSpeed = mean(windMatrix.SPEED);

% grid the data
nGridWind = 1000;
lonGrid_wind = linspace(boundingBoxOfAssessmentZone.minLon, boundingBoxOfAssessmentZone.maxLon,nGridWind);
latGrid_wind = linspace(boundingBoxOfAssessmentZone.minLat, boundingBoxOfAssessmentZone.maxLat,nGridWind);
[lonGrid_windMesh, latGrid_windMesh] = meshgrid(lonGrid_wind,latGrid_wind);
windMatrix.interpolated = griddata(windMatrix.lat,windMatrix.lon,windMatrix.meanSpeed,latGrid_windMesh,lonGrid_windMesh);

gridIndexNotInAssessmentZone = 1-inpolygon(lonGrid_windMesh,latGrid_windMesh,[IrelandShp.assessmentZone.X],[IrelandShp.assessmentZone.Y]);
windMatrix.interpolated(gridIndexNotInAssessmentZone==1) = NaN;


IrelandPoly.boundingBox = polyshape([IrelandShp.boundingBox.X],[IrelandShp.boundingBox.Y]);
IrelandPoly.assessmentZone = polyshape([IrelandShp.assessmentZone.X],[IrelandShp.assessmentZone.Y]);
IrelandPoly.boundingBoxMinusAssessmentZone = subtract(IrelandPoly.boundingBox,IrelandPoly.assessmentZone);
IrelandPoly.country = polyshape([IrelandShp.country.X],[IrelandShp.country.Y]);

[IrelandShp.boundingBoxMinusAssessmentZone.long,IrelandShp.boundingBoxMinusAssessmentZone.lat]...
    = deal([IrelandPoly.boundingBoxMinusAssessmentZone.Vertices(:,1);IrelandPoly.boundingBoxMinusAssessmentZone.Vertices(1,1);NaN],...
    [IrelandPoly.boundingBoxMinusAssessmentZone.Vertices(:,2);IrelandPoly.boundingBoxMinusAssessmentZone.Vertices(1,2);NaN]);

save stop1.mat
%% wind power model
clear
clc
load stop1.mat
% power curve of wind turbine
windSpeedTest = 0:0.1:0.1;
ratedPower = 15; % 15 MW type model
[electricityGenerationCurve,windTurbine] = windTurbineModel(windSpeedTest,ratedPower);

% wake effect area for a single WT
resolution = 10; % 10m
nGridWake = 5000;
for ix = 1:nGridWake
    dx = ix * resolution;
    for iy = 1:nGridWake
        dy = iy * resolution;
        sigma(ix,iy) = 0.5 * (windTurbine.rotorRadius + 0.56 / log(windTurbine.hubHeight/windTurbine.roughness) .* dx);
        windDecreaseFactor(ix,iy) = (1 - sqrt(1 - windTurbine.C_T / 2 ./ (sigma(ix,iy) / windTurbine.rotorRadius)^2) ) * exp(-dy.^2 / 2 / sigma(ix,iy).^2);
    end
end
% 就取实数部分也行
windDecreaseFactor_real = real(windDecreaseFactor);
% 截取一段进行画图
indexRow = max(find(max(windDecreaseFactor_real,[],2) > 1e-2));
indexColumn = ceil(indexRow / 6);
export.wakeEffectSingle = windDecreaseFactor_real(1:indexRow,1:indexColumn);
% 风机间距
minDistanceWT = calculateMinDistance(windDecreaseFactor,nGridWake,resolution);

save stop2.mat
%% offshore wind cost
clear
clc
load stop2.mat
load('bathymetry_2022_e3e9_084d_15b3.mat')
mpc.busName = readtable('All Island Ten Year Transmission Statement-2021.xlsx',...
    'sheet','bus name','range','A1:D371');
EbusCoordinate = table2array(mpc.busName(1:end,3:4));
nb = size(EbusCoordinate,1);
IrelandShp.ferryPort = readshp('Ferry_Port.shp'); 
nPort = size(IrelandShp.ferryPort,1);

% capacity
historicalWindGeneration = windTurbineModel(windMatrix.SPEED,ratedPower);
capacityFactor = mean(mean(historicalWindGeneration)) / ratedPower;

loadFactor = 1;

% ---test setting
% waterDepth = 40;
% distanceToConnectPoint = 60000;
% distanceToPort = 60000;
% distanceBetweenTurbine = 1000;
% OWFtype = 2;
% LCOEtest = evaluateOWFelectricityCost(OWFtype,capacityFactor,loadFactor,windTurbine,...
%     waterDepth,distanceToConnectPoint,distanceBetweenTurbine,distanceToPort);
%
distanceBetweenTurbine = minDistanceWT;
resolution = 10;
nx = size(1:resolution:size(bathymetry_2022.longitude,1),2);
ny = size(1:resolution:size(bathymetry_2022.latitude,1),2);
LCOE = zeros(nx,ny);
distanceToConnectPoint = zeros(nx,ny);
distanceToPort = zeros(nx,ny);

for ix = 1:nx
    for iy = 1:ny
        lon = bathymetry_2022.longitude(resolution*(ix-1)+1);
        lat = bathymetry_2022.latitude(resolution*(iy-1)+1);
%         distanceToConnectPoint(ix,iy) = 1e3 * min(deg2km(sum((repmat([lon,lat],[nb,1])-EbusCoordinate).^2,2))); %km->m
        distanceToConnectPoint(ix,iy) = 1e3 * min(deg2km(distance(repmat([lon,lat],[nb,1]),EbusCoordinate))); %km->m
%         distanceToPort(ix,iy) = 1e3 * min(deg2km(sum((repmat([lon,lat],[nPort,1])-[[IrelandShp.ferryPort.X]',[IrelandShp.ferryPort.Y]']).^2,2))); %km->m
        distanceToPort(ix,iy) = 1e3 * min(deg2km(distance(repmat([lon,lat],[nPort,1]),[[IrelandShp.ferryPort.X]',[IrelandShp.ferryPort.Y]']))); %km->m
    end
end
%%
OWFcapacity = 1050; % assume 1050MW for a wind farm
costInd = cell(nx,ny);
for ix = 1:nx
    for iy = 1:ny
        waterDepth(ix,iy) = - bathymetry_2022.elevation(resolution*(iy-1)+1,resolution*(ix-1)+1);
        if ~isnan(waterDepth(ix,iy)) && waterDepth(ix,iy) > 0
            if waterDepth(ix,iy) <= 30
                OWFtype = 1;
            elseif waterDepth(ix,iy) <= 60
                OWFtype = 2;
            else
                OWFtype = 3;
            end
            [LCOE(ix,iy),costInd{ix,iy}] = evaluateOWFelectricityCost(OWFtype,capacityFactor,loadFactor,windTurbine,...
                        waterDepth(ix,iy),distanceToConnectPoint(ix,iy),distanceBetweenTurbine,distanceToPort(ix,iy),OWFcapacity);
            cost.foundation(ix,iy) = costInd{ix,iy}.foundation;
            cost.installation(ix,iy) = costInd{ix,iy}.installation;
        end
    end
end
% waterDepth1(waterDepth1>100) = nan;

% export cost coordinate
assessmentZone_lon = bathymetry_2022.longitude(1:resolution:size(bathymetry_2022.longitude,1));
assessmentZone_lat = bathymetry_2022.latitude(1:resolution:size(bathymetry_2022.latitude,1));
[lonGrid,latGrid] = meshgrid(assessmentZone_lon,assessmentZone_lat);
assessmentZoneIndex = (inpolygon(lonGrid,latGrid,[IrelandShp.assessmentZone.X],[IrelandShp.assessmentZone.Y]))';
LCOEinAssessmentZone = LCOE; LCOEinAssessmentZone(assessmentZoneIndex==0) = 0;
LCOEinAssessmentZone(LCOEinAssessmentZone==0) = nan;

counter = 0;
for i = 1:nx
    for j = 1:ny
        if LCOEinAssessmentZone(i,j) >0
            counter = counter + 1;
            export.LCOE(counter,1) = lonGrid(1,i);
            export.LCOE(counter,2) = latGrid(j,1);
            export.LCOE(counter,3) = LCOEinAssessmentZone(i,j);
        end
    end
end
% figure
worldmap('world');
geoshow(latGrid, lonGrid, LCOEinAssessmentZone','DisplayType','surface');
colorbar;
save stop3.mat
%% LCOH
clear
clc
load stop3.mat
GbusCoordinate = table2array(readtable('Irish energy system data.xlsx',...
    'sheet','Gbus','range','H2:I145'));
nGb = size(GbusCoordinate,1);

distanceToGasBus = zeros(nx,ny);
LCOH_energy = zeros(nx,ny); LCOH_volume = zeros(nx,ny); LCOH_mass = zeros(nx,ny);
LCOA_hyVolume = zeros(nx,ny); LCOH_hyEnergy = zeros(nx,ny); LCOH_hyMass = zeros(nx,ny);
[X,P_battery, P_compressor, P_electrolyzer, P_waterProcess, massWater, q_hy, q_hy_inSCF] = ElectrolysorSizing(OWFcapacity);
for ix = 1:nx
    for iy = 1:ny
        if ~isnan(waterDepth(ix,iy)) && waterDepth(ix,iy) > 0 && assessmentZoneIndex(ix,iy) == 1
            lon = bathymetry_2022.longitude(resolution*(ix-1)+1);
            lat = bathymetry_2022.latitude(resolution*(iy-1)+1);
            distanceToGasBus(ix,iy) =  min(deg2km(distance(repmat([lon,lat],[nGb,1]),GbusCoordinate))); %km
            [LCOH_energy(ix,iy),LCOH_volume(ix,iy),LCOH_mass(ix,iy),LCOA_hyVolume(ix,iy),LCOH_hyEnergy(ix,iy),LCOH_hyMass(ix,iy)] ...
                = evaluateHydrogenCost(OWFcapacity,P_battery, ...
                P_compressor, P_electrolyzer, P_waterProcess,q_hy,distanceToGasBus(ix,iy), ...
                costInd{ix,iy},capacityFactor, loadFactor);
        end
    end
end
LCOH_energy(LCOH_energy==0) = nan; LCOH_volume(LCOH_volume==0) = nan; LCOH_mass(LCOH_mass==0) = nan;
LCOA_hyVolume(LCOA_hyVolume==0) = nan; LCOH_hyEnergy(LCOH_hyEnergy==0) = nan; LCOH_hyMass(LCOH_hyMass==0) = nan;
save stop4.mat
%% simulation
clear
clc
load stop4.mat
load mpcIreland.mat
%

mpc0 = mpc;
[PQ, PV, REF, NONE, BUS_I, BUS_TYPE, PD, QD, GS, BS, BUS_AREA, VM, ...
    VA, BASE_KV, ZONE, VMAX, VMIN, LAM_P, LAM_Q, MU_VMAX, MU_VMIN] = idx_bus;
[GEN_BUS, PG, QG, QMAX, QMIN, VG, MBASE, GEN_STATUS, PMAX, PMIN, ...
    MU_PMAX, MU_PMIN, MU_QMAX, MU_QMIN, PC1, PC2, QC1MIN, QC1MAX, ...
    QC2MIN, QC2MAX, RAMP_AGC, RAMP_10, RAMP_30, RAMP_Q, APF] = idx_gen;
[F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, RATE_C, ...
    TAP, SHIFT, BR_STATUS, PF, QF, PT, QT, MU_SF, MU_ST, ...
    ANGMIN, ANGMAX, MU_ANGMIN, MU_ANGMAX] = idx_brch;
[PW_LINEAR, POLYNOMIAL, MODEL, STARTUP, SHUTDOWN, NCOST, COST] = idx_cost;
baseMVA = 100;
genTypeSet = ["Water"; "Gas"; "Gasoil";"Waste";"Peat";"Coal";"Oil";"Wind";"Solar"];
% get onshore wind generation and PV generation
onshoreWindGenIndex = find(mpc.genType == 'Wind');
nOnshoreWind = size(onshoreWindGenIndex,1);
onshoreWindBusIndex = mpc.gen(onshoreWindGenIndex,1);
onshoreWindCoordinates = table2array(mpc.busName(onshoreWindBusIndex,3:4));

for i = 1:nOnshoreWind
    lonIndex = max(find(onshoreWindCoordinates(i,1)>windMatrix.lon0));
    latIndex = max(find(onshoreWindCoordinates(i,2)>windMatrix.lat0));
    coordinateSet = [windMatrix.lon0(lonIndex),windMatrix.lat0(latIndex); windMatrix.lon0(lonIndex+1), windMatrix.lat0(latIndex); ...
        windMatrix.lon0(lonIndex),windMatrix.lat0(latIndex+1);windMatrix.lon0(lonIndex+1),windMatrix.lat0(latIndex+1)];
    windSpeedSet = [windMatrix.SPEED(:,windMatrix.pointer(lonIndex,latIndex)),windMatrix.SPEED(:,windMatrix.pointer(lonIndex+1,latIndex)),...
        windMatrix.SPEED(:,windMatrix.pointer(lonIndex,latIndex+1)),windMatrix.SPEED(:,windMatrix.pointer(lonIndex+1,latIndex+1))];
    distanceToVertex = distance(repmat(onshoreWindCoordinates(i,:),[4,1]),coordinateSet);
    weight = 1./distanceToVertex.^2 / sum(sum(1./distanceToVertex.^2));

    onshoreWind.windSpeed(:,i) = windSpeedSet * weight; % get wind speed of onshore wind
    onshoreWind.dispatchableCapacity(:,i) = windTurbineModel(onshoreWind.windSpeed(:,i),15) / 15 * mpc.gen(onshoreWindGenIndex(i),PMAX);
end
 

gppIndex_gen = mpc.GEcon(:,3);
mpc.gencost(gppIndex_gen,5:7) = 0; % cost of gpp = 0
mpc.gen(find(mpc.genType == 'Solar'),PMAX) = 0; % set solar generation to zero, can change it later
waterGenIndex = find(mpc.genType == 'Water');
mpc.gen(waterGenIndex,PMAX) = mpc0.gen(waterGenIndex,PMAX)/2; % water generator容量减半

% calculation for a winter week
weekIndex = 20;
nDay = 7;
startHour = (weekIndex-1) * 7 * 24 + 1;
endHour = weekIndex * 7 * 24;

% optimize without offshore wind
NK = 24;
for iDay = 1:nDay
    yalmip('clear')
    onshoreWindCapacity = onshoreWind.dispatchableCapacity(startHour+(iDay-1)*24+1:startHour+iDay*24,:);
    gasDemandCurve = mpc0.gasDemandCurve(startHour+(iDay-1)*24+1:startHour+iDay*24);
    electricityDemandCurve = mpc0.electricityDemandCuve(startHour+(iDay-1)*24+1:startHour+iDay*24);
    gasDemandPowerProportion = mpc0.gasDemandPowerProportion(startHour+(iDay-1)*24+1:startHour+iDay*24);
    [solution, solution_info] = runGEopf_continous(mpc,onshoreWindCapacity,electricityDemandCurve,gasDemandCurve,gasDemandPowerProportion,NK);
    for iGenType = 1:size(genTypeSet,1)
        typeName = genTypeSet(iGenType);
        genIndex = find(mpc.genType == typeName);
        generation((iDay-1)*24+1:iDay*24,iGenType) = sum(solution.Pg(:,genIndex'),2); % 回头得加上hydro和solar
    end
end
% optimize with offshore wind
for iOWF = 1:nOWF
    % modify the mpc file
    mpc_withOWF = mpcUpdateWithOWF(mpc);
    results = runGEopf_continous(mpc_withOWF);
end
save stop5.mat
%% evaluate LCOH of other countries
clear
clc
load stop5.mat

EUshp.EEZ = readshp('eez_v12.shp');                                         % load Exclusive Economic Zone for all EU
nCountry = size(EUshp.EEZ,1);
EUcountryList = ["Belgium", "Denmark", "France", "Germany", "Netherlands", "Norway", "Portugal", "Spain", "Sweden", "United Kingdom"];

for i = 1:nCountry
    EUshp.EEZ(i).TERRITORY1 = convertCharsToStrings(EUshp.EEZ(i).TERRITORY1);
    EUshp.EEZ(i).POL_TYPE = convertCharsToStrings(EUshp.EEZ(i).POL_TYPE);
end
countryIndex = ismember([EUshp.EEZ.TERRITORY1],EUcountryList);
EUshp.EEZ = EUshp.EEZ(countryIndex); % only consider homeland not colony
EUshp.EEZ = EUshp.EEZ(ismember([EUshp.EEZ.POL_TYPE],"200NM"));
c
EUshp.boundingBox = [-16.1,36.5;34.8,74.6];

% data required: wind (u,v), radiation, water depth, distance to port, distance to power node (nearest town)
fileName = "EUclimate.nc"; fileInfo = ncinfo(fileName);
EUlon = ncread(fileName, 'longitude'); EUlat = ncread(fileName, 'latitude');
EUtime = ncread(fileName, 'time'); 
EUu100 = ncread(fileName, 'u100'); EUv100 = ncread(fileName, 'v100'); 
EUp140209 = ncread(fileName, 'p140209'); EUcdir = ncread(fileName, 'cdir');

load('bathymetry_2022_Portugal.mat');