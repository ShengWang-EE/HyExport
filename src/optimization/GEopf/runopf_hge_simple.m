function [solution, solution_info] = runopf_hge_simple(mpc,year)
if nargin < 2
    year = 2030;
end
%% paras
hymax = 1;
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
iGd = find(mpc.Gbus(:,3)~=0);
mpc.gasCompositionForGasSource = repmat([1,0],[nGs,1]);
% natural gas, hydrogen
nGasType = 2;
[GCV, M, fs, a, R, T_stp, Prs_stp, Z_ref, T_gas, eta, CDF,rho_stp] = initializeParameters_J13(year);

%% state vars
Prs = sdpvar(nGb,1); % bar^2
PGs = sdpvar(nGs,1); % Mm3/day
Qd = sdpvar(nGd,nGasType);% Mm3/day
Qptg = sdpvar(nPTG,2); % [ methane; hydrogen ] % Mm3/day
Pptg = sdpvar(nPTG,1); % electricity consumption, 1/100 MW
Pg = sdpvar(ng,1); % include TPP, GPP and renewable generators, 1/100 MW
Qgpp = sdpvar(nGpp, nGasType); % Mm3/day
Va = sdpvar(nb,1);
gasFlow = sdpvar(nGl,nGasType);% Mm3/day
gamma = mpc.Gline(:,9);
%% bounds
Prsmin = mpc.Gbus(:,5); Prsmax = mpc.Gbus(:,6); % bar
PGsmin = mpc.Gsou(:,3); PGsmax = mpc.Gsou(:,4); % Mm3/day
Qptgmin = mpc.ptg(:,4); Qptgmax = mpc.ptg(:,5);
QptgMax_hydrogen = Qptgmax;
Pgmin = mpc.gen(:, PMIN) / baseMVA *0; %Pgmin is set to zero
Pgmax = mpc.gen(:, PMAX) / baseMVA;
gasFlowMax = mpc.Gline(:,5);
%% constraints
%
gasSourceCons = [ ...
    PGs >= PGsmin;
    PGs <= PGsmax;
    ];

%
GCVall = [GCV.ng,GCV.hy];
energyDemand = mpc.Gbus(iGd,3) * GCV.ng; % energy need of these gas bus
gasDemandCons = [
    Qd * GCVall'/1e9 == energyDemand/1e9;
    Qd >= 0;
    ]:'gasDemandCons';

%
nodalGasFlowBalanceCons = [
    consfcn_nodalGasFlowBalance_hge(PGs,Qd,Qgpp,Qptg, gasFlow,mpc,nGasType,nGpp,nGd,iGd) == 0;
    ]:'nodalGasFlowBalanceCons';

%
PTGcons = [
    ( Qptg(:,1) * 1e6/24/3600 *GCV.CH4 / eta.methanation + Qptg(:,2) * 1e6/24/3600 * GCV.hy ...
        ) /1e6 == Pptg * baseMVA * eta.electrolysis; % hydrogen-equivalent MW
    Pptg * baseMVA >= 0;
    Pptg * baseMVA <= QptgMax_hydrogen /24/3600 * GCV.hy / eta.electrolysis; % 如果全用来制氢，
    0 <= Qptg;
    ];

% gpp
Pgpp = Pg(mpc.GEcon(:,3));% 100 MW
GPPcons = [
    Pgpp * baseMVA == Qgpp/24/3600 * GCVall'*eta.GFU; % Mm3对应MW
    Qgpp >= 0;
    ]:'GPPcons';

%
[B, Bf, Pbusinj, Pfinj] = makeBdc(mpc.baseMVA, mpc.bus, mpc.branch);
upf = mpc.branch(il, RATE_A) / mpc.baseMVA;
electricityCons = [
    Bf(il,:)*Va >= -upf;
    Bf(il,:)*Va <= upf;
    Pg >= Pgmin;
    Pg <= Pgmax;
    ]:'electricityCons';

%
electricityBalanceCons = [...
    consfcn_electricPowerBalance_hge(Va,Pg,Pptg,mpc) == 0;
    Va(refBus) == 0;
    ]:'electricityBalanceCons';

% 
gasSecurityCons = [
        gasFlow(:,2) <= gamma .* hymax .* sum(gasFlow,2);
    ]:'gasSecurityCons';

%
C = mpc.Gline(:,3);
FB = mpc.Gline(:,1); TB = mpc.Gline(:,2);
gasFlow_sum = sum(gasFlow,2);
PHI = gamma .* (Prs(FB).^2-Prs(TB).^2);
gasFlowCons = [
    Prs >= Prsmin;
    Prs <= Prsmax;
    PHI == gasFlow_sum.^2 ./ C.^2 ;
    ]:'gasFlowSOCcons';

constraints = [
    gasSourceCons;
    gasDemandCons;
    nodalGasFlowBalanceCons;
    PTGcons;
    GPPcons;
    electricityCons;
    electricityBalanceCons;
    gasSecurityCons;
    gasFlowCons;
    ];
%% solve
objfcn = obj_operatingCost(Pg,PGs,Qptg, mpc);
options = sdpsettings('verbose',2,'solver','gurobi', 'debug',1);
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
gasFlow_sum = sum(value(gasFlow_sum),2);
objfcn = value(objfcn);

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
solution.gasFlow_sum = gasFlow_sum;
solution.objfcn = objfcn;
end
