function [X,P_bt, P_cp, P_el, P_wpd, massWater, q_hy, q_hy_inSCF] = electrolyzerSizing(OWFcapacity)
eta.electrolysor = 0.65;
eta.waterPumpDesal = 1;
highPressure = 80 * 1e6; % psia
lowPressure = 10 * 1e6;
eta.compressor = 0.9;
R_gas = 8.314; % J/ (mol*K)
gasTemperature = 520; % 
specifcHeatRatioHydrogen = 1.405;
B = R_gas * gasTemperature / eta.compressor * (specifcHeatRatioHydrogen/(specifcHeatRatioHydrogen-1));
p_stp = 101325; % psia
T_stp = 273.15; % K
M_water = 18;
heightPlatform = 50; %m
heatValueHydrogen = 12.75 * 1e6;      % J/m3
hoursePowerToWatt = 745.7; %1 hp=745.7watts
eta.battery = 0.95;
batteryUtilizationRate = 0.1;
Z_hy = 1;
%%
syms q_hy q_hy_inSCF massWater P_el P_wpd  P_cp P_bt
equations = [
    q_hy_inSCF == q_hy / 0.02831685 * 3600;
    massWater == q_hy * p_stp / R_gas / T_stp * M_water; % kg
    P_el * eta.electrolysor == q_hy * heatValueHydrogen; % W
    P_wpd == (eta.waterPumpDesal+1) * heightPlatform * massWater; % W
    P_cp == 0.3 * B * q_hy * ((highPressure/lowPressure) ...
        ^(Z_hy * (specifcHeatRatioHydrogen-1)/specifcHeatRatioHydrogen)-1) * hoursePowerToWatt; %W
    P_bt == (1-eta.battery) * batteryUtilizationRate * (P_el + P_wpd + P_cp); % w
    (P_el + P_wpd + P_cp + P_bt) * 1e-6 == OWFcapacity; % MW
    ];
[A,b] = equationsToMatrix(equations);
vars = symvar(equations);
X = double(linsolve(A,b));
[P_bt, P_cp, P_el, P_wpd, massWater, q_hy, q_hy_inSCF] = deal(X(1),X(2),X(3),X(4),X(5),X(6),X(7));
end
