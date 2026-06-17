function [LCOE, cost] = evaluateOWFelectricityCost(OWFtype,capacityFactor,loadFactor,windTurbine,...
    waterDepth,distanceToConnectPoint,distanceBetweenTurbine,distanceToPort,OWFcapacity)

%% default paras
p2e = 1.17; % pound to euro
u2e = 0.93; % usd to euro
nWindTurbine = OWFcapacity / windTurbine.ratedPower;
MPTratedPower = 300;
ratedPowerCable = 300; %MW
lifetime = 27; % year
nMooring = 4;
interconnectVoltage = 220; % 220 kv
discountRate = 0.06;
distanceToPort = distanceToPort / 1e3;
avaliability = 0.95;

% 这里全都用美元（别用欧元，因为后面会有平方三次方等，算不清楚）。到最后再一次性转化为欧元
costRate.monopile = 2250; 
costRate.monopileTransitionPiece = 3230;
costRate.jacketMainLattice = 4680;
costRate.jacketTransitionPiece = 4500;
costRate.jacketPile = 2250;
costRate.semisubmersibleStiff = 3120;
costRate.semisubmersibleTruss = 6250;
costRate.semisubmersibleHeavePlate = 6250;
costRate.anchor = 123000 / u2e; % euro->$
costRate.mooring = 48 / u2e; % euro->$
costRate.chain = 270 / u2e; % euro->$
costRate.secondarySteel = 7250;
costRate.mainPowerTransformer = 12500;
costRate.highVoltageSwitchgear = 950000;
costRate.midVoltageSwitchgear = 500000;
costRate.topside = 14500;
costRate.substationSubstructure = 3230;    % ?
costRate.substructurePile = 2250;
costRate.exportCable = 0.1*sqrt(ratedPowerCable) * 1e6 * 1e-3; % 
costRate.arrayCable = 0.1*sqrt(windTurbine.ratedPower*1.2) * 1e6 * 1e-3;

%% 1 DEVEX
% 1.1 Development and project management https://guidetoanoffshorewindfarm.com/wind-farm-costs
cost.developmentConsenting = 5000 * OWFcapacity * p2e / u2e;
% 1.2 Environmental surveys
cost.enviromentalSurvey = 4000 * OWFcapacity * p2e / u2e;
% 1.3 Resource and metocean assessment
cost.resourceMetocean = 4000 * OWFcapacity * p2e / u2e;
% 1.4 Geological and hydrological surveys
cost.geologicalHydrological = 4000 * OWFcapacity * p2e / u2e;
% 1.5 Engineering and consultancy
cost.engineeringConsultancy = 4000 * OWFcapacity * p2e / u2e;
% 1.6 Other (includes lost projects that incur development expenditure)
cost.otherDevelopmentProject = 54000 * OWFcapacity * p2e / u2e;
% 1.7 addup
DEVEX = cost.developmentConsenting + cost.enviromentalSurvey + cost.resourceMetocean ...
    + cost.geologicalHydrological + cost.engineeringConsultancy + cost.otherDevelopmentProject;

%% 2 CAPEX
% 2.1 wind turbine
cost.WindTurbine = (1.6 * windTurbine.ratedPower - 1.9) * 1e6;

% 2.2 monopile foundation (fixed)
% 2.2.1 monopile
mass.rotorNacelleAssembly = 2.082*windTurbine.ratedPower.^2 + 44.59*windTurbine.ratedPower + 22.48;
mass.monopile = 1e-4 * ( (windTurbine.ratedPower*1000).^1.5 + windTurbine.hubHeight.^3.7/10 + 2100*waterDepth.^2.25 ...
    + mass.rotorNacelleAssembly.^1.13);
cost.monopile = mass.monopile * costRate.monopile;
% 2.2.2 Monopile Transition Piece
mass.monopileTransitionPiece = exp(2.77 + 1.04*windTurbine.ratedPower.^0.5 + 0.00127*waterDepth.^1.5);
cost.monopileTransitionPiece = mass.monopileTransitionPiece * costRate.monopileTransitionPiece;
% 2.2.3 addup
cost.monopileFoundation = cost.monopile + cost.monopileTransitionPiece;

