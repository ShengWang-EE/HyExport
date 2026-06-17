function [supplyCurve_new,waterDepthColumn_new,lonColumn_new,latColumn_new] = ...
    adjustSupplyCurve(supplyCurve,capacityRange,capacityResolution,waterDepthColumn,lonColumn,latColumn)
%% adjust range
maxIndex = min(find(supplyCurve(:,1)>capacityRange));
if ~isempty(maxIndex)
    supplyCurve_new = supplyCurve(1:maxIndex,:);
    waterDepthColumn_new = waterDepthColumn(1:maxIndex,:);
    lonColumn_new = lonColumn(1:maxIndex,:);
    latColumn_new = latColumn(1:maxIndex,:);
else
    supplyCurve_new = supplyCurve;
    waterDepthColumn_new = waterDepthColumn;
    lonColumn_new = lonColumn;
    latColumn_new = latColumn;
end
slope = (supplyCurve(2,2) - supplyCurve(1,2)) / (supplyCurve(2,1) - supplyCurve(1,1));
addPoint = supplyCurve(1,2) - slope * supplyCurve(1,1);
supplyCurve_new = [0,addPoint;supplyCurve_new];
waterDepthColumn_new = [waterDepthColumn_new(1);waterDepthColumn_new];
lonColumn_new = [lonColumn_new(1);lonColumn_new]; latColumn_new = [latColumn_new(1);latColumn_new];
%% adjust resolution
if size(supplyCurve_new,1) > capacityResolution
    capacityArray = (0:supplyCurve_new(end,1)/capacityResolution:supplyCurve_new(end,1))';
    costArray = interp1(supplyCurve_new(:,1),supplyCurve_new(:,2),capacityArray);
    waterDepthColumn_new = interp1(supplyCurve_new(:,1),waterDepthColumn_new,capacityArray);
    lonColumn_new = interp1(supplyCurve_new(:,1),lonColumn_new,capacityArray);
    latColumn_new = interp1(supplyCurve_new(:,1),latColumn_new,capacityArray);
    supplyCurve_new = [capacityArray,costArray];
end
end