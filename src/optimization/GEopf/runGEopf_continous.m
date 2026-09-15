function [solution, solution_info] = runGEopf_continous(mpc,onshoreWindCapacity,solarCapacity,hydroCapacity, ...
    interconnectorCapacity,offshoreWindAvaliableCapacityCoeff,electricityDemandCurve,gasDemandCurve,gasDemandPowerProportion,NK,options)
%% paras
hymax = options.hymax;

[PQ, PV, REF, NONE, BUS_I, BUS_TYPE, PD, QD, GS, BS, BUS_AREA, VM, ...
    VA, BASE_KV, ZONE, VMAX, VMIN, LAM_P, LAM_Q, MU_VMAX, MU_VMIN] = idx_bus;
[GEN_BUS, PG, QG, QMAX, QMIN, VG, MBASE, GEN_STATUS, PMAX, PMIN, ...
    MU_PMAX, MU_PMIN, MU_QMAX, MU_QMIN, PC1, PC2, QC1MIN, QC1MAX, ...
    QC2MIN, QC2MAX, RAMP_AGC, RAMP_10, RAMP_30, RAMP_Q, APF] = idx_gen;
[F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, RATE_C, ...
    TAP, SHIFT, BR_STATUS, PF, QF, PT, QT, MU_SF, MU_ST, ...
    ANGMIN, ANGMAX, MU_ANGMIN, MU_ANGMAX] = idx_brch;
[PW_LINEAR, POLYNOMIAL, MODEL, STARTUP, SHUTDOWN, NCOST, COST] = idx_cost;
baseMVA = 100;
il = find(mpc.branch(:, RATE_A) ~= 0 & mpc.branch(:, RATE_A) < 1e10);
%
nb   = size(mpc.bus, 1);    %% number of buses
refBus = find(mpc.bus(:,BUS_TYPE) == REF,1,'first');
nGb  = size(mpc.Gbus,1); % number of gas bus
nGl = size(mpc.Gline,1);
ng = size(mpc.gen,1);
nl = size(mpc.branch,1);
nGpp = size(mpc.GEcon,1);
nGs = size(mpc.Gsou,1);
nGd = size(find(mpc.Gbus(:,3)~=0),1);
nPTG = size(mpc.ptg,1);
nIC = size(mpc.interconnectorBus,1); % num of interconnector
iGd = find(mpc.Gbus(:,3)~=0);
iOnshoreWind = find(mpc.genType == 'Wind');
iHydro = find(mpc.genType == 'Water');
iSolar = find(mpc.genType == 'Solar');
iCoal = find(mpc.genType == 'Coal');
iGasoil = find(mpc.genType == 'Gasoil');
iWaste = find(mpc.genType == 'Waste');
iOil = find(mpc.genType == 'Oil');
iOffshoreWind = find(mpc.genType == 'Offshore');
nOffshoreWind = size(iOffshoreWind,1);
iNonRenewable = find(mpc.genType ~= 'Wind' & mpc.genType ~= 'Solar' & mpc.genType ~= 'Offshore');
iOnOffGen = [find(mpc.genType == 'Coal'); find(mpc.genType == 'Gas')];

iNonOnOffGen = setdiff(1:ng,iOnOffGen);
nOnOffGen = size(iOnOffGen,1);
mpc.gasCompositionForGasSource = repmat([1,0],[nGs,1]);
% natural gas, hydrogen
nGasType = 2;
[GCV, M, fs, a, R, T_stp, Prs_stp, Z_ref, T_gas, eta, CDF,rho_stp] = initializeParameters_J13(options.year);

%% state vars
Prs = sdpvar(NK,nGb); % bar^2
PGs = sdpvar(NK,nGs); % Mm3/day
Qd = sdpvar(NK,nGd,nGasType);% Mm3/day
Qptg = sdpvar(NK,nPTG,nGasType); % [ methane; hydrogen ] % Mm3/day
Pptg = sdpvar(NK,nPTG); % electricity consumption, 1/100 MW
Pg = sdpvar(NK,ng); % include TPP, GPP and renewable generators, 1/100 MW
Qgpp = sdpvar(NK,nGpp, nGasType); % Mm3/day
Va = sdpvar(NK,nb);
gasFlow = sdpvar(NK,nGl,nGasType);% Mm3/day
gamma = mpc.Gline(:,9);
% add unit commitment
I_status = binvar(NK,nOnOffGen);
I_up = binvar(NK,nOnOffGen);
I_down = binvar(NK,nOnOffGen);

