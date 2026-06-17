function bathymetry_interpolated = loadCountryBathymetry(countryEEZ,countryName,nGrid)

load(resolveProjectFile(['bathymetry_2022_',countryName,'.mat'])); % var name bathymetry_2022

minLonIndex = find(countryEEZ.minLon>=bathymetry_2022.longitude,1,'last');
maxLonIndex = find(countryEEZ.maxLon<=bathymetry_2022.longitude,1,'first');
minLatIndex = find(countryEEZ.minLat>=bathymetry_2022.latitude,1,'last');
maxLatIndex = find(countryEEZ.maxLat<=bathymetry_2022.latitude,1,'first');

% nLon = maxLonIndex - minLonIndex + 1;
% nLat = maxLatIndex - minLatIndex + 1;
% minLon = bathymetry_2022.longitude(minLonIndex); maxLon = bathymetry_2022.longitude(maxLonIndex);
% minLat = bathymetry_2022.latitude(minLatIndex); maxLat = bathymetry_2022.latitude(maxLatIndex);

bathymetry.lon = bathymetry_2022.longitude(minLonIndex:maxLonIndex);
bathymetry.lat = bathymetry_2022.latitude(minLatIndex:maxLatIndex);
bathymetry.elevation = bathymetry_2022.elevation(minLatIndex:maxLatIndex,minLonIndex:maxLonIndex);

%% adjust resolution(别用插值，算不过来，找个最近的就行了）
lonGrid = linspace(countryEEZ.minLon,countryEEZ.maxLon,nGrid);
latGrid = linspace(countryEEZ.minLat, countryEEZ.maxLat,nGrid);

[~, iLon] = min(abs(bsxfun(@minus, lonGrid, bathymetry.lon)));
[~, iLat] = min(abs(bsxfun(@minus, latGrid, bathymetry.lat)));


bathymetry_interpolated.lon = lonGrid;
bathymetry_interpolated.lat = latGrid;
bathymetry_interpolated.elevation = bathymetry.elevation(iLat,iLon);

end
