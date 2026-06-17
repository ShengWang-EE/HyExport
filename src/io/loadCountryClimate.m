function [climate_interpolated,spatiResolution,lonGrid_mesh, latGrid_mesh] = loadCountryClimate(EEZ,nGrid)
%% get climate
fileName = resolveProjectFile("EUclimate.nc"); fileInfo = ncinfo(fileName);
climate.lon = ncread(fileName, 'longitude'); 
climate.lat = flip(ncread(fileName, 'latitude')); % lat is reversed!
climate.windSpeed = sqrt((flip(ncread(fileName, 'u100'),2)).^2 + (flip(ncread(fileName, 'v100'),2)).^2);
% climate.ssr = flip(ncread(fileName, 'ssr'),2);

minLonIndex = max(find(EEZ.minLon>=climate.lon)); % climate should cover all EEZ
maxLonIndex = min(find(EEZ.maxLon<=climate.lon));
minLatIndex = max(find(EEZ.minLat>=climate.lat));
maxLatIndex = min(find(EEZ.maxLat<=climate.lat));
% save as the same name to save memory
nLon = maxLonIndex - minLonIndex + 1;
nLat = maxLatIndex - minLatIndex + 1;

climate.lon = climate.lon(minLonIndex:maxLonIndex);
climate.lat = climate.lat(minLatIndex:maxLatIndex);
% climate.ssr = climate.ssr(minLonIndex:maxLonIndex,minLatIndex:maxLatIndex,:);
climate.windSpeed = climate.windSpeed(minLonIndex:maxLonIndex,minLatIndex:maxLatIndex,:);

climate.meanWindSpeed = mean(climate.windSpeed,3);

%% adjust resolution
nPeriod = 365; % avoid out of memory
timeResolution = 8760 / nPeriod;
lonGrid = linspace(EEZ.minLon,EEZ.maxLon,nGrid);
latGrid = linspace(EEZ.minLat, EEZ.maxLat,nGrid);

spatiResolution.lon = (EEZ.maxLon - EEZ.minLon) / nGrid;
spatiResolution.lat = (EEZ.maxLat - EEZ.minLat) / nGrid;

[lonGrid_mesh, latGrid_mesh] = meshgrid(lonGrid,latGrid);
nPoint = nLon * nLat;
coordinate = zeros(nPoint,2); 
counter = 0;
for iLat = 1:nLat
    for iLon = 1:nLon
        counter = counter + 1;
        coordinate(counter,1) = climate.lon(iLon);
        coordinate(counter,2) = climate.lat(iLat);
    end
end
meanWindSpeedinRow = reshape(climate.meanWindSpeed,[1,nPoint]); %先列再行(先遍历Lon)

climate_interpolated.lon = lonGrid;
climate_interpolated.lat = latGrid;
climate_interpolated.meanWindSpeed = griddata(coordinate(:,1),coordinate(:,2),meanWindSpeedinRow',lonGrid_mesh,latGrid_mesh);
for h = 1:nPeriod
    windSpeedinRow = reshape(mean(climate.windSpeed(:,:,(h-1)*timeResolution+1:h*timeResolution),3),[1,nPoint]); 
    climate_interpolated.windSpeed(:,:,h) = griddata(coordinate(:,1),coordinate(:,2),windSpeedinRow',lonGrid_mesh,latGrid_mesh);
end
end
