function [onshoreWindAvaliableCapacity,onshoreSolarAvaliableCapacity,hydroAvaliableCapacity,interconnectorAvaliableCapacity,offshoreWindAvaliableCapacityCoeff] = ...
    renewableGeneration(EUshpEEZ,mpc,nGrid,irelandPowerSystemOperation,lonColumn,latColumn,LCOEcurve)
%%
[GEN_BUS, PG, QG, QMAX, QMIN, VG, MBASE, GEN_STATUS, PMAX, PMIN, ...
    MU_PMAX, MU_PMIN, MU_QMAX, MU_QMIN, PC1, PC2, QC1MIN, QC1MAX, ...
    QC2MIN, QC2MAX, RAMP_AGC, RAMP_10, RAMP_30, RAMP_Q, APF] = idx_gen;

fileName = resolveProjectFile("EUclimate.nc"); fileInfo = ncinfo(fileName);
climate.lon = double(ncread(fileName, 'longitude')); 
climate.lat = double(flip(ncread(fileName, 'latitude'))); % lat is reversed!
climate.windSpeed = double(sqrt((flip(ncread(fileName, 'u100'),2)).^2 + (flip(ncread(fileName, 'v100'),2)).^2));
climate.ssr = double(flip(ncread(fileName, 'ssr'),2));

[~,nOffshoreWind] = max(LCOEcurve(:,1) > 37000);
%% onshore wind
onshoreWindGenIndex = find(mpc.genType == 'Wind');
nOnshoreWind = size(onshoreWindGenIndex,1);
onshoreWindBusIndex = mpc.gen(onshoreWindGenIndex,1);
onshoreWindCoordinates = table2array(mpc.busName(onshoreWindBusIndex,3:4));
%% solar
onshoreSolarGenIndex = find(mpc.genType == 'Solar');
nOnshoreSolar = size(onshoreSolarGenIndex,1);
onshoreSolarBusIndex = mpc.gen(onshoreSolarGenIndex,1);
onshoreSolarCoordinates = table2array(mpc.busName(onshoreSolarBusIndex,3:4));
%% interp
[lat_meshed,lon_meshed] = meshgrid(climate.lat,climate.lon);
windSpeed = zeros(8760,nOnshoreWind); solarRadiation = zeros(8760,nOnshoreSolar);
offshoreWindSpeed = zeros(8760,nOffshoreWind);

for h = 1:8760
    windSpeed(h,:) = (interp2(lat_meshed,lon_meshed,climate.windSpeed(:,:,h),onshoreWindCoordinates(:,2),onshoreWindCoordinates(:,1)))';
    offshoreWindSpeed(h,:) = (interp2(lat_meshed,lon_meshed,climate.windSpeed(:,:,h),latColumn(1:nOffshoreWind),lonColumn(1:nOffshoreWind)))';
    solarRadiation(h,:) = (interp2(lat_meshed,lon_meshed,climate.ssr(:,:,h),onshoreSolarCoordinates(:,2),onshoreSolarCoordinates(:,1)))';
    windSpeedAtSolarLocation(h,:) = (interp2(lat_meshed,lon_meshed,climate.windSpeed(:,:,h),onshoreSolarCoordinates(:,2),onshoreSolarCoordinates(:,1)))';
end
solarRadiation = solarRadiation/3600; % convert W/m2 to J/(hour*m2)
ratedPowerWind = 8; ratedPowerSolar = mpc.gen(onshoreSolarGenIndex,PMAX);
onshoreWindAvaliableCapacity = windTurbineModel(windSpeed,ratedPowerWind) / ratedPowerWind .* repmat(mpc.gen(onshoreWindGenIndex,PMAX)',[8760,1]);
offshoreWindAvaliableCapacityCoeff = windTurbineModel(offshoreWindSpeed,ratedPowerWind) / ratedPowerWind;
onshoreSolarAvaliableCapacity = PVPower_Beckman(ratedPowerSolar,solarRadiation,windSpeedAtSolarLocation);
% for i = 1:nOnshoreWind
%     lonIndex = max(find(onshoreWindCoordinates(i,1)>climate.lon));
%     latIndex = max(find(onshoreWindCoordinates(i,2)>climate.lat));
%     coordinateSet = [climate.lon(lonIndex),climate.lat(latIndex); climate.lon(lonIndex+1), climate.lat(latIndex); ...
%         climate.lon(lonIndex),climate.lat(latIndex+1);climate.lon(lonIndex+1),climate.lat(latIndex+1)];
%     windSpeedSet = [windMatrix.SPEED(:,windMatrix.pointer(lonIndex,latIndex)),windMatrix.SPEED(:,windMatrix.pointer(lonIndex+1,latIndex)),...
%         windMatrix.SPEED(:,windMatrix.pointer(lonIndex,latIndex+1)),windMatrix.SPEED(:,windMatrix.pointer(lonIndex+1,latIndex+1))];
%     distanceToVertex = distance(repmat(onshoreWindCoordinates(i,:),[4,1]),coordinateSet);
%     weight = 1./distanceToVertex.^2 / sum(sum(1./distanceToVertex.^2));
% 
%     onshoreWind.windSpeed(:,i) = windSpeedSet * weight; % get wind speed of onshore wind
%     onshoreWind.dispatchableCapacity(:,i) = windTurbineModel(onshoreWind.windSpeed(:,i),15) / 15 * mpc.gen(onshoreWindGenIndex(i),PMAX);
% end
%% hydro
hydroGenIndex = find(mpc.genType == 'Water');
nHydro = size(hydroGenIndex,1);
AIHydro = irelandPowerSystemOperation.AIHydro;
AIHydro = AIHydro(1:4:4*8759+1);

hydroAvaliableCapacity = repmat(AIHydro,[1,nHydro]) / sum(mpc.gen(hydroGenIndex,PMAX)) ...
    .* repmat((mpc.gen(hydroGenIndex,PMAX))',[8760,1]);
%% interconnector
interconnectorAvaliableCapacity = [irelandPowerSystemOperation.MoyleI_C(1:4:4*8759+1),irelandPowerSystemOperation.EWICI_C(1:4:4*8759+1)];
end
