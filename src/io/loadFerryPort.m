function [ferryPortShp_noAggregation,ferryPortShp_aggregated,portIndexPerCountry,portInCountry] = loadFerryPort(filename,nCountry)
% merge these ports that are close and belong to the same country to reduce
% number of variables
%% preliminarily identify the ports in EU by country name
ferryPortShp = readshp(filename); 
nPort = size(ferryPortShp,1);
countryCodeList = ["BE","DK","FR","DE","IE","NL","NO","PT","ES","SE","UK"];


for iPort = 1:nPort
    ferryPortShp(iPort).CNTR_CODE = convertCharsToStrings(ferryPortShp(iPort).CNTR_CODE);
    isInCountryList(iPort) = ismember(ferryPortShp(iPort).CNTR_CODE,countryCodeList);
end
ferryPortShp(~isInCountryList) = [];

%% further excluded the colony ports
portCoordinates = [[ferryPortShp.X]',[ferryPortShp.Y]'];
EUlatmin = 35; EUlatmax = 71;
EUlonmin = -11; EUlonmax = 32;
portIndexOutEU = find( (portCoordinates(:,1)<EUlonmin | portCoordinates(:,1)>EUlonmax) | ...
    (portCoordinates(:,2)<EUlatmin | portCoordinates(:,2)>EUlatmax) );
ferryPortShp(portIndexOutEU) = [];
%% reduce the number of ports
mergeDistance = 100; % km, can be changed to see the results

nPort = size(ferryPortShp,1);
portCoordinates = [[ferryPortShp.X]',[ferryPortShp.Y]'];
portDistances = deg2km(pdist2(portCoordinates,portCoordinates));
aggregated_points = {}; aggregated_indices = [];
for i = 1:nPort
        if ~ismember(i,aggregated_indices)
            nearbyIndices = find(portDistances(i,:) < mergeDistance);
            nearbyIndices(ismember(nearbyIndices,aggregated_indices)) = [];
            if ~isempty(nearbyIndices)
                aggregated_points{end+1} = nearbyIndices;
                aggregated_indices = [aggregated_indices, nearbyIndices];
            end
        end
end

ferryPortShp_noAggregation = ferryPortShp;
for i = 1:size(aggregated_points,2)
    centerIndex(i) = aggregated_points{i}(1);
end
ferryPortShp_aggregated = ferryPortShp_noAggregation(centerIndex);

%% mappings
nPort = size(ferryPortShp_aggregated,1);
portInCountry = zeros(nPort,1);
for ic = 1:nCountry
    portIndexPerCountry{ic} = find([ferryPortShp_aggregated.CNTR_CODE]==countryCodeList(ic));
    portInCountry(portIndexPerCountry{ic}) = ic;
end