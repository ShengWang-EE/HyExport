function [IrelandShp] = loadIrelandShpData()
%
% IrelandShp.country = readshp('gadm41_IRL_0.shp');                         % load basemap
% IrelandShp.county = readshp('gadm41_IRL_1.shp');
% UKshp.country = readshp('gadm41_GBR_0.shp');

IrelandShp.EES = readshp(resolveProjectFile('Maritime_Boundary_Exclusive_Economic_Zone.shp')); % load Exclusive Economic Zone
IrelandShp.studyArea = readshp(resolveProjectFile('OREDP_Study_Area.shp'));
IrelandShp.assessmentZone = readshp(resolveProjectFile('OREDP_Assessment_Zone.shp'));         % conduct assessment in this area

% IrelandShp.OWFapproved = readshp('Energy_Offshore_Renewable.shp');       % areas of offshore wind under foreshore process
IrelandShp.OWFforeshore = readshp(resolveProjectFile('offshore areas (early planning).shp'));

% % excluded areas
aquacultureSites = readshp(resolveProjectFile('AquacultureSites.shp'));            % Aquaculture Sites
protectedMarineSites = readshp(resolveProjectFile('Protected_Marine_Sites.shp'));  % Special Area of Conservation
militaryAreas = readshp(resolveProjectFile('EMODnet_HA_MilitaryAreas_pg_20221216.shp'));  % militaryAreas

% aquacultureSites_polyshape = polyshape([aquacultureSites.X],[aquacultureSites.Y]);
% protectedMarineSites_polyshape = polyshape([protectedMarineSites.X],[protectedMarineSites.Y]);
% militaryAreas_polyshape = polyshape([militaryAreas.X],[militaryAreas.Y]);
% excludedAreas = Union([aquacultureSites_polyshape,protectedMarineSites_polyshape,militaryAreas_polyshape]);

% ; IrelandShp.protectedMarineSites; IrelandShp.militaryAreas];
% 
% % penalized areas
% % inshore fishing
% IrelandShp.dredgeFishing = readshp('Dredge_Fishing.shp');
% IrelandShp.lineFishing = readshp('Line_Fishing.shp');
% IrelandShp.midwaterTrawlFishing = readshp('Midwater_Trawl_Fishing.shp');
% IrelandShp.netsFishing = readshp('Nets_Fishing.shp');
% IrelandShp.bottomTrawlFishing = readshp('Bottom_Trawl_Fishing.shp');
% IrelandShp.potFishing = readshp('Pot_Fishing.shp');
% % offshore fishing
% IrelandShp.offshoreFishing = readshp('Fishing_Method_All_Gears.shp');
% % vessel density
% [A,R] = readgeoraster('vesseldensity_all_2022.tif');

%% bounding box
boundingBoxMatrix = [IrelandShp.assessmentZone.BoundingBox];
boundingBoxPositive = boundingBoxMatrix(boundingBoxMatrix > 0);
boundingBoxNegtive = boundingBoxMatrix(boundingBoxMatrix < 0);
[IrelandShp.boundingBoxOfAssessmentZone.minLon, IrelandShp.boundingBoxOfAssessmentZone.maxLon, ...
    IrelandShp.boundingBoxOfAssessmentZone.minLat, IrelandShp.boundingBoxOfAssessmentZone.maxLat] ...
    = deal(min(min(boundingBoxNegtive)),max(max(boundingBoxNegtive)), ...
    min(min(boundingBoxPositive)), max(max(boundingBoxPositive))) ;
IrelandShp.boundingBox.X = [IrelandShp.boundingBoxOfAssessmentZone.minLon, IrelandShp.boundingBoxOfAssessmentZone.minLon,IrelandShp.boundingBoxOfAssessmentZone.maxLon,IrelandShp.boundingBoxOfAssessmentZone.maxLon,IrelandShp.boundingBoxOfAssessmentZone.minLon,NaN];
IrelandShp.boundingBox.Y = [IrelandShp.boundingBoxOfAssessmentZone.minLat,IrelandShp.boundingBoxOfAssessmentZone.maxLat,IrelandShp.boundingBoxOfAssessmentZone.maxLat,IrelandShp.boundingBoxOfAssessmentZone.minLat,IrelandShp.boundingBoxOfAssessmentZone.minLat,NaN];
end
