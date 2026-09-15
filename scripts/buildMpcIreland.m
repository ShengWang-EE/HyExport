clear
clc
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
projectRoot = setupHyExport(projectRoot);
checkpointDir = fullfile(projectRoot, 'results', 'checkpoints');
fileName = projectFile('data','tables','All Island Ten Year Transmission Statement-2021.xlsx');

mpc.baseMVA = 100;

busName = readtable(fileName,'Sheet','bus name','range','A2:D371');
transmissionSystem = readtable(fileName,'Sheet','transmission system','range','A4:K694');
demand_winterPeak = readtable(fileName,'Sheet','demand','range','A4:M168');
demand_summerPeak = readtable(fileName,'Sheet','demand','range','O4:AA167');
demand_summerValley = readtable(fileName,'Sheet','demand','range','AC4:AO167');
generation_transmissionConnected = readtable(fileName,'Sheet','generation','range','A4:H161');
generation_distributionWind = readtable(fileName,'Sheet','generation','range','K4:U105');
generation_distributionNonWind = readtable(fileName,'Sheet','generation','range','X4:AI116');
generation_table = readtable(fileName,'Sheet','generator','range','B6:AL161');
%% bus
mpc.busName = busName;

% bus
nb = size(busName,1);
bus = zeros(nb,13);
bus(:,1) = 1:nb;
bus(:,2) = 1;
bus(1,2) = 3;

nd = size(demand_winterPeak,1);
demand = demand_winterPeak;
for i = 1:nd
    name = convertCharsToStrings(table2cell(demand_winterPeak(i,1)));
    busIndex = find(busName.Var1 == name);
    bus(busIndex,3) = demand.Var6(i); % active power, MW
    powerFactor = demand.Var3(i);
    bus(busIndex,4) = bus(busIndex,3) / powerFactor * sqrt(1-powerFactor^2); % reactive power
end

bus(:,[5,6,9]) = 0; % Gs Bs Va
bus(:,[7,8,11]) = 1; % ESystemID, Vm, zone

% voltage level
for i = 1:nb
    name = convertCharsToStrings(table2cell(busName(i,1)));
    lineIndex = min([find(transmissionSystem.Var2==name);find(transmissionSystem.Var3 == name)]);
    if isempty(lineIndex)
        bus(i,10) = 110;
    else
        bus(i,10) = transmissionSystem.Var1(lineIndex);
    end
end

bus(:,12) = 1.05;
bus(:,13) = 0.95;

mpc.bus = bus;
%% branch
nl = size(transmissionSystem,1);
counter = 1;
counter1 = 1;
for i = 1:nl
    fbName = convertCharsToStrings(table2cell(transmissionSystem(i,2)));
    tbName = convertCharsToStrings(table2cell(transmissionSystem(i,3)));
    fb = min(find(contains(busName.Var1,fbName))); 
    tb = min(find(contains(busName.Var1,tbName)));
    if isempty(fb)
        fb = 0;
        busNameNan{counter1} = fbName;
        counter1 = counter1 + 1;
    elseif isempty(tb)
        tb = 0;
        busNameNan{counter1} = tbName;
        counter1 = counter1 + 1;
    else
        branch(counter,1:2) = [fb,tb];
        RXB = [transmissionSystem.Var6(i),transmissionSystem.Var7(i),transmissionSystem.Var8(i)];
        RXB(RXB==0) = 1e-2;
        branch(counter,[3,4,5]) = RXB;
        branch(counter,[6,7,8]) = [transmissionSystem.Var9(i),transmissionSystem.Var10(i),transmissionSystem.Var11(i)];
        branch(counter,[9,10,11,12,13]) = [0    0	1	-360	360];
        counter = counter + 1;
    end
end
mpc.branch = branch;
%% gen (only counter DSO level?)
ng = size(generation_table,1);
for i = 1:ng
    name = convertCharsToStrings(table2cell(generation_table(i,6)));
    busIndex = find(busName.Var2 == name); 
    if isempty(busIndex)
        gen(i,1) = 0;
    else
        gen(i,1) = busIndex;
    end
    gen(i,[2,4,9]) = generation_table.MaxCapacity_MW_(i);
    gen(i,3) = generation_table.MinStableCapacity_MW_(i);
    gen(i,5) = -generation_table.MaxCapacity_MW_(i);
    gen(i,6) = 1;
    gen(i,7) = 100;
    gen(i,8) = 1;
    gen(i,10) = generation_table.MinStableCapacity_MW_(i);
    gen(i,11:21) = 0;
    gen(i,17) = generation_table.RampRateUp_MW_min(i);

    genType(i,1) = generation_table.FuelForGenerationAndNoLoad(i);