% 2.3 Jacket foundation (fixed)
% 2.3.1 Jacket main lattice
mass.jacketMainLattice = exp(3.71 + 0.00176*windTurbine.ratedPower.^2.5 + 0.645*log(waterDepth.^1.5));
cost.jacketMainLattice = mass.jacketMainLattice * costRate.jacketMainLattice;
% 2.3.2 Jacket transition piece
mass.jacketTransitionPiece = 1/((-0.0131+0.0381)/log(windTurbine.ratedPower) - 2.27*1e-9*waterDepth.^3);
cost.jacketTransitionPiece = mass.jacketTransitionPiece * costRate.jacketTransitionPiece;
% 2.3.3 Jacket pile
mass.jacketPile = 8*mass.jacketMainLattice.^0.5574;
cost.jacketPile = mass.jacketPile * costRate.jacketPile;
% 2.3.4 addup
cost.jacketFoundation = cost.jacketMainLattice + cost.jacketTransitionPiece + cost.jacketPile;

% 2.4 Semi-submersible foundation (floating)
% 2.4.1 Semi-submersible stiffened column
mass.semisubmersibleStiff = -0.9571*windTurbine.ratedPower.^2 + 40.89*windTurbine.ratedPower + 802.09; % ton
cost.semisubmersibleStiff = mass.semisubmersibleStiff * costRate.semisubmersibleStiff;
% 2.4.2 Semi-submersible truss
mass.semisubmersibleTruss = 2.7894*windTurbine.ratedPower.^2 + 15.591*windTurbine.ratedPower + 266.03;
cost.semisubmersibleTruss = mass.semisubmersibleTruss * costRate.semisubmersibleTruss;
% 2.4.3 Semi-submersible heave plate
mass.semisubmersibleHeavePlate = -0.4397*windTurbine.ratedPower.^2 + 21.545*windTurbine.ratedPower + 177.42;
cost.semisubmersibleHeavePlate = mass.semisubmersibleHeavePlate + costRate.semisubmersibleHeavePlate;
% 2.4.4 Mooring and anchor system
cost.mooringAnchor = nMooring * (costRate.anchor + (1.5*waterDepth+410)*costRate.mooring + 50*costRate.chain);
% addup
mass.semisubmersible = mass.semisubmersibleStiff + mass.semisubmersibleTruss + mass.semisubmersibleHeavePlate;
cost.semisubmersible = cost.semisubmersibleStiff + cost.semisubmersibleTruss + cost.semisubmersibleHeavePlate + cost.mooringAnchor;

% 2.5 Secondary steel
mass.secondarySteelFixed = 40 + (0.8*(18+waterDepth));
mass.secondarySteelFloating = -0.153*windTurbine.ratedPower.^2 + 6.54*windTurbine.ratedPower + 128.34;
cost.secondarySteelFixed = mass.secondarySteelFixed * costRate.secondarySteel;
cost.secondarySteelFloating = mass.secondarySteelFloating * costRate.secondarySteel;

% 2.6 offshore substation
% 2.6.1 main power transformer
nMainPowerTransformer = ceil(1.*windTurbine.ratedPower*nWindTurbine / MPTratedPower);
cost.mainPowerTransformer = nMainPowerTransformer * MPTratedPower * costRate.mainPowerTransformer;
% 2.6.2 switchgear
cost.Switchgear = nMainPowerTransformer * (costRate.highVoltageSwitchgear + costRate.midVoltageSwitchgear);
% 2.6.3 Topside
mass.topside = 3.85 * (MPTratedPower*nMainPowerTransformer) + 285;
cost.topside = mass.topside * costRate.topside;
% 2.6.4 Substructure base
mass.substationSubstructureFixed = 0.4 * mass.topside;
mass.substationSubstructureFloating = 2 * (mass.semisubmersible + mass.secondarySteelFloating);
mass.substructurePile = 8*mass.substationSubstructureFixed.^0.5574; %(fixed only)
cost.substationSubstructureFixed = mass.substationSubstructureFixed * costRate.substationSubstructure ...
    + mass.substructurePile*costRate.substructurePile;
