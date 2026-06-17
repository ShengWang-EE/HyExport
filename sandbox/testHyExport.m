clear
% 颜色数据
colors = [
    191 97 106;     % 红色
    255 170 128;    % 橙色
    255 214 137;    % 柠檬黄色
    241 243 126;    % 淡黄色
    147 224 255;    % 淡蓝色
    160 196 255;    % 水蓝色
    169 205 112;    % 淡绿色
    115 186 151;    % 薄荷绿色
    250 207 176;    % 淡粉色
    248 155 167;    % 粉红色
    225 173 216;    % 浅紫色
    185 182 225;    % 淡蓝紫色
    226 192 217;    % 玫瑰色
    175 221 142;    % 淡绿黄色
    184 244 252;    % 天蓝色
    227 200 193;    % 豆沙色
    255 173 215;    % 浅梅红色
    173 232 244;    % 浅天蓝色
    192 236 148;    % 豆绿色
    198 246 173;    % 淡草绿色
    248 232 223;    % 浅米黄色
    255 209 134;    % 明黄色
    197 204 214;    % 亮灰色
    178 168 207;    % 浅蓝紫色
    230 216 232     % 浅紫灰色
] / 255; % 将颜色值归一化到 [0, 1] 范围

% 颜色英文名称
color_names = {
    'Red',
    'Orange',
    'Lemon Yellow',
    'Light Yellow',
    'Light Blue',
    'Aquamarine Blue',
    'Light Green',
    'Mint Green',
    'Light Pink',
    'Pink',
    'Light Purple',
    'Light Blue Purple',
    'Rose',
    'Light Green Yellow',
    'Sky Blue',
    'Tan',
    'Light Plum Red',
    'Light Sky Blue',
    'Pea Green',
    'Light Grass Green',
    'Light Beige',
    'Bright Yellow',
    'Light Gray',
    'Light Blue Purple',
    'Light Purple Gray'
};

% 绘制图形
figure;

for i = 1:size(colors, 1)
    subplot(4, 6, i); % 调整为4行6列的布局
    plot(1, 1, 'o', 'MarkerSize', 10, 'MarkerFaceColor', colors(i, :), 'MarkerEdgeColor', 'k');
    title(color_names{i});
    axis off;
end
%%
clear
% 生成24个颜色，复古、好看，颜色之间反差稍微大
colors = [
    153 50 53;     % Dark Red
    184 108 74;    % Brown Orange
    228 141 89;    % Light Red Brown
    248 186 140;   % Orange Yellow
    255 223 130;   % Light Yellow
    218 192 90;    % Goose Yellow
    168 183 110;   % Dark Yellow Green
    115 139 73;    % Dark Olive
    65 94 84;      % Gray Green
    85 58 55;      % Dark Brown
    115 99 104;    % Gray Red
    174 129 139;   % Light Brown Red
    236 158 133;   % Flesh Pink
    244 214 188;   % Dark Flesh Pink
    255 248 219;   % Light Beige
    191 163 144;   % Dark Beige
    120 134 121;   % Vine Green
    152 189 160;   % Mint Green
    173 206 188;   % Light Mint Green
    186 199 234;   % Blue Gray
    144 154 189;   % Light Blue
    115 108 177;   % Dark Purple
    155 132 172;   % Blue Purple
    195 179 205    % Light Blue Purple
] / 255; % 将颜色值归一化到 [0, 1] 范围

% 颜色英文名称
color_names = {
    'Dark Red',
    'Brown Orange',
    'Light Red Brown',
    'Orange Yellow',
    'Light Yellow',
    'Goose Yellow',
    'Dark Yellow Green',
    'Dark Olive',
    'Gray Green',
    'Dark Brown',
    'Gray Red',
    'Light Brown Red',
    'Flesh Pink',
    'Dark Flesh Pink',
    'Light Beige',
    'Dark Beige',
    'Vine Green',
    'Mint Green',
    'Light Mint Green',
    'Blue Gray',
    'Light Blue',
    'Dark Purple',
    'Blue Purple',
    'Light Blue Purple'
};