% I_status = ones(NK,nOnOffGen);
% I_up = zeros(NK,nOnOffGen);
% I_down = zeros(NK,nOnOffGen);

Pic = sdpvar(NK,nIC);

Qd_export = sdpvar(NK,nPTG); % considering export

    
%% bounds
Prsmin = repmat(mpc.Gbus(:,5)',[NK,1]); Prsmax = repmat(mpc.Gbus(:,6)',[NK,1]); % bar
PGsmin = repmat(mpc.Gsou(:,3)',[NK,1]); PGsmax = repmat(mpc.Gsou(:,4)',[NK,1]); % Mm3/day
Qptgmin = repmat(mpc.ptg(:,4)',[NK,1]); Qptgmax = repmat(mpc.ptg(:,5)',[NK,1]);
QptgMax_hydrogen = Qptgmax;

Pgmin = zeros(NK,ng); Pgmax = zeros(NK,ng);
Pgmin(:,iNonRenewable) = repmat(mpc.gen(iNonRenewable,PMIN)',[NK,1]) / baseMVA; 
Pgmax(:,iNonRenewable) = repmat(mpc.gen(iNonRenewable, PMAX)',[NK,1]) / baseMVA;
Pgmax(:,iOnshoreWind) = onshoreWindCapacity/ baseMVA;
Pgmax(:,iOffshoreWind) = repmat(mpc.gen(iOffshoreWind, PMAX)',[NK,1]) / baseMVA;
Pgmax(:,iOffshoreWind) = Pgmax(:,iOffshoreWind) .* offshoreWindAvaliableCapacityCoeff(:,1:nOffshoreWind);
Pgmax(:,iSolar) = solarCapacity/ baseMVA;
Pgmax(:,iHydro) = repmat(mpc.gen(iHydro, PMAX)',[NK,1]) / baseMVA;
Pgmax(:,iHydro) = hydroCapacity/ baseMVA;
Picmax = max(interconnectorCapacity,0);
Picmin = min(interconnectorCapacity,0);

gasFlowMax = mpc.Gline(:,5);
upf = repmat((mpc.branch(il, RATE_A) / mpc.baseMVA)',[NK,1]);
if options.export == 0 
    Qd_exportmax = zeros(NK,nPTG);
else
    Qd_exportmax = ones(NK,nPTG) * 9999;
end
%% constraints
%
gasSourceCons = [ ...
    PGs >= PGsmin;
    PGs <= PGsmax;
    Qd_export <= Qd_exportmax;
    Qd_export >= 0;
    ];

%
GCVall = [GCV.ng,GCV.hy];
energyDemand = mpc.Gbus(iGd,3) * GCV.ng/1e9; % energy need of these gas bus
energyDemandMultiPeriods = (energyDemand * (gasDemandCurve./max(gasDemandCurve))')'.* repmat(gasDemandPowerProportion,[1,nGd]);
gasDemandCons = [
    sum(Qd .* repmat(permute(GCVall/1e9,[3,1,2]),[NK,nGd,1]),3) == energyDemandMultiPeriods;
    Qd >= 0;
    ]:'gasDemandCons';

%
nodalGasFlowBalanceCons = [     
    consfcn_nodalGasFlowBalance_hge_multiPeriod(PGs,Qd,Qgpp,Qptg, gasFlow,Qd_export,mpc,nGasType,nGpp,nGd,iGd,NK) == 0;
    ]:'nodalGasFlowBalanceCons';

%
% eta.methanation  = 0; % 取消甲烷化功能
PTGcons = [
    ( Qptg(:,:,1) * 1e6/24/3600 *GCV.ng / eta.methanation + Qptg(:,:,2) * 1e6/24/3600 * GCV.hy ...
        ) /1e6 == Pptg * baseMVA * eta.electrolysis; % hydrogen-equivalent MW
    Pptg * baseMVA >= 0;
    Pptg * baseMVA <= QptgMax_hydrogen /24/3600 * GCV.hy / eta.electrolysis; % 如果全用来制氢，
    0 <= Qptg;
    Qptg(:,:,1) == 0;% 取消甲烷化功能
    ];

% gpp
Pgpp = Pg(:,mpc.GEcon(:,3));% 100 MW
GPPcons = [
    Pgpp * baseMVA == sum(Qgpp*(1/24/3600) .* repmat(permute(GCVall,[3,1,2]),[NK,nGpp,1]),3)*eta.GFU;
    Qgpp >= 0;
    ]:'GPPcons';

%
[B, Bf, Pbusinj, Pfinj] = makeBdc(mpc.baseMVA, mpc.bus, mpc.branch);
rampUnitIndex = find(mpc.gen(:,17) ~= 0);
rampRate = repmat(mpc.gen(:,17)',[NK,1]) * 60 / 100; % 100 MW/hour
rampDelta = Pg([2:end,1],iOnOffGen) - Pg(:,iOnOffGen);
rampDeltaMin = - (1-I_up - I_down) .* rampRate(:,iOnOffGen) + (I_up+I_down) .* (-999);
rampDeltaMax = (1-I_up - I_down) .* rampRate(:,iOnOffGen) + (I_up+I_down) .* (999);


electricityCons = [
    (Bf(il,:)*Va')' >= -upf;
    (Bf(il,:)*Va')' <= upf;
    Pg(:,iNonOnOffGen) >= Pgmin(:,iNonOnOffGen);
    Pg(:,iNonOnOffGen) <= Pgmax(:,iNonOnOffGen);
    Pg(:,iOnOffGen) >= I_status .* Pgmin(:,iOnOffGen);
    Pg(:,iOnOffGen) <= I_status .* Pgmax(:,iOnOffGen);
    rampDelta >= rampDeltaMin;
    rampDelta <= rampDeltaMax;
    ]:'electricityCons';

%
Cgs_Pic = sparse(mpc.interconnectorBus, (1:nIC)', 1, nb, nIC); % connection matrix
Pic_inbus = Cgs_Pic * Pic';
electricityBalanceCons = [...
    consfcn_electricPowerBalance_hge_multiPeriod(Va,Pg,Pptg,mpc,electricityDemandCurve,interconnectorCapacity,Pic_inbus) == 0;
    Va(:,refBus) == 0;
    I_status([2:end,1],:) - I_status == I_up - I_down;
    I_up + I_down <= 1; % 同一时间只能启动，或者关闭
    ]:'electricityBalanceCons';
%
windReserve = (sum(Pg(:,iOnshoreWind),2) + sum(Pg(:,iOffshoreWind),2)) * 0.001;
stabilityCons = [
        sum(I_status,2) >= 5; % must on cons
        sum(Pgmax(:,iNonRenewable),2) - sum(Pg(:,iNonRenewable),2) >= 125/baseMVA + 3.5*max([max(max(Pgmax)),500/baseMVA]) + windReserve; % 500 is the interconnector
        (sum(I_status .* Pgmax(:,iOnOffGen),2) +  sum(Pgmax(:,iHydro),2) + sum(Pgmax(:,iOil),2) + sum(Pgmax(:,iGasoil),2) + sum(Pgmax(:,iWaste),2)) ...
            * baseMVA / 1e3 * 4 >= 20; % GWs, 惯量,H=4s
        ];
% 
gasSecurityCons = [
        % gasFlow(:,:,2) <= repmat(gamma',[NK,1]) .* hymax .* sum(gasFlow,3);
        sum(Qptg(:,:,2),2) - sum(Qd_export,2) <= hymax * (sum(Qptg(:,:,2),2) + sum(Qptg(:,:,1),2) + sum(PGs,2) - sum(Qd_export,2) );
    ]:'gasSecurityCons';

%
% C = mpc.Gline(:,3);
% FB = mpc.Gline(:,1); TB = mpc.Gline(:,2);
% gasFlow_sum = sum(gasFlow,3);
% PHI = repmat(gamma',[NK,1]) .* (Prs(:,FB).^2-Prs(:,TB).^2);
% gasFlowCons = [
%     Prsmin <= Prs <= Prsmax;
%     PHI >= gasFlow_sum.^2 ./ repmat(C',[NK,1]).^2;
%     ];

constraints = [
    gasSourceCons;
    gasDemandCons;
    nodalGasFlowBalanceCons;
    gasSecurityCons;
%     gasFlowCons;
    PTGcons;
    GPPcons;
    electricityCons;
    electricityBalanceCons;
    stabilityCons;
    % 0 <= Pg <= 9999;
    Pic >= Picmin;
    Pic <= Picmax;
    ];
%% solve
objfcn = obj_operatingCost_schedule(Pg,Pic,PGs,Qptg,Qd_export,windReserve,I_up,I_down,mpc,NK,iOnOffGen,iCoal);
options = sdpsettings('verbose',2,'solver','gurobi', 'debug',1);
options.gurobi.MIPGap = 5e-2;
options.mosek.MSK_DPAR_MIO_TOL_REL_GAP = 1e-2;
options.gurobi.TuneTimeLimit = 0;
solution_info = optimize(constraints, objfcn, options);
%% results
Prs = value(Prs);
PGs = value(PGs); % Mm3/day
Qd = value(Qd); % Mm3/day
Qptg = value(Qptg);
Pptg = value(Pptg); % MW
Pg = value(Pg);  % MW
Pgpp = value(Pgpp);  % MW
Qgpp = value(Qgpp);  % Mm3/day
Va = value(Va);
gamma = value(gamma);
gasFlow = value(gasFlow);
% gasFlow_sum = sum(value(gasFlow_sum),2);
[totalCost,electricityGenerationCost,gasPurchasingCost,upDownCost,exportProfit,reserveCost] = ...
    obj_operatingCost_schedule(Pg,Pic,PGs,Qptg,Qd_export,windReserve,I_up,I_down,mpc,NK,iOnOffGen,iCoal);
I_status = value(I_status);
I_up = value(I_up);
I_down = value(I_down);
Pic = value(Pic);
Qd_export = value(Qd_export);

solution.Prs = Prs;
solution.PGs = PGs;
solution.Qd = Qd;
solution.Qptg = Qptg;
solution.Pptg = Pptg;
solution.Pg = Pg;
solution.Pgpp = Pgpp;
solution.Qgpp = Qgpp;
solution.Va = Va;
solution.gasFlow = gasFlow;
% solution.gasFlow_sum = gasFlow_sum;
solution.totalCost = totalCost;
solution.I_status = I_status;
solution.I_up = I_up;
solution.I_down = I_down;
solution.Pic = Pic;
solution.Qd_export = Qd_export;

solution.electricityGenerationCost = electricityGenerationCost;
solution.gasPurchasingCost = gasPurchasingCost;
solution.onshoreWindCurtailment = Pgmax(:,iOnshoreWind) - Pg(:,iOnshoreWind);
solution.offshoreWindCurtailment = Pgmax(:,iOffshoreWind) - Pg(:,iOffshoreWind);

solution.energyDemandMultiPeriods = energyDemandMultiPeriods;
solution.gasEnergyConsumption = Pgpp / eta.GFU;
%% observation
powerLineUtilization = abs((Bf(il,:)*Va')')./upf; %陆地上的弃风不太受网架影响
rampRateUtilization = abs(Pg([2:end,1],rampUnitIndex) - Pg(:,rampUnitIndex)) ./ rampRate(:,rampUnitIndex);
windOnshoreCurtailRate = (Pgmax(:,iOnshoreWind) - Pg(:,iOnshoreWind)) ./ Pgmax(:,iOnshoreWind);
sumOnshoreWindCurtailRate = sum(Pgmax(:,iOnshoreWind) - Pg(:,iOnshoreWind),2) ./ sum(Pgmax(:,iOnshoreWind),2);
sumOffshoreWindCurtailRate = sum(Pgmax(:,iOffshoreWind) - Pg(:,iOffshoreWind),2) ./ sum(Pgmax(:,iOffshoreWind),2);
% windCapacity = sum(mpc.gen(iOnshoreWind,PMAX));
end
