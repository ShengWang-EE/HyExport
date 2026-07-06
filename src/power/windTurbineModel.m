function [electricityGeneration,windTurbine] = windTurbineModel(inputWindSpeed,modelType)
%WINDTURBINEMODELDATA Summary of this function goes here
%   Detailed explanation goes here
% 提供的数据
windSpeed = [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 40]';

NREL_Reference_6MW = 1e-3*[0 0 0 0 246 562 1033 1691 2567 3691 5092 5860 6000 6000 6000 6000 6000 6000 6000 6000 6000 6000 6000 6000 6000 6000]';
NREL_Reference_8MW = 1e-3*[0 0 0 0 359 812 1483 2407 3616 5135 6976 7813 8000 8000 8000 8000 8000 8000 8000 8000 8000 8000 8000 8000 8000 8000 8000]';
NREL_Reference_10MW = 1e-3*[0 0 0 0 471 1059 1928 3125 4691 6655 8858 9767 10000 10000 10000 10000 10000 10000 10000 10000 10000 10000 10000 10000 10000 10000]';
DTU_Reference_10MW = 1e-3*[0 0 0 0 280 799 1533 2506 3731 5312 7287 9698 10639 10649 10639 10684 10642 10640 10640 10653 10646 10644 10641 10640 10644 10636]';
NREL_Reference_12MW = 1e-3*[0 0 0 0 400 1141 2189 3581 5323 7579 10397 12000 12000 12000 12000 12000 12000 12000 12000 12000 12000 12000 12000 12000 12000 12000]';
NREL_Reference_15MW = 1e-3*[0 0 0 0 499 1424 2732 4469 6643 9459 12975 15000 15000 15000 15000 15000 15000 15000 15000 15000 15000 15000 15000 15000 15000 15000 15000]';

% 创建表格
% WindTable = table(windSpeed, NREL_Reference_6MW, NREL_Reference_8MW, NREL_Reference_10MW, DTU_Reference_10MW, NREL_Reference_12MW, NREL_Reference_15MW);

% 先把参数设置的和IEEE的文章一样，验证模型是对的，再改参数
if modelType == 15
    electricityGeneration = interp1(windSpeed,NREL_Reference_15MW,inputWindSpeed,'linear');
    % para
    windTurbine.ratedPower = 15; windTurbine.cutinSpeed = 3; windTurbine.ratedSpeed = 11; windTurbine.cutoutSpeed = 31;
    windTurbine.hubHeight = 150; windTurbine.rotorRadius = 118; windTurbine.roughness = 0.0002;
    windTurbine.C_T = 0.5; windTurbine.airDensity = 1.25;
elseif modelType == 8 %https://en.wind-turbine-models.com/turbines/318-vestas-v164-8.0
    electricityGeneration = interp1(windSpeed,NREL_Reference_8MW,inputWindSpeed,'linear');
    % para
    windTurbine.ratedPower = 8; windTurbine.cutinSpeed = 4; windTurbine.ratedSpeed = 13; windTurbine.cutoutSpeed = 25;
    windTurbine.hubHeight = 112; windTurbine.rotorRadius = 82; windTurbine.roughness = 0.0002;
    windTurbine.C_T = 0.5; windTurbine.airDensity = 1.25;
end
electricityGeneration(inputWindSpeed > windTurbine.cutoutSpeed) = 0;
end