% 绘制图形
figure;

for i = 1:size(colors, 1)
    subplot(4, 6, i);
    plot(1, 1, 'o', 'MarkerSize', 10, 'MarkerFaceColor', colors(i, :), 'MarkerEdgeColor', 'k');
    title(color_names{i});
    axis off;
end
%%
clear
clc

% 生成一些示例数据，每个数据点包括纬度、经度和强度
latitude = randi([-90, 90], 100, 1);
longitude = randi([-180, 180], 100, 1);
[latgrid,longrid] = meshgrid(latitude,longitude); 
intensity = rand(100, 100);


% 创建地图
worldmap('World');

% 使用 geoshow 函数显示热力图
geoshow(latgrid, longrid, intensity,'DisplayType', 'surface');

% 添加标题和颜色栏
title('Geographical Heatmap');
c = colorbar;
c.Label.String = 'Intensity';
%%
clear
clc
% 生成一些示例数据，每个数据点包括纬度、经度和强度
latitude = randi([-90, 90], 100, 1);
longitude = randi([-180, 180], 100, 1);
intensity = randi([1, 10], 100, 1);

% 定义插值网格
numGridPoints = 100;
latGrid = linspace(min(latitude), max(latitude), numGridPoints);
lonGrid = linspace(min(longitude), max(longitude), numGridPoints);
[lonGrid, latGrid] = meshgrid(lonGrid, latGrid);

% 使用 griddata 函数进行插值
intensityInterpolated = griddata(latitude, longitude, intensity, latGrid, lonGrid, 'cubic');

% 创建地图
worldmap('World');

% 使用 pcolorm 函数绘制插值后的热力图
pcolorm(latGrid, lonGrid, intensityInterpolated);

% 添加标题和颜色栏
title('Interpolated Heatmap');
colorbar('Location', 'eastoutside', 'FontSize', 8);

%% read water depth data
fileName = 'EMODnet_bathymetry_2022.nc';
fileInfo = ncinfo(fileName);
%%
resolution = 100;
nx = size(1:100:size(bathymetry_2022.longitude,1),2);
ny = size(1:100:size(bathymetry_2022.latitude,1),2);
LCOE = zeros(nx,ny);
for ix = 17
    for iy = 11
        waterDepth1(ix,iy) = - bathymetry_2022.elevation(resolution*(iy-1)+1,resolution*(ix-1)+1);
        distanceToConnectPoint1(ix,iy) = distanceToConnectPoint(resolution*(ix-1)+1,resolution*(iy-1)+1);
        distanceToPort1(ix,iy) = distanceToPort(resolution*(ix-1)+1,resolution*(iy-1)+1);
        if waterDepth1(ix,iy) <= 30
            OWFtype = 1;
        elseif waterDepth1(ix,iy) <= 60
            OWFtype = 2;
        else
            OWFtype = 3;
        end
        LCOE(ix,iy) = evaluateOWFelectricityCost(OWFtype,capacityFactor,loadFactor,windTurbine,...
                    waterDepth1(ix,iy),distanceToConnectPoint1(ix,iy),distanceBetweenTurbine,distanceToPort1(ix,iy));
    end
end
%% 
cost1 = zeros(nx,ny);
for ix = 1:nx
    for iy = 1:ny
        if ~isnan(waterDepth(ix,iy)) && waterDepth(ix,iy) > 0
            cost1(ix,iy) = costInd{ix,iy}.totalCostNoCable;
            cost2(ix,iy) = costInd{ix,iy}.CAPEX;
        end
    end
