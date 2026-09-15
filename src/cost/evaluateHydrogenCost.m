function [LCOH_energy,LCOH_volume,LCOH_mass,LCOA_hyVolume,LCOH_hyEnergy,LCOH_hyMass] = evaluateHydrogenCost(OWFcapacity,P_battery, ...
    P_compressor, P_electrolyzer, P_waterProcess,q_hy,distanceToGasBus,OWFcost, ...
    capacityFactor, loadFactor, year, windCostFactor)
%% parameters
u2e = 0.93; % usd to euro
heatValueHydrogen = 12.75 * 1e6;      % J/m3
densityHydrogenSTP = 0.08988; % kg/m3

% Select scalar equipment prices for this model year before computing costs.
costs = hydrogenCostParameters(year);
AlkalineElectrolyser.CAPEXrate = costs.capex.electrolyser;
hydrogenCompressor.CAPEXrate = costs.capex.compressor;
battery.CAPEXrate = costs.capex.battery;
waterDesalination.CAPEXrate = costs.capex.water;
platform.CAPEXrate = costs.capex.platform;
systemReplacement.CAPEXrate = costs.capex.replacement;
pipeline.CAPEXrate = costs.capex.pipeline;
AlkalineElectrolyser.OPEXrate = costs.opex.electrolyser;
hydrogenCompressor.OPEXrate = costs.opex.compressor;
battery.OPEXrate = costs.opex.battery;
waterDesalination.OPEXrate = costs.opex.water;
platform.OPEXrate = costs.opex.platform;
pipeline.OPEXrate = costs.opex.pipeline;

pipelineDiameter = 22.7; % inch

lifetime = 27; % year
discountRate = 0.06;
%% 1 DEVEX (additional 0.2 of OWF cost)
DEVEX = 0.2 * OWFcost.DEVEX * u2e * windCostFactor;
%% 2 CAPEX
% 2.1 AlkalineElectrolyser
capacity.electrolyser = ceil(P_electrolyzer/1e8) * 100; % 取整100MW
capex.AlkalineElectrolyser = AlkalineElectrolyser.CAPEXrate * capacity.electrolyser; 
% 2.2 hydrogenCompressor
capacity.hydrogenCompressor = ceil(P_compressor/1e6); % 取整10MW
capex.hydrogenCompressor = hydrogenCompressor.CAPEXrate * capacity.hydrogenCompressor; 
% 2.3 battery
capacity.battery = OWFcapacity * 0.1;
capex.battery = battery.CAPEXrate * capacity.battery; 
% 2.4 waterDesalination
capacity.waterDesalination = ceil(P_waterProcess/1e6); % MW, total water-processing capacity
capex.waterDesalination = waterDesalination.CAPEXrate * capacity.waterDesalination; 
% platform
capex.platform = platform.CAPEXrate * capacity.electrolyser; 
% systemReplacement
capex.systemReplacement = systemReplacement.CAPEXrate * capacity.electrolyser; 
% pipeline
capex.pipeline = pipelineDiameter * distanceToGasBus * pipeline.CAPEXrate;

CAPEX1 = capex.AlkalineElectrolyser + capex.hydrogenCompressor + capex.battery ...
    + capex.waterDesalination + capex.platform + capex.systemReplacement + capex.pipeline;

% installation
capex.installation = OWFcost.installation * 7 / OWFcost.CAPEX * CAPEX1; %因为原来的除以10了

% sum
CAPEX = CAPEX1 + capex.installation;
%% OPEX
opex.AlkalineElectrolyser = capacity.electrolyser * AlkalineElectrolyser.OPEXrate;

opex.hydrogenCompressor = hydrogenCompressor.OPEXrate * capacity.hydrogenCompressor; 

opex.battery = battery.OPEXrate * capacity.battery; 

opex.waterDesalination = waterDesalination.OPEXrate * capacity.waterDesalination; 

opex.platform = capacity.electrolyser * platform.OPEXrate;

opex.pipeline = pipelineDiameter * distanceToGasBus * pipeline.OPEXrate;

% sum
OPEXperyear = opex.AlkalineElectrolyser + opex.hydrogenCompressor + opex.battery ...
    + opex.waterDesalination + opex.platform + opex.pipeline;
OPEX = sum(OPEXperyear ./ (1+discountRate).^[0:lifetime-1]);
%% DECEX
DECEX = 0.0938 * capex.installation / (1+discountRate).^(lifetime-1);
%% 

% Wind learning applies only to wind-linked expenditure. Equipment prices
% already contain their annual projections and must not be discounted again.
totalCost = DEVEX + CAPEX + OPEX + DECEX + OWFcost.totalCost * windCostFactor;

hydrogenVolume = lifetime * 365*24*3600 * q_hy * capacityFactor * 1e-6; % Mm3
hydrogenEnergy = hydrogenVolume * heatValueHydrogen / 3600; % MWh
hydrogenMass = hydrogenVolume * 1e6 * densityHydrogenSTP;

LCOH_volume = totalCost / hydrogenVolume;
LCOH_energy = totalCost / hydrogenEnergy;
LCOH_mass = totalCost / hydrogenMass;

%% additional cost for ammonia
% Air separation and Haber–Bosch reactor 
ammoniaProduction.CAPEXrate = 990 * 1e3;  % euro/(ton/day)
CAPEXammonia = ammoniaProduction.CAPEXrate * (q_hy*densityHydrogenSTP/1e3*24*3600);
opex.ammoniaProduction = CAPEXammonia * 0.02;
OPEXammonia = sum(opex.ammoniaProduction ./ (1+discountRate).^[0:lifetime-1]);
OPEXpipeline = sum(opex.pipeline ./ (1+discountRate).^[0:lifetime-1]);
totalCost_ammonia = totalCost + CAPEXammonia + OPEXammonia - capex.pipeline - OPEXpipeline;

LCOA_hyVolume = totalCost_ammonia / hydrogenVolume;
LCOH_hyEnergy = totalCost_ammonia / hydrogenEnergy;
LCOH_hyMass = totalCost / hydrogenMass;
end