end
genType = convertCharsToStrings(genType);
deleteLine = (gen(:,1) == 0);
gen(deleteLine,:) = []; 
genType(deleteLine,:) = [];

mpc.gen = gen;
mpc.genType = genType;
%% gencost
fuelCost.coal = 2.318468; % ROI Coal, €/GJ
fuelCost.gas = 3.707716; % ROI Gas, €/GJ
fuelCost.distillate = 13.144915; 
fuelCost.oil = 9.206651;
fuelCost.peat = 0;
emissionFactor.coal = 0.09365; % tCO2/GJ
emissionFactor.gas = 0.05582;
emissionFactor.gasoil = 0.07373;
emissionFactor.LSFO = 0.07701;
emissionFactor.peat = 0.11670;

gencost = zeros(ng,7);
gencost(:,1) = 2;
genCarbon = zeros(ng,7);
genCarbon(:,1) = 2;

for i = 1:ng
% for i = 5
    startup = generation_table.StartUpEnergy_GJ_Cold(i);
    startup(isnan(startup)) = 0;
    gencost(i,3) = 0;
    gencost(i,4) = 3; % 二次函数
    genCarbon(i,3) = 0;
    genCarbon(i,4) = 3; % 二次函数

    capacityPoint = table2array(generation_table(i,17:21))';
    heatRate = table2array(generation_table(i,22:26))';        
    capacityPoint(isnan(capacityPoint)) = [];
    heatRate(isnan(heatRate)) = [];
    nPoints = size(capacityPoint,1);
    curvePoint = zeros(nPoints+1,2);
    curvePoint(2:nPoints+1,1) = capacityPoint;
    yPoint = 0;
    for j = 1:nPoints
        xPoint = capacityPoint(j);
        yPoint = yPoint + (curvePoint(j+1,1) - curvePoint(j,1)) * heatRate(j);
        curvePoint(j+1,:) = [xPoint,yPoint];
    end
    if genType(i) == 'Wind' || genType(i) == 'Solar' || genType(i) == 'Water' ...
            || genType(i) == 'Waste' || genType(i) == 'Peat'
        gencost(i,5:7) = 0;
    else
        if genType(i) == 'Coal'
            curvePoint(:,2) = curvePoint(:,2) * fuelCost.coal;
            gencost(i,2) = startup * fuelCost.coal;
        elseif genType(i) == 'Gas'
            curvePoint(:,2) = curvePoint(:,2) * fuelCost.gas;
            gencost(i,2) = startup * fuelCost.gas;
        elseif genType(i) == 'Gasoil'
            curvePoint(:,2) = curvePoint(:,2) * fuelCost.distillate;
            gencost(i,2) = startup * fuelCost.distillate;
        elseif genType(i) == 'Oil'
            curvePoint(:,2) = curvePoint(:,2) * fuelCost.oil;
            gencost(i,2) = startup * fuelCost.oil;
        end
        if nPoints == 1
            coefficients = polyfit(curvePoint(:,1),curvePoint(:,2),1);
            gencost(i,6:7) = coefficients;
        else 
            coefficients = polyfit(curvePoint(:,1),curvePoint(:,2),2);
            gencost(i,5:7) = coefficients;
        end
    end
    % carbon
    if genType(i) == 'Wind' || genType(i) == 'Solar' || genType(i) == 'Water' ...
           || genType(i)  == 'Waste'
        genCarbon(i,5:7) = 0;
    else
        if genType(i) == 'Coal'
            curvePoint(:,2) = curvePoint(:,2) * emissionFactor.coal;
            genCarbon(i,2) = startup * emissionFactor.coal;
        elseif genType(i) == 'Gas'
            curvePoint(:,2) = curvePoint(:,2) * emissionFactor.gas;
            genCarbon(i,2) = startup * emissionFactor.gas;
        elseif genType(i) == 'Gasoil'
            curvePoint(:,2) = curvePoint(:,2) * emissionFactor.gasoil;
            genCarbon(i,2) = startup * emissionFactor.gasoil;
        elseif genType(i) == 'Oil'
            curvePoint(:,2) = curvePoint(:,2) * emissionFactor.gasoil;
            genCarbon(i,2) = startup * emissionFactor.gasoil;
        elseif genType(i) == 'Peat'
            curvePoint(:,2) = curvePoint(:,2) * emissionFactor.peat;
            genCarbon(i,2) = startup * emissionFactor.peat;
        end
        if nPoints == 1
            coefficients = polyfit(curvePoint(:,1),curvePoint(:,2),1);
            genCarbon(i,6:7) = coefficients;
        else 
            coefficients = polyfit(curvePoint(:,1),curvePoint(:,2),2);
            genCarbon(i,5:7) = coefficients;
        end
    end