cost.substationSubstructureFloating = 2*(cost.semisubmersible + cost.mooringAnchor);
% 2.6.5 addup
cost.offshoreSubstationFixed = cost.mainPowerTransformer + cost.Switchgear...
    + cost.topside + cost.substationSubstructureFixed;
cost.offshoreSubstationFloating = cost.mainPowerTransformer + cost.Switchgear...
    + cost.topside + cost.substationSubstructureFloating;

% 2.7 onshore substation
% 2.7.1 substation cost
cost.substationMain = 11652 * (interconnectVoltage + windTurbine.ratedPower*nWindTurbine) + 1200000;
% 2.7.2 miscellaneous cost
cost.substationMiscellaneous = 11795*OWFcapacity.^0.3549 + 350000;
% 2.7.3 switchyard cost
cost.switchyard = 18115*interconnectVoltage + 165944;
% 2.7.4 addup
cost.onshoreSubstation = cost.substationMain + cost.substationMiscellaneous + cost.switchyard;

% 2.8 cables
% 2.8.1 export cable
nExportCable = ceil(OWFcapacity / ratedPowerCable);
hangingAngle = (-0.0047*waterDepth+18.743)/180*pi;
length.exportCableFloating = waterDepth/ cos(hangingAngle)+190;
cost.exportCableFixed = costRate.exportCable * nExportCable * 1.1 * (2*waterDepth+distanceToConnectPoint);
cost.exportCableFloating = costRate.exportCable * nExportCable * 1.1 * (distanceToConnectPoint + length.exportCableFloating+500);
% 2.8.2 array cale
length.arrayCableFixed = nWindTurbine * (2*waterDepth + distanceBetweenTurbine);
length.arrayCableFloating = nWindTurbine * (2*waterDepth/cos(hangingAngle) + distanceBetweenTurbine);
cost.arrayCableFixed = costRate.arrayCable * length.arrayCableFixed;
cost.arrayCableFloating = costRate.arrayCable * length.arrayCableFloating;
% 2.8.3 addup
cost.cableFixed = cost.exportCableFixed + cost.arrayCableFixed;
cost.cableFloating = cost.exportCableFloating + cost.arrayCableFloating;

    % cost.installation = CAPEX / 0.472 * 0.192;
    % CAPEX = CAPEX + cost.installation;

% 2.9 installation cost
% 2.9.1 Substructure installation cost (waterDepth(m), distanceToPort(km))
cost.substructureInstallation_6MWmonopile = 88705573 - 2965980*waterDepth - 7813*distanceToPort ...
    + 104665*waterDepth.^2 + 1.49*1e-6*distanceToPort.^2 + 661*waterDepth*distanceToPort ...
    - 707*waterDepth.^3 - 1.71*1e-9*distanceToPort.^3 - 2.751e-11*waterDepth*distanceToPort.^2 ...
    + 19.44*waterDepth.^2*distanceToPort;
cost.substructureInstallation_6MWjacket = -4.58*1e8 + 5.17*1e8*log(waterDepth) + 809803*distanceToPort...
    - 1.59*1e8*(log(waterDepth)).^2 + 1.89*1e-7*distanceToPort.^2 - 483412*distanceToPort*log(waterDepth)...
    + 16772093*(log(waterDepth)).^3 - 1.57*1e-10*distanceToPort.^3 - 0.000000016*distanceToPort.^2*log(waterDepth)...
    + 75746*distanceToPort*(log(waterDepth)).^2;
cost.substructureInstallation_6MWsemisubmersible = 18408000 + 7875*waterDepth + 24821*distanceToPort;
cost.substructureInstallation_10MWmonopile = 1.76861e8 - 2.26*1e6/waterDepth + 257702 *distanceToPort...
    +1.21*1e10/waterDepth.^2 + 1.82*1e-8*distanceToPort.^2 - 2558888*(distanceToPort/waterDepth);
