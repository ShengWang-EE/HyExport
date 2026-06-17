function [LCOH_energy,LCOH_volume,LCOH_mass,LCOA_hyVolume,LCOH_hyEnergy,LCOH_hyMass] = evaluateHydrogenCost(OWFcapacity,P_battery, ...
    P_compressor, P_electrolyzer, P_waterProcess,q_hy,distanceToGasBus,OWFcost, ...
    capacityFactor, loadFactor)
%% parameters
p2e = 1.17; % pound to euro
u2e = 0.93; % usd to euro
heatValueHydrogen = 12.75 * 1e6;      % J/m3
densityHydrogenSTP = 0.08988; % kg/m3

AlkalineElectrolyser.CAPEXrate = [   625     400     300     ] * 1e3; % euro/MW (for 2020, 2030, 2050)
hydrogenCompressor.CAPEXrate =   [   3.3     2.3     2.0     ] * 1e3 * p2e; %
battery.CAPEXrate =              [   48.2    35.5    19.3    ] * 1e3 * p2e;
waterDesalination.CAPEXrate =    [   1.2     0.8     0.2     ] * 1e3 * p2e;
platform.CAPEXrate =             [   198.4   167.5   111.5   ] * 1e3 * p2e;
systemReplacement.CAPEXrate =    [   9.37    18.05   9.82    ] * 1e3 * p2e;
pipeline.CAPEXrate =              [  37360    37360*0.99^10    37360*0.99^20    ] * u2e; % $->euro/(in*km)和直径相关

AlkalineElectrolyser.OPEXrate = AlkalineElectrolyser.CAPEXrate * 0.02;
hydrogenCompressor.OPEXrate =   [   0.10    0.07    0.03    ] * 1e3 * p2e;
battery.OPEXrate =              [   1.20    0.89    0.48    ] * 1e3 * p2e;
waterDesalination.OPEXrate =   [   0.04    0.02    0.01    ] * 1e3 * p2e;
pipeline.OPEXrate          =   pipeline.CAPEXrate * 0.03;
platform.OPEXrate = 2.5 * 1e3 * p2e;

pipelineDiameter = 22.7; % inch

lifetime = 27; % year
discountRate = 0.06;
%% 1 DEVEX (additional 0.2 of OWF cost)
DEVEX = 0.2 * OWFcost.DEVEX * u2e;
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
capacity.waterDesalination = OWFcapacity * ceil(P_waterProcess/1e6);
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

opex.pipeline = 0.03 * capex.pipeline;

% sum
OPEXperyear = opex.AlkalineElectrolyser + opex.hydrogenCompressor + opex.battery ...
    + opex.waterDesalination + opex.platform + opex.pipeline;
OPEX = sum(OPEXperyear(1) ./ (1+discountRate).^[0:lifetime-1]);
%% DECEX
DECEX = 0.0938 * capex.installation / (1+discountRate).^(lifetime-1);
%% 

totalCost = DEVEX(1) + CAPEX(1) + OPEX(1) + DECEX(1) + OWFcost.totalCost;

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
OPEXpipeline = sum(opex.pipeline(1) ./ (1+discountRate).^[0:lifetime-1]);
totalCost_ammonia = totalCost + CAPEXammonia + OPEXammonia - capex.pipeline(1) - OPEXpipeline;

LCOA_hyVolume = totalCost_ammonia / hydrogenVolume;
LCOH_hyEnergy = totalCost_ammonia / hydrogenEnergy;
LCOH_hyMass = totalCost / hydrogenMass;
end