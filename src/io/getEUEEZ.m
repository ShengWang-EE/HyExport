function [EUshpEEZ] = getEUEEZ(fileName,EUcountryList)
%GETEUEEZ Summary of this function goes here
%   Detailed explanation goes here
EUshpEEZ = readshp(fileName);                                         % load Exclusive Economic Zone for all EU
nCountry = size(EUshpEEZ,1);

for i = 1:nCountry
    EUshpEEZ(i).TERRITORY1 = convertCharsToStrings(EUshpEEZ(i).TERRITORY1);
    EUshpEEZ(i).POL_TYPE = convertCharsToStrings(EUshpEEZ(i).POL_TYPE);
end
countryIndex = ismember([EUshpEEZ.TERRITORY1],EUcountryList);
EUshpEEZ = EUshpEEZ(countryIndex); % only consider homeland not colony
EUshpEEZ = EUshpEEZ(ismember([EUshpEEZ.POL_TYPE],"200NM"));

nEUcountry = size(EUshpEEZ,1);
for i = 1:nEUcountry
    [EUshpEEZ(i).minLon, EUshpEEZ(i).maxLon, ...
        EUshpEEZ(i).minLat, EUshpEEZ(i).maxLat] ...
        = deal(EUshpEEZ(i).BoundingBox(1,1), EUshpEEZ(i).BoundingBox(2,1), ...
        EUshpEEZ(i).BoundingBox(1,2), EUshpEEZ(i).BoundingBox(2,2));
end

end