cost.substructureInstallation_10MWjacket = 1.27*1e8 - 2490356*waterDepth + 174981*distanceToPort ...
    + 80519*waterDepth.^2 + 7.28*1e-8*distanceToPort.^2 - 4227*waterDepth*distanceToPort ...
    - 514*waterDepth.^3 - 6.37*1e-11*distanceToPort.^3 - 4.5*1e-10*waterDepth*distanceToPort.^2 ...
    + 49.24*waterDepth.^2*distanceToPort;
cost.substructureInstallation_10MWsemisubmersible = 23658000 + 11625*waterDepth + 35450*distanceToPort;
% 2.9.2 Turbine installation cost
cost.turbineInstallation_6MWmonopile = 15687102 + 2685414*waterDepth - 149549*waterDepth.^2 + 3474*waterDepth.^3 ...
    - 34.1*waterDepth.^4 + 0.12*waterDepth.^5 + 3133853*log(distanceToPort);
cost.turbineInstallation_6MWjacket = -17171241 + 18311725*waterDepth - 12467174*waterDepth*log(waterDepth) ...
    + 5716767*waterDepth.^1.5 - 172159*waterDepth.^2 + 15946*distanceToPort;
cost.turbineInstallation_6MWsemisubmersible = 48170500 + 95833*distanceToPort;
cost.turbineInstallation_10MWmonopile = 57108119 + 1166746*waterDepth - 58333*waterDepth.^2 + 1217*waterDepth.^3 ...
    - 10.6*waterDepth.^4 + 0.032*waterDepth.^5 + 24987*distanceToPort;
cost.turbineInstallation_10MWjacket = 37087901 + 3946015*waterDepth - 199518*waterDepth.^2 + 4192*waterDepth.^3 ...
    - 37*waterDepth.^4 + 0.116*waterDepth.^5 + 26874*distanceToPort;
cost.turbineInstallation_10MWsemisubmersible = 59608000 + 120833*distanceToPort;
% 2.9.3 Port and staging cost
cost.portStaging_6MWmonopile = 6419595 + 31553*waterDepth - 5364*waterDepth.^2 + 189*waterDepth - 2.27*waterDepth.^4 ...
    + 0.009*waterDepth.^5 + 6622*distanceToPort;
cost.portStaging_6MWjacket = (303606 + 743543*log(waterDepth) - 2244*distanceToPort - 2.92*distanceToPort.^2) / ...
    (1 - 0.851*log(waterDepth) + 0.273*(log(waterDepth)).^2 - 0.0269*(log(waterDepth).^3) - 0.0003*distanceToPort);
cost.portStaging_6MWsemisubmersible = 10472899 + 2000*waterDepth + 19002*distanceToPort;
cost.portStaging_10MWmonopile = (7533930 - 116296*waterDepth + 1084*waterDepth.^2 - 1.22*waterDepth.^2 - 1425*distanceToPort) / ...
    (1 - 0.013*waterDepth + 8.83*1e-5*waterDepth.^2 - 0.0005*distanceToPort + 2.38*1e-7*distanceToPort);
cost.portStaging_10MWjacket = 21321746 - 8043691*log(waterDepth) + 106665*distanceToPort + 2496413*(log(waterDepth)).^2 ...
    - 0.26*distanceToPort.^2 - 56191*distanceToPort*log(waterDepth) - 219766*(log(waterDepth)).^3 + 0.0003*distanceToPort.^3 ...
    - 2.65*1e-8*distanceToPort.^2*log(waterDepth) + 7912.15*distanceToPort*(log(waterDepth)).^2;
cost.portStaging_10MWsemisubmersible = 15896470 + 2975*waterDepth + 28266*distanceToPort;