end

mpc.gencost = gencost;
mpc.genCarbon = genCarbon;

% mpopt = mpoption('opf.ac.solver', 'MIPS');
% runopf(mpc);
%%
GbusName = readtable(projectFile('data','tables','Irish energy system data.xlsx'),'sheet','Gbus','range','G1:I145');
mpc.GbusName = GbusName;

mpc.Gbus = table2array(readtable(projectFile('data','tables','Irish energy system data.xlsx'),'sheet','Gbus','range','A2:F145'));
mpc.Gline = table2array(readtable(projectFile('data','tables','Irish energy system data.xlsx'),'sheet','Gline','range','A2:I145'));
mpc.Gsou = table2array(readtable(projectFile('data','tables','Irish energy system data.xlsx'),'sheet','Gsou','range','A2:D3'));
mpc.Gcost = table2array(readtable(projectFile('data','tables','Irish energy system data.xlsx'),'sheet','Gcost','range','A2:A3'));
mpc.ptg = table2array(readtable(projectFile('data','tables','Irish energy system data.xlsx'),'sheet','ptg','range','A2:E8'));

%% GEcon
gppIndex = find(genType == "Gas");
nGPP = size(gppIndex,1);
GEcon = zeros(nGPP,4);
gppBusIndex = gen(gppIndex,1);
GEcon(:,2) = gppBusIndex;
GEcon(:,3) = gppIndex;
GEcon(:,4) = 0.9;
Ecoordinates = table2array(busName(gppBusIndex,3:4));
Gcoordinates = table2array(GbusName(:,2:3));
for i = 1:nGPP
    point1 = Ecoordinates(i,:);
    points2 = Gcoordinates;
    distancesEG = geoDistance(point1,points2);
    [minValue,minIndex] = min(distancesEG);
    GEcon(i,1) = minIndex;