end
cost1(cost1==0) = nan;
cost2(cost2==0) = nan;
%% 检查电力系统孤岛
am = zeros(nGb,nGb);
for i = 1:nGl
    fb = mpc.Gline(i,1);
    tb = mpc.Gline(i,2);
    am(fb,tb) = 1; am(tb,fb) = 1;
end
G = graph(am);
[components, numComponents] = conncomp(G);

% 检查是否存在孤岛
hasIslands = numComponents > 1;
%% draw the map
% fig1: areas
% figure;
% worldmap('world');
% fig.country = geoshow(IrelandShp.country,'DisplayType', 'polygon','FaceColor','white','FaceAlpha',1,'EdgeColor','black');
% fig.OWFforeshore = geoshow(IrelandShp.OWFforeshore,'DisplayType','polygon','FaceAlpha',1,'FaceColor',colorData.Red);
% fig.assessmentZone = geoshow(IrelandShp.assessmentZone,'DisplayType', 'polygon','FaceColor', ...
%     colorData.LightMintGreen,'FaceAlpha',0,'EdgeColor',colorData.VineGreen);
% fig.aquacultureSites = geoshow(IrelandShp.aquacultureSites,'FaceColor',colorData.BlueGray);
% fig.protectedMarineSites = geoshow(IrelandShp.protectedMarineSites,'FaceColor',colorData.LightBlue);
% fig.militaryAreas = geoshow(IrelandShp.militaryAreas,'FaceColor',colorData.BrightYellow);
% 
% legendEntries = [fig.country,fig.OWFforeshore,fig.assessmentZone, ...
%     fig.aquacultureSites,fig.protectedMarineSites,fig.militaryAreas];
% legendLabels = {'land areas', 'offshore wind farms','assessment zone',...
%     'aquaculture sites', 'protected marine sites','military areas'};
% legend(legendEntries,legendLabels);
% 
% worldmap('world');
% geoshow(latGrid, lonGrid, windMatrix.interpolated,'DisplayType','surface');
% colorbar;

save stop1.mat
%%
% read the wind data from nc file
% fileNameList = dir('G:\BaiduSyncdisk\Repository\Matlab repository\Irish UK map\Climate\wind data in 2023');
% [windMatrix,numDays] = loadWindDataFromNC(fileNameList); % load wind data from nc file
% windMatrix.speedHist = reshape(windMatrix.SPEED,[size(windMatrix.SPEED,1)*size(windMatrix.SPEED,2),1]);
% windMatrix.meanSpeed = mean(windMatrix.SPEED);

% IrelandPoly.boundingBox = polyshape([IrelandShp.boundingBox.X],[IrelandShp.boundingBox.Y]);
% IrelandPoly.assessmentZone = polyshape([IrelandShp.assessmentZone.X],[IrelandShp.assessmentZone.Y]);
% IrelandPoly.boundingBoxMinusAssessmentZone = subtract(IrelandPoly.boundingBox,IrelandPoly.assessmentZone);
% IrelandPoly.country = polyshape([IrelandShp.country.X],[IrelandShp.country.Y]);
% 
% [IrelandShp.boundingBoxMinusAssessmentZone.long,IrelandShp.boundingBoxMinusAssessmentZone.lat]...
%     = deal([IrelandPoly.boundingBoxMinusAssessmentZone.Vertices(:,1);IrelandPoly.boundingBoxMinusAssessmentZone.Vertices(1,1);NaN],...
%     [IrelandPoly.boundingBoxMinusAssessmentZone.Vertices(:,2);IrelandPoly.boundingBoxMinusAssessmentZone.Vertices(1,2);NaN]);

% ---test setting
% waterDepth = 40;
% distanceToConnectPoint = 60000;
% distanceToPort = 60000;
% distanceBetweenTurbine = 1000;
% OWFtype = 2;
% LCOEtest = evaluateOWFelectricityCost(OWFtype,capacityFactor,loadFactor,windTurbine,...
%     waterDepth,distanceToConnectPoint,distanceBetweenTurbine,distanceToPort);
%