% 2.10 adding up
if OWFtype == 1 % monopile
%     cost.installation = 2* cost.substructureInstallation_10MWmonopile -cost.substructureInstallation_6MWmonopile ...
%         + 2* cost.turbineInstallation_10MWmonopile -cost.turbineInstallation_6MWmonopile ...
%         + 2* cost.portStaging_10MWmonopile -cost.portStaging_6MWmonopile;
    cost.foundation = cost.monopileFoundation;
    cost.installation = (cost.substructureInstallation_6MWmonopile + cost.turbineInstallation_6MWmonopile ...
        + cost.portStaging_6MWmonopile) * 1.2 / 10;
    CAPEX = (cost.WindTurbine + cost.foundation + cost.secondarySteelFixed + cost.installation) * nWindTurbine ...
        + cost.offshoreSubstationFixed + cost.onshoreSubstation + cost.cableFixed;
    CAPEXnoCable = CAPEX -  cost.cableFixed;
    CAPEX = CAPEX * 1.2; CAPEXnoCable = CAPEXnoCable * 1.2;
elseif OWFtype == 2 % jacket
%     cost.installation = 2* cost.substructureInstallation_10MWjacket -cost.substructureInstallation_6MWjacket ...
%         + 2* cost.turbineInstallation_10MWjacket -cost.turbineInstallation_6MWjacket ...
%         + 2* cost.portStaging_10MWjacket -cost.portStaging_6MWjacket;
    cost.foundation = cost.jacketFoundation;
    cost.installation = (cost.substructureInstallation_6MWjacket + cost.turbineInstallation_6MWjacket ...
        + cost.portStaging_6MWjacket) * 1.2/ 10;
    CAPEX = (cost.WindTurbine + cost.foundation + cost.secondarySteelFixed + cost.installation) * nWindTurbine ...
        + cost.offshoreSubstationFixed + cost.onshoreSubstation + cost.cableFixed;
    CAPEXnoCable = CAPEX -  cost.cableFixed; 
    CAPEX = CAPEX * 0.75; CAPEXnoCable = CAPEXnoCable * 0.75;

elseif OWFtype == 3 % semisubmersible
%     cost.installation = 2* cost.substructureInstallation_10MWsemisubmersible -cost.substructureInstallation_6MWsemisubmersible ...
%         + 2* cost.turbineInstallation_10MWsemisubmersible -cost.turbineInstallation_6MWsemisubmersible ...
%         + 2* cost.portStaging_10MWsemisubmersible -cost.portStaging_6MWsemisubmersible;
    cost.foundation = cost.semisubmersible;
    cost.installation = (cost.substructureInstallation_6MWsemisubmersible + cost.turbineInstallation_6MWsemisubmersible ...
        + cost.portStaging_6MWsemisubmersible) * 1.2/ 10;
    CAPEX = (cost.WindTurbine + cost.foundation + cost.secondarySteelFloating + cost.installation) * nWindTurbine ...
        + cost.offshoreSubstationFloating + cost.onshoreSubstation + cost.cableFloating;
    CAPEXnoCable = CAPEX -  cost.cableFloating; 
    CAPEX = CAPEX * 1.5; CAPEXnoCable = CAPEXnoCable * 1.5;
end

%% OPEX
% OPEX = CAPEX / 0.664 * 0.282;\
if OWFtype == 1 || OWFtype == 2 % monopile or jacket
    % 单位是km，Million $
    OPEXperyear = (2.5522*log(distanceToPort) + 90.899) * 1e6;
else
    OPEXperyear = (4.0739*log(distanceToPort) + 76.993) * 1e6;
end
OPEX = sum(OPEXperyear ./ (1+discountRate).^[0:lifetime-1]);
%% DECEX
% DECEX = CAPEX / 0.664 * 0.018;
% 认为是安装成本的一定倍数
DECEX = 0.0938 * cost.installation * nWindTurbine / (1+discountRate).^(lifetime-1);
%% LCOE
cost.DEVEX = DEVEX;
cost.CAPEX = CAPEX;
cost.OPEX = OPEX;
cost.DECEX = DECEX;
cost.CAPEXnoCable = CAPEXnoCable;
cost.totalCost = DEVEX + CAPEX + OPEX + DECEX;
electricity = lifetime * 365*24 * OWFcapacity * capacityFactor * loadFactor; % MWh
LCOEdollar = cost.totalCost / electricity;
LCOE = LCOEdollar * u2e;

cost.totalCostNoCable = (DEVEX + CAPEXnoCable + OPEX + DECEX)* u2e  ;
end