end
mpc.GEcon = GEcon;
%% ptg (只保留陆地上的，海上的在分析时再生成）
mpc.ptg = mpc.ptg(1,:);
%% electricity demand
% electricityDemandCurve_48 = table2array(readtable('UK electricity demand from National Grid.csv', ...
%     'range','D2:D17521'));
% for i = 1:365*24
%     electricityDemandCurve_24(i) = electricityDemandCurve_48(2*(i-1)+1);
% end
% mpc.electricityDemandCuve = (electricityDemandCurve_24 / max(electricityDemandCurve_24) * sum(bus(:,3)))';
irelandPowerSystemOperation = readtable(projectFile('data','tables','System-Data-Qtr-Hourly-2023.xlsx'));

electricityDemandCurve_24 = irelandPowerSystemOperation.AIDemand;
electricityDemandCurve_24 = electricityDemandCurve_24(1:4:4*8759+1);
mpc.electricityDemandCuve = electricityDemandCurve_24;


dateTime_raw = convertCharsToStrings(table2cell(readtable(projectFile('data','tables','Ireland gasconsumption 2023 merged.xlsx'), ...
    'sheet','merged','range','C1:C8735')));
for i = 1:size(dateTime_raw,1)
    dateTime_object{i} = datetime(dateTime_raw{i});
    monthValue(i) = month(dateTime_object{i});
    dayValue(i) = day(dateTime_object{i});
    hourValue(i) = hour(dateTime_object{i});
end
gasDemandCurve_NDM = table2array(readtable(projectFile('data','tables','Ireland gasconsumption 2023 merged.xlsx'), ...
    'sheet','merged','range','D1:D8735'));
gasDemandCurve_LDM = table2array(readtable(projectFile('data','tables','Ireland gasconsumption 2023 merged.xlsx'), ...
    'sheet','merged','range','J1:J8735'));
gasDemandCurve_power = table2array(readtable(projectFile('data','tables','Ireland gasconsumption 2023 merged.xlsx'), ...
    'sheet','merged','range','P1:P8735'));
gasDemandTotal_raw = gasDemandCurve_NDM + gasDemandCurve_LDM + gasDemandCurve_power;
gasDemandTotal = zeros(8760,1);


for i = 1:size(gasDemandTotal_raw,1)
    differenceInHour = hours(dateTime_object{i} - dateTime_object{1}) + 1;
    gasDemandTotal(differenceInHour) = gasDemandTotal_raw(i);
end
while min(gasDemandTotal) == 0
    for i = 1:8760
        if gasDemandTotal(i) == 0
            gasDemandTotal(i) = gasDemandTotal(i-1);
        end
    end
end
gasDemandPowerProportion = gasDemandCurve_power ./ gasDemandTotal_raw;
gasHeatValue = 39.33; % MJ/m3
mpc.gasDemandCurve = gasDemandTotal /1e3 / gasHeatValue/1e6*24*3600 / 24;
mpc.gasDemandPowerProportion = gasDemandPowerProportion;
%% 检查电力系统孤岛
am = zeros(size(mpc.bus,1),size(mpc.bus,1));
for i = 1:size(mpc.branch,1)
    fb = mpc.branch(i,1);
    tb = mpc.branch(i,2);
    am(fb,tb) = 1; am(tb,fb) = 1;
end
G = graph(am);
[components, numComponents] = conncomp(G);

busCoordinates = table2array(busName(:,3:4));
% 添加最近的线路

if size(numComponents,2) > 1 % is island
    mainBusIndex = find(components == 1);
    nMainBus = size(mainBusIndex,2);
    islandBusIndex = find(components ~= 1);
    for i = 1:size(islandBusIndex,2)
        distanceToMain = geoDistance(repmat(busCoordinates(islandBusIndex(i),:),[nMainBus,1]),busCoordinates(mainBusIndex,:));
        [~,minBusIndex] = min(distanceToMain);
        addBranch = [islandBusIndex(i),mainBusIndex(minBusIndex),1e-5,1e-5,1e-5,999,999,999,0,	0,	1,	-360,	360];
        mpc.branch = [mpc.branch;addBranch];
    end
end

%%
save(fullfile(checkpointDir,'mpcIreland.mat'),'mpc')

% test run for a single time point
[solution, solution_info] = runopf_hge_simple(mpc);
%% future gas demand data
% 1 best estimate
futureGasDemand = readtable(projectFile('data','tables','Irish energy system data.xlsx'),'sheet','future gas','range','L1:S11');
futureGasDemand_total = table2array(futureGasDemand(:,8));
futureGasDemand_sector = table2array(futureGasDemand(:,1:8));

for i = 1:8
    sys = ar(futureGasDemand_sector(:,i),4);
    newData{i} = forecast(sys,futureGasDemand_sector(:,i),20);
    dataTogather(:,i) = [futureGasDemand_sector(:,i);newData{i}];
end

% 2 low demand
futureGasDemand = readtable(projectFile('data','tables','Irish energy system data.xlsx'),'sheet','future gas','range','L15:S24');
futureGasDemand_total = table2array(futureGasDemand(:,8));
futureGasDemand_sector = table2array(futureGasDemand(:,1:8));

for i = 1:8
    sys = ar(futureGasDemand_sector(:,i),4);
    newData{i} = forecast(sys,futureGasDemand_sector(:,i),20);
    dataTogather(:,i) = [futureGasDemand_sector(:,i);newData{i}];
end

% 3 high demand
futureGasDemand = readtable(projectFile('data','tables','Irish energy system data.xlsx'),'sheet','future gas','range','L27:S36');
futureGasDemand_total = table2array(futureGasDemand(:,8));
futureGasDemand_sector = table2array(futureGasDemand(:,1:8));

for i = 1:8
    sys = ar(futureGasDemand_sector(:,i),4);
    newData{i} = forecast(sys,futureGasDemand_sector(:,i),20);
    dataTogather(:,i) = [futureGasDemand_sector(:,i);newData{i}];
end