% draw wind speed map
gridIndexNotInAssessmentZone = 1-inpolygon(lonGrid_windMesh,latGrid_windMesh,[IrelandShp.assessmentZone.X],[IrelandShp.assessmentZone.Y]);
windMatrix.interpolated(gridIndexNotInAssessmentZone==1) = NaN;


% waterDepth1(waterDepth1>100) = nan;

% export cost coordinate
assessmentZone_lon = bathymetry_2022.longitude(1:resolution:size(bathymetry_2022.longitude,1));
assessmentZone_lat = bathymetry_2022.latitude(1:resolution:size(bathymetry_2022.latitude,1));
[lonGrid,latGrid] = meshgrid(assessmentZone_lon,assessmentZone_lat);
assessmentZoneIndex = (inpolygon(lonGrid,latGrid,[IrelandShp.assessmentZone.X],[IrelandShp.assessmentZone.Y]))';
LCOEinAssessmentZone = LCOE; LCOEinAssessmentZone(assessmentZoneIndex==0) = 0;
LCOEinAssessmentZone(LCOEinAssessmentZone==0) = nan;

counter = 0;
for i = 1:nx
    for j = 1:ny
        if LCOEinAssessmentZone(i,j) >0
            counter = counter + 1;
            export.LCOE(counter,1) = lonGrid(1,i);
            export.LCOE(counter,2) = latGrid(j,1);
            export.LCOE(counter,3) = LCOEinAssessmentZone(i,j);
        end
    end
end
% figure
worldmap('world');
geoshow(latGrid, lonGrid, LCOEinAssessmentZone','DisplayType','surface');
colorbar;

%
LCOH_energy(LCOH_energy==0) = nan; LCOH_volume(LCOH_volume==0) = nan; LCOH_mass(LCOH_mass==0) = nan;
LCOA_hyVolume(LCOA_hyVolume==0) = nan; LCOH_hyEnergy(LCOH_hyEnergy==0) = nan; LCOH_hyMass(LCOH_hyMass==0) = nan;
%% merge norway
fileName = "bathymetry_2022_Norway1.nc"; fileInfo = ncinfo(fileName);
norway1.lon = ncread(fileName, 'longitude'); 
norway1.lat = ncread(fileName, 'latitude');
norway1.elevation = ncread(fileName, 'elevation');

fileName = "bathymetry_2022_Norway2.nc"; fileInfo = ncinfo(fileName);
norway2.lon = ncread(fileName, 'longitude'); 
norway2.lat = ncread(fileName, 'latitude');
norway2.elevation = ncread(fileName, 'elevation');

bathymetry_2022.longitude = norway1.lon;
bathymetry_2022.latitude = [norway1.lat;norway2.lat(11:end)];
bathymetry_2022.elevation = [norway1.elevation,norway2.elevation(:,11:end)]';

save('bathymetry_2022_Norway.mat','bathymetry_2022');
%%
EEZnew = rmfield(EUshpEEZ,'X');
EEZnew = rmfield(EEZnew,'Y');
shapewrite(EEZnew,'EEZnew.shp')
%%
sdpvar x
ff = interp1(LCOEcurve{1}(:,1),LCOEcurve{1}(:,2),x,'sos2');
optimize(0<=x<=100,ff)
plot(value(x),value(ff),'k*')
%%
index = zeros(nCountry,1);
for ic = 1:nCountry
    index(ic) = max(find(Q_hyspl(ic) > LCOHcurve{ic}(:,1)));
    marginalCost(ic,:) = LCOHcurve{ic}(index,:);
end

for ic = 1:nCountry
    LCOHaccumulatedCurve{ic} = [LCOHcurve{ic}];
    LCOHaccumulatedCurve{ic}(:,2) = cumsum(LCOHaccumulatedCurve{ic}(:,2),1);
end
%%
scatter(lonColumnE{5},latColumnE{5});