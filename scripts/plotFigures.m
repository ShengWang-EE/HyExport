projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
projectRoot = setupHyExport(projectRoot);
checkpointDir = fullfile(projectRoot, 'results', 'checkpoints');
[colors] = generateColorData('gem12');
colormap(nclCM(15,100));
%% wind speed map
countryEEZ = EUshpEEZ(strcmp(string({EUshpEEZ.TERRITORY1}), "Ireland"));
[climate,spatiResolution,lonGrid_mesh, latGrid_mesh] = loadCountryClimate(countryEEZ,500);
inEEZindex = inpolygon(lonGrid_mesh,latGrid_mesh,countryEEZ.X,countryEEZ.Y);
meanWindSpeed = climate.meanWindSpeed;
meanWindSpeed(~inEEZindex) = nan; 

minLon = min(min(lonGrid_mesh)); maxLon = max(max(lonGrid_mesh));
minLat = min(min(latGrid_mesh)); maxLat = max(max(latGrid_mesh));

figure;
colormap(nclCM(15,100));
% fig = axes;
worldmap([minLat,maxLat],[minLon,maxLon]);
% fig.Color = 'white';
geoshow(latGrid_mesh,lonGrid_mesh,meanWindSpeed,'DisplayType','texturemap');
hold on;
geoshow('gadm41_IRL_0.shp','FaceColor','white');
geoshow('AquacultureSites.shp','FaceColor',[0.8, 0.8, 0.8]);
% geoshow('Protected_Marine_Sites.shp','FaceColor','green'); % 这个好像是漏的，所以一填充全白了
geoshow('EMODnet_HA_MilitaryAreas_pg_20221216.shp','FaceColor',[0.8, 0.8, 0.8]);
geoshow('offshore areas (early planning).shp','FaceColor','none','EdgeColor','black','LineWidth',1,'DisplayType','polygon');

points = [
    -6.0392226, 53.8153670;
    -5.9810554, 52.6492857;
    -7.8880785, 51.7834268;
    -9.9732611, 53.263192
    ];

c = colorbar;
c.Label.String = 'Wind speed (m/s)'; 


geoshow(points(:,1), points(:,2), 'DisplayType', 'point', 'Marker', '.', ...
    'Color', 'black','MarkerSize',100);
labels = {'1','2','3','4'};
for i = 1:4
    text(points(i,1),points(i,2),labels{i}, 'VerticalAlignment', 'bottom', 'FontSize', 10, 'Color', 'black');
end
hold off;
exportgraphics(gcf, 'figs/fig wind speed map.emf', 'ContentType', 'vector');
%% windroses
points = [
    -6.0392226, 53.8153670;
    -5.9810554, 52.6492857;
    -7.8880785, 51.7834268;
    -9.9732611, 53.263192
    ];

fileName = resolveProjectFile("EUclimate.nc"); fileInfo = ncinfo(fileName);
lon = ncread(fileName, 'longitude'); 
lat = flip(ncread(fileName, 'latitude')); % lat is reversed!
u100 = flip(ncread(fileName, 'u100'),2);
v100 = flip(ncread(fileName, 'v100'),2);
[lon_meshed,lat_meshed] = meshgrid(lon,lat);
for i = 1:4
    for k = 1:8760
        coordinate = points(i,:);
        u100_point(k,i) = interp2(lon_meshed,lat_meshed,u100(:,:,k)',coordinate(1),coordinate(2));
        v100_point(k,i) = interp2(lon_meshed,lat_meshed,v100(:,:,k)',coordinate(1),coordinate(2));
    end
        windSpeed = sqrt(u100_point(:,i).^2 + v100_point(:,i).^2);
        direction = atan2(u100_point(:,i),v100_point(:,i)) / pi * 180;
        options.ndirections = 36;
        options.cmap = nclCM(15,100);
        options.EdgeWidth = 0.01;
        options.nspeeds = 5; 
        % options.speedround = 20;
        options.height = 425; options.width = 400;
        options.legendtype = 2;
        options.lablegend = 'Wind speed (m/s)';
        options.legendvariable = 'v';
        [figure_handle,count,speeds,directions,Table,Others] = WindRose(direction,windSpeed,options);
        if i ~= 1
            legend('off');
        end
        fileName  = ['fig windroseOfPoint',char(string(i))];
        exportgraphics(gcf, ['figs/',fileName,'.emf'], 'ContentType', 'vector');
end

%% wind turbine generation curve
windSpeedTest = 0:0.1:40;
[electricityGenerationCurvePlot,windTurbine] = windTurbineModel(windSpeedTest,15);
colororder(colors);
fig = figure;
set(fig,'Position',[0,0,600,200]);
plot(windSpeedTest,electricityGenerationCurvePlot,'LineWidth',2,'DisplayName','Power generation');
grid on;
legend('Location', 'southeast');
xlabel('Wind speed (m/s)');
ylabel('Power generation (MW)');
exportgraphics(gcf, 'figs/fig power curve of wind turbine.pdf', 'ContentType', 'vector');
%% wake effect
% draw line
for iRow = 1:size(wakeEffectSingle,1)
    iColumn = find(wakeEffectSingle(iRow,:)>0.11,1,'last');
    if ~isempty(iColumn)
        record(iRow,[1,2]) = [iRow,iColumn];
    end
end
x = resolution:resolution:resolution*size(wakeEffectSingle,1);
y = resolution:resolution:resolution*size(wakeEffectSingle,2);
colormap(nclCM(15,100));
figure('Position', [0, 0, 800, 200]);
imagesc(x,y,wakeEffectSingle');
xlim([resolution,2500]); ylim([resolution,100]);
% set(fig,'Position',[0,0,1000,200]);
hold on;
c = colorbar;
c.Label.String = 'Wake effect factor'; 
plot(record(:,1),record(:,2),'-','LineWidth',2,'Color','black');
xlabel('Vertical distance (m)');
ylabel('Horizontal distance (m)');
exportgraphics(gcf, 'figs/fig wake effect single.pdf', 'ContentType', 'vector');
%% EEZ and water depth
colormap(nclCM(15,100));
nGrid = 100;
EUshpEEZ = getEUEEZ(resolveProjectFile('eez_v12.shp'),EUcountryList);
EUcountryList = {'Belgium', 'Denmark', 'France', 'Germany', 'Ireland', 'Netherlands', 'Norway', 'Portugal', 'Spain', 'Sweden', 'United Kingdom'};

colormap([nclCM(15,100)]);  % 将白色添加到颜色映射的开始

for ic = 1:nCountry
    countryName = EUcountryList{ic};
    countryEEZ = EUshpEEZ(strcmp(string({EUshpEEZ.TERRITORY1}), string(countryName)));
    bathymetry{ic} = loadCountryBathymetry(countryEEZ,countryName,nGrid);
    bathymetry{ic}.elevation = - double(bathymetry{ic}.elevation);
    bathymetry{ic}.elevation(find(bathymetry{ic}.elevation<=0)) = nan;
    [lon_mesh,lat_mesh] = meshgrid(bathymetry{ic}.lon,bathymetry{ic}.lat); 
    inEEZindex = inpolygon(lon_mesh,lat_mesh,countryEEZ.X,countryEEZ.Y);
    bathymetry{ic}.elevation(~inEEZindex) = nan;
    map = geoshow(lat_mesh,lon_mesh,bathymetry{ic}.elevation,'DisplayType','surface','FaceAlpha','0.75');
    hold on;
    contourm(lat_mesh,lon_mesh,double(bathymetry{ic}.elevation),[30,30], ...
        'EdgeColor','black','LineWidth',1);
    contour(lon_mesh,lat_mesh,double(bathymetry{ic}.elevation),[60,60], ...
        'EdgeColor','red','LineWidth',1);
    
end
geoshow(EUshpEEZ,'DisplayType','Polygon','FaceColor','none');
hold off;
xlabel('Longtitute'); ylabel('Latitude');
c = colorbar;
c.Label.String = 'Water depth (m)'; 
exportgraphics(gcf, 'figs/fig water depth map.pdf', 'ContentType', 'vector');
% % 还是得化成一张图，不然会重叠
% nGrid = 1000;
% for iLon = 1:nGrid
%     for iLat = 1:nGrid

% 
%     alphaData = ones(size(bathymetry{ic}.elevation));
%     alphaData(isnan(bathymetry{ic}.elevation)) = 0;  % NaN 点透明
%     map = geoshow(lat_mesh,lon_mesh,bathymetry{ic}.elevation,'DisplayType','texturemap');
%     set(map, 'AlphaData', alphaData, 'AlphaDataMapping', 'none');
% 
% 
%     % uistack(h, 'top');
% % end
% 
% 
% hold on;
%% port location and distance to port
[ferryPortShp_noAggregation,ferryPortShp_aggregated,portIndexPerCountry,portInCountry] ...
    = loadFerryPort(resolveProjectFile('EMODnet_HA_Main_Ports_20231106.shp'),nCountry);

EU.minLon = -16.1; EU.maxLon = 36.5; EU.minLat = 34.8; EU.maxLat = 74.6;
nGrid = 300;
lonArray = linspace(EU.minLon,EU.maxLon,nGrid);
latArray = linspace(EU.minLat,EU.maxLat,nGrid);

nPort = size(ferryPortShp_aggregated,1);
distanceToPort = zeros(nGrid,nGrid);
for iLon = 1:nGrid
    for iLat = 1:nGrid
        lon = lonArray(iLon); lat = latArray(iLat); 
        distanceToPort(iLat,iLon) = min(deg2km(geoDistance(repmat([lon,lat],[nPort,1]),[[ferryPortShp_aggregated.X]',[ferryPortShp_aggregated.Y]']))); %km
    end
end

EUshpEEZ = getEUEEZ(resolveProjectFile('eez_v12.shp'),EUcountryList);
[lonMesh,latMesh] = meshgrid(lonArray,latArray);
inEEZ = zeros(nGrid,nGrid,nCountry);
for ic = 1:nCountry
    inEEZ(:,:,ic) = inpolygon(lonMesh,latMesh,EUshpEEZ(ic).X,EUshpEEZ(ic).Y);
end
inEEZ = max(inEEZ,[],3); % 只要在其中一个国家EEZ就行
distanceToPort(~inEEZ) = nan; 

colormap(nclCM(15,100));
geoshow(latMesh,lonMesh,distanceToPort,'DisplayType','surface');
geoshow(ferryPortShp_aggregated,'DisplayType','point','Marker','o',...
    'MarkerFaceColor','k','MarkerEdgeColor','none','MarkerSize',4);
geoshow(EUshpEEZ,'DisplayType','Polygon','FaceColor','none');
xlabel('Longtitute'); ylabel('Latitude');
c = colorbar;
c.Label.String = 'Distance to port (km)'; 
exportgraphics(gcf, 'figs/fig distance to port.pdf', 'ContentType', 'vector');
%% or change the type of fig 
colormap(nclCM(15,100));
nGrid = 100;
EUshpEEZ = getEUEEZ(resolveProjectFile('eez_v12.shp'),EUcountryList);
EUcountryList = {'Belgium', 'Denmark', 'France', 'Germany', 'Ireland', 'Netherlands', 'Norway', 'Portugal', 'Spain', 'Sweden', 'United Kingdom'};
colors = colororder('gem12');

fig = figure;
subplot1 = axes('Position', [0.1, 0.1, 0.6, 0.6]); % [left, bottom, width, height]

for ic = 1:nCountry
    % waterDepth_here = reshape(waterDepth{ic},[nGrid^2,1]);
    % distanceToPort_here = reshape(distanceToPort{ic},[nGrid^2,1]);
    % 
    % sizes_here = (reshape(capacityFactor{ic},[nGrid^2,1])-0.0).^(0.3)*1;
    % sizes_here(isnan(sizes_here)) = nan;
    scatter(log(waterDepth{ic}),log(distanceToPort{ic}),2,colors(ic,:),'MarkerFaceAlpha',0.2,'MarkerFaceColor',colors(ic,:),'MarkerEdgeColor','none','LineWidth',0.01);
    hold on;  
end
xlim([0,10]);
xlabel('log(Water depth) (m)'); 
ylabel('log(Distance to port) (m)');


subplot2 = axes('Position', [0.1, 0.7, 0.6, 0.2]); % [left, bottom, width, height]
for ic = 1:nCountry
    [f, xi] = ksdensity(reshape(log(waterDepth{ic}),[nGrid^2,1]));  % 计算概率密度
    plot(xi, f, 'k', 'LineWidth', 2,'Color',colors(ic,:),'DisplayName',EUcountryList{ic});  % 绘制概率密度曲线
    xlim([0,10]);
    hold on;
end
axis off;
lgd = legend('Location', 'southeast','NumColumns',3);
lgd.Position = [0.2 0.11 0.4 0.1];
% ylabel('Probability density');

subplot3 = axes('Position', [0.7, 0.1, 0.2, 0.6]); % [left, bottom, width, height]
for ic = 1:nCountry
    [f, xi] = ksdensity(reshape(log(distanceToPort{ic}),[nGrid^2,1]));  % 计算概率密度
    plot(f, xi, 'k', 'LineWidth', 2,'Color',colors(ic,:));  % 绘制概率密度曲线
    ylim([0,15]);
    hold on;
end
axis off;
% xlabel('Probability density');
set(fig, 'Position', [100, 100, 550, 550]);  % 同样的参数
exportgraphics(gcf, 'figs/fig distribution of water depth and distance to port.png', 'Resolution',1200);
%% LCOH map
colormap(nclCM(15,100));
nGrid = 100;
EUshpEEZ = getEUEEZ(resolveProjectFile('eez_v12.shp'),EUcountryList);
EUcountryList = {'Belgium', 'Denmark', 'France', 'Germany', 'Ireland', 'Netherlands', 'Norway', 'Portugal', 'Spain', 'Sweden', 'United Kingdom'};

for ic = 1:nCountry
    countryName = EUcountryList{ic};
    countryEEZ = EUshpEEZ(strcmp(string({EUshpEEZ.TERRITORY1}), string(countryName)));
    map = geoshow(latGrid_mesh{ic},lonGrid_mesh{ic},LCOH{ic},'DisplayType','surface');
    hold on;
    
end
geoshow(EUshpEEZ,'DisplayType','Polygon','FaceColor','none');
hold off;
xlabel('Longtitute'); ylabel('Latitude');
c = colorbar;
clim([90 200]);
c.Label.String = 'LCOH (€/MWh)'; 
text(1.166, 1.0355, '/above','Units', 'normalized', 'VerticalAlignment', 'top');

exportgraphics(gcf, 'figs/fig LCOH map.pdf', 'ContentType', 'vector');
%% vessel density and power density
fig = figure;
colors = colororder('gem12');
shortNameList = ["BE","DK","FR","DE","IE","NL","NO","PT","ES","SE","GB"];
subplot1 = axes('Position', [0.1, 0.1, 0.7, 0.9]); % [left, bottom, width, height]
colormap(nclCM(15,100));
[vesselDensity.value,vesselDensity.info] = readgeoraster(resolveProjectFile('vesseldensity_all_2022.tif'));
% [vesselDensity.value,vesselDensity.info] = readgeoraster('vesseldensity_all_2022.tif');
vesselDensity.value(abs(vesselDensity.value)>500) = nan;
[WGSlonLimits,WGSlatLimits] = rasterWgsLimits(vesselDensity.info);
[nLatRaster,nLonRaster] = size(vesselDensity.value);
[rasterCenterLon, rasterCenterLat] = deal(linspace(WGSlonLimits(1),WGSlonLimits(2),nLonRaster),linspace(WGSlatLimits(1),WGSlatLimits(2),nLatRaster));
vesselDensity.value = flip(vesselDensity.value,1); % 纬度又是倒过来的
lonmin = -16.1; lonmax = 36.5;
latmin = 34.8; latmax = 74.6;
rangeLon = find(rasterCenterLon>lonmin & rasterCenterLon<lonmax);
rangeLat = find(rasterCenterLat>latmin & rasterCenterLat<latmax);
[lonMesh,latMesh] = meshgrid(rasterCenterLon(rangeLon),rasterCenterLat(rangeLat));
vesselDensityEU = vesselDensity.value(rangeLat,rangeLon);
geoshow(latMesh,lonMesh,double(vesselDensityEU),'DisplayType','surface');
c = colorbar;
c.Label.String = 'Vessel density (hours/km^2/month)'; 
clim([0,5]);
xlim([lonmin,lonmax]);ylim([latmin,latmax]);
xlabel('Longtitute'); ylabel('Latitude');
grid on;
hold on;

for ic = 1:nCountry
    subplot2 = axes('Position', [0.85, 0.95 - ic*0.07, 0.1, 0.05 ]); % [left, bottom, width, height]
    powerDensity{ic} = powerPerGridNew{ic} / (deg2km(spatiResolution{ic}.lon) * deg2km(spatiResolution{ic}.lat));
    [f, xi] = ksdensity(reshape(powerDensity{ic},[nGrid^2,1]));  % 计算概率密度
    h = area(xi, f);  % 绘制概率密度曲线
    h.FaceColor = colors(ic,:);
    h.FaceAlpha = 0.1;
    h.EdgeColor = colors(ic,:);
    % axis off;
    if ic ~= 11
        set(gca, 'XTickLabel', []);
    end
    if ic == 11
        ylabel('Probability density');
        xlabel("Power density (MW/km^2)");
    end
    text(1, 1, shortNameList(ic), ...
        'Units', 'normalized', 'HorizontalAlignment', 'right','VerticalAlignment', 'top', 'Color', 'black');
    hold on;
    xlim([2.5,5]);
end


set(fig, 'Position', [100, 100, 940, 600]);  % 同样的参数
exportgraphics(gcf, 'figs/fig vessel density and power density.png', 'Resolution',1200);
%% LCOH supply curve
colors = colororder('gem12');
fig = figure;
% fig 1
subfig1 = axes('Position', [0.1, 0.1, 0.25, 0.7]); % [left, bottom, width, height]
for i = 1:size(EUcountryList,2)
    countryName = char(EUcountryList(i));
    plot(LCOHcurve2030{i}(:,1)/1e3,LCOHcurve2030{i}(:,2),'LineWidth', 1,'DisplayName',countryName,'Color',colors(i,:));
    hold on;
end
xlim([0, 0.6*1e2]); ylim([60,150]);
lgd = legend('Location', 'northoutside','NumColumns',4);
lgd.Position = [0.244 0.84 0.4 0.06];
ylabel('LCOH (€/MWh)');

% add marks
% UK: 55 GW
[~,index] = min(abs(LCOHcurve2030{11}(:,1)-55000));
x_val = LCOHcurve2030{11}(index,1)/1e3; y_val = LCOHcurve2030{11}(index,2);
plot([x_val,x_val],[0,y_val],'black--','HandleVisibility', 'off');
plot([0,x_val],[y_val,y_val],'black--','HandleVisibility', 'off');
plot(x_val,y_val,'o','MarkerSize',3,'MarkerEdgeColor',colors(11,:),'MarkerFaceColor','white',...
    'LineWidth',1,'HandleVisibility', 'off');
% ireland: 5GW
[~,index] = min(abs(LCOHcurve2030{5}(:,1)-5000));
x_val = LCOHcurve2030{5}(index,1)/1e3; y_val = LCOHcurve2030{5}(index,2);
plot([x_val,x_val],[0,y_val],'black--','HandleVisibility', 'off');
plot([0,x_val],[y_val,y_val],'black--','HandleVisibility', 'off');
plot(x_val,y_val,'o','MarkerSize',3,'MarkerEdgeColor',colors(5,:),'MarkerFaceColor','white',...
    'LineWidth',1,'HandleVisibility', 'off');
text(0.1, 1, 'a', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');
% subfig2
subfig2 = axes('Position', [0.4, 0.1, 0.25, 0.7]); % [left, bottom, width, height]
for i = 1:size(EUcountryList,2)
    countryName = char(EUcountryList(i));
    plot(LCOHcurve2040{i}(:,1)/1e3,LCOHcurve2040{i}(:,2),'LineWidth', 1,'DisplayName',countryName,'Color',colors(i,:));
    hold on;
end
xlim([0, 0.6*1e2]); ylim([60,150]);
xlabel('Hydrogen production capacity (GW)');
subfig2.YTick = [];
% add marks
% ireland: 20GW
[~,index] = min(abs(LCOHcurve2040{5}(:,1)-20000));
x_val = LCOHcurve2040{5}(index,1)/1e3; y_val = LCOHcurve2040{5}(index,2);
plot([x_val,x_val],[0,y_val],'black--','HandleVisibility', 'off');
plot([0,x_val],[y_val,y_val],'black--','HandleVisibility', 'off');
plot(x_val,y_val,'o','MarkerSize',3,'MarkerEdgeColor',colors(5,:),'MarkerFaceColor','white',...
    'LineWidth',1,'HandleVisibility', 'off');
text(0.1, 1, 'b', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');
% fig 3
subfig3 = axes('Position', [0.7, 0.1, 0.25, 0.7]); % [left, bottom, width, height]
for i = 1:size(EUcountryList,2)
    countryName = char(EUcountryList(i));
    plot(LCOHcurve2050{i}(:,1)/1e3,LCOHcurve2050{i}(:,2),'LineWidth', 1,'DisplayName',countryName,'Color',colors(i,:));
    hold on;
end
xlim([0, 0.6*1e2]); ylim([60,150]);
% add marks
% UK: 55 GW
[~,index] = min(abs(LCOHcurve2050{11}(:,1)-55000));
x_val = LCOHcurve2050{11}(index,1)/1e3; y_val = LCOHcurve2050{11}(index,2);
plot([x_val,x_val],[0,y_val],'black--','HandleVisibility', 'off');
plot([0,x_val],[y_val,y_val],'black--','HandleVisibility', 'off');
plot(x_val,y_val,'o','MarkerSize',3,'MarkerEdgeColor',colors(11,:),'MarkerFaceColor','white',...
    'LineWidth',1,'HandleVisibility', 'off');
% ireland: 37GW
[~,index] = min(abs(LCOHcurve2050{5}(:,1)-37000));
x_val = LCOHcurve2050{5}(index,1)/1e3; y_val = LCOHcurve2050{5}(index,2);
plot([x_val,x_val],[0,y_val],'black--','HandleVisibility', 'off');
plot([0,x_val],[y_val,y_val],'black--','HandleVisibility', 'off');
plot(x_val,y_val,'o','MarkerSize',3,'MarkerEdgeColor',colors(5,:),'MarkerFaceColor','white',...
    'LineWidth',1,'HandleVisibility', 'off');
subfig3.YTick = [];
text(0.1, 1, 'c', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');
hold off;
set(fig, 'Position', [100, 100, 600, 400]);  % 同样的参数
exportgraphics(gcf, 'figs/fig LCOH curves.pdf', 'ContentType', 'vector'); 
%% ireland power system
geoshow('Ireland and UK boundary low res.shp', 'DisplayType', 'polygon','FaceColor','none','EdgeColor','k');
busName = readtable(projectFile('tables','All Island Ten Year Transmission Statement-2021.xlsx'),...
        'sheet','bus name','range','A1:D371');
EbusCoordinate = table2array(busName(1:end,3:4));
colorSet = colormap(nclCM(15,100));
load(fullfile(checkpointDir,'mpcIreland.mat'))
mpc1 = mpc;

electricDemand = mpc1.bus(:,3);
colors = zeros(size(mpc1.bus,1),3);
sizes = zeros(size(mpc1.bus,1),1);
for i = 1:size(mpc1.bus,1)
    if electricDemand(i) ~= 0
        sizes(i) = min([(electricDemand(i)/20),5])*3+1;
        index(i) = ceil(electricDemand(i)/max(electricDemand)* 100);
        colors(i,:) = colorSet(index(i),:);
    else
        sizes(i) = 1;
        colors(i,:) = [0,0,0];
    end
    map = geoshow(EbusCoordinate(i,2),EbusCoordinate(i,1),'DisplayType','point','Marker','o',...
        'MarkerEdgeColor','none','MarkerFaceColor',colors(i,:),'MarkerSize',sizes(i));
end
xlim([-11,-5]);ylim([51,56]);
c = colorbar;
c.TickLabels = 0:max(electricDemand)/10:max(electricDemand);
c.Label.String = 'Electric demand (MW)';
xlabel('Longtitute'); ylabel('Latitude');

% 不画线了，有点乱 !!不对的原因是很多不同节点不知怎么的是同一个坐标。下次有时间再纠正
mpc1 = mpc;
for i = 1:size(mpc1.branch,1)
    fb = mpc.branch(i,1); tb = mpc.branch(i,2);
    fbCord = EbusCoordinate(fb,:); tbCord = EbusCoordinate(tb,:);
    geoshow([fbCord(:,2);tbCord(:,2)],[fbCord(:,1);tbCord(:,1)],'DisplayType','line');
end
exportgraphics(gcf, 'figs/fig ireland power system.pdf', 'ContentType', 'vector'); 
%% Ireland gas network
colorSet = colormap(nclCM(15,100));
GbusCoordinate = table2array(readtable(projectFile('tables','Irish energy system data.xlsx'),...
        'sheet','Gbus','range','H2:I145'));
load(fullfile(checkpointDir,'mpcIreland.mat'))
mpc1 = mpc;

gasDemand = mpc1.Gbus(:,3);
colors = zeros(size(mpc1.Gbus,1),3);
sizes = zeros(size(mpc1.Gbus,1),1);
for i = 1:size(mpc1.Gbus,1)
    if gasDemand(i) ~= 0
        sizes(i) = min([(gasDemand(i)*20),6])*2+2;
        index(i) = ceil(gasDemand(i)/max(gasDemand)* 100);
        colors(i,:) = colorSet(index(i),:);
    else
        sizes(i) = 2;
        colors(i,:) = [0,0,0];
    end
    map = geoshow(GbusCoordinate(i,2),GbusCoordinate(i,1),'DisplayType','point','Marker','o',...
        'MarkerEdgeColor','none','MarkerFaceColor',colors(i,:),'MarkerSize',sizes(i));
end
% draw pipeline
for i = 1:size(mpc1.Gline,1)
    fb = mpc1.Gline(i,1); tb = mpc1.Gline(i,2);
    fbCord = GbusCoordinate(fb,:); tbCord = GbusCoordinate(tb,:);
    geoshow([fbCord(:,2);tbCord(:,2)],[fbCord(:,1);tbCord(:,1)],'DisplayType','line','Color','k','LineWidth',1);
end

xlim([-10.5,-3.3]);ylim([51,56]);
c = colorbar;
c.Label.String = 'Gas demand (Mm^3/day)';
xlabel('Longtitute'); ylabel('Latitude');
c.TickLabels = linspace(0, max(gasDemand), 6);
% c.TickLabels = arrayfun(@(x) sprintf('%.2f', x), c.TickLabels, 'UniformOutput', false);

geoshow('Ireland and UK boundary low res.shp', 'DisplayType', 'polygon','FaceColor','none','EdgeColor','k');
exportgraphics(gcf, 'figs/fig ireland gas system.pdf', 'ContentType', 'vector'); 
%% ireland gas demand
gasDemand = readtable(projectFile('tables','Irish energy system data.xlsx'),'Sheet','future gas','Range','J40:Q70');
gasDemand = table2array(gasDemand(:,2:end));
colors = colororder('gem12');
% colors = colororder(generateColorData());
fig = figure;
area(gasDemand,'LineStyle','none');
set(fig, 'Position', [100, 100, 600, 200]);  % 同样的参数
xlabel('Year'); ylabel('Gas demand (Mm^3/day)');
xlim([1,30]);ylim([0,50]);
ax = gca;
ax.XTick = 0:5:30;
ax.XTickLabel = 2020:5:2050;
lgd = legend('Location', 'northeast','NumColumns',3);
lgd.Position = [0.391 0.71 0.4 0.2];
legend('Power',	'Industrial & Commercial',	'Residential',	'Transport',	'Own use',	'Isle of Man',	'Northern Ireland');
exportgraphics(gcf, 'figs/fig future ireland gas demand.pdf', 'ContentType', 'vector'); 
%% unit commitment
fig = figure;
colors = colororder('gem12');
% colors = [colors(1:10,:);[0.8,0.8,0.8]];
% fig 1
subfig1 = axes('Position', [0.1, 0.7, 0.6, 0.25]); % [left, bottom, width, height]
area([winter.interconnectorPower,winter.electricityGeneration,winter.windCurtailment],'LineStyle','none');
lgd = legend('Interconnector',"Coal","Waste","Peat", "Oil","Gasoil", "Gas","Water", "Solar","Wind",'Wind curtailment');
xlim([1,72]); ylim([-1000,7000]);
ylabel('Generation (MW)');
subfig1.XTick = [];
lgd.Position = [0.77 0.55 0.1 0.4];
text(0.05, 1, 'a', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');
% lgd.Location = 'northoutside';
% lgd.NumColumns = 3;
% fig 2
subfig2 = axes('Position', [0.1, 0.4, 0.6, 0.25]); % [left, bottom, width, height]
area([summer.interconnectorPower,summer.electricityGeneration,summer.windCurtailment],'LineStyle','none');
xlim([1,72]); ylim([-1000,7000]);
subfig2.XTick = [];
ylabel('Generation (MW)');
text(0.05, 1, 'b', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');

% fig 3
subfig3 = axes('Position', [0.1, 0.1, 0.6, 0.25]); % [left, bottom, width, height]
area([spring.interconnectorPower,spring.electricityGeneration,spring.windCurtailment],'LineStyle','none');
xlim([1,72]); ylim([-1000,7000]);
ylabel('Generation (MW)');
xlabel('Time (hour)');
text(0.05, 1, 'c', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');

exportgraphics(gcf, 'figs/fig unit commitment without offshore.pdf', 'ContentType', 'vector');
%% EU hydrogen demand
hydrogenDemand = [];
for iCountry = 1:11
    for iYear = 1:3
        hydrogenDemand = [hydrogenDemand; table2array(EUhydrogenDemand(iCountry,(iYear-1)*5+2:(iYear-1)*5+5))];
    end
    hydrogenDemand = [hydrogenDemand;zeros(1,4)];
end
bar(hydrogenDemand,'stacked','group');
hold off;
%% EU offshore wind/hydrogen capaicty
clear
clc

capacityTable = readtable(projectFile('tables','tables.xlsx'),'Sheet','offshore goal','Range','A1:E35');
EUcountryList = ["Belgium", "Denmark", "France", "Germany", "Ireland", "Netherlands", "Norway", "Portugal", "Spain", "Sweden", "United Kingdom"];
resourceList = ["Offshore wind","hydrogen","ammonia"];

fig = figure;
colors = colororder('gem12');
set(fig,'Position',[0,0,600,200]);
counter = 1;
for i = 2:34
    for j = 3:5
        if ~isnan(table2array(capacityTable(i,j)))
            country = table2cell(capacityTable(i,1));
            countryIndex = find(EUcountryList == country);
            resource = table2cell(capacityTable(i,2));
            resourceIndex = find(resourceList == resource);
            year = table2array(capacityTable(1,j));
    
            xx = table2array(capacityTable(i,j));
            yy = year;
           
            color = colors(countryIndex,:);
            size = 100;
            if resourceIndex == 1
                sc{counter} = scatter(xx,yy,size,color,"o",'filled','DisplayName',EUcountryList(countryIndex));
            elseif resourceIndex == 2
                sc{counter} = scatter(xx,yy,size,color,'Square','filled','DisplayName',EUcountryList(countryIndex));
            else 
                sc{counter} = scatter(xx,yy,size,color,"^",'filled','DisplayName',EUcountryList(countryIndex));
            end
            counter = counter + 1;
            hold on;
        end
    end
end
grid on;
legend([sc{1},sc{2},sc{6},sc{8},sc{9},sc{13},sc{15},sc{16},sc{17},sc{18}]);
legend('Location', 'eastoutside');
xlabel('Offshore resource capacity (GW)');
ylabel('Year');
exportgraphics(gcf, 'figs/fig EU offshore resource supply.pdf', 'ContentType', 'vector');

%% shipping cost heatmap
% colors = colororder('gem12');
countryShortNameList = {'BE','DK','FR','DE','IE','NL','NO','PT','ES','SE','GB'};

fig = figure;
colormap(nclCM(15,100));
% fig 1
% subfig1 = axes('Position', [0.1, 0.7, 0.7, 0.25]); % [left, bottom, width, height]
subplot(3,1,1);
heatmap1 = heatmap(solution{1}.shipHyFuelCostMatrix);
heatmap1.XLabel = 'To Country'; heatmap1.YLabel = 'From Country'; 
heatmap1.XDisplayLabels = countryShortNameList; heatmap1.YDisplayLabels = countryShortNameList;
clim([0,1.2]);
annotation('textbox', [0.00, 0.69, 0.2, 0.0], 'String', 'a', ...
           'HorizontalAlignment', 'center', 'EdgeColor', 'none', ...
           'FontSize', 10, 'FontWeight', 'bold');
heatmap1.Title = "Fuel cost (€/MWh)";
% fig 2
% subfig2 = axes('Position', [0.1, 0.4, 0.7, 0.25]); % [left, bottom, width, height]
subplot(3,1,2);
heatmap2 = heatmap(solution{2}.shipHyFuelCostMatrix);
heatmap2.XLabel = 'To Country'; heatmap2.YLabel = 'From Country'; 
heatmap2.XDisplayLabels = countryShortNameList; heatmap2.YDisplayLabels = countryShortNameList;
clim([0,1.2]);
annotation('textbox', [0.00, 0.39, 0.2, 0.0], 'String', 'b', ...
           'HorizontalAlignment', 'center', 'EdgeColor', 'none', ...
           'FontSize', 10, 'FontWeight', 'bold');
% fig 3
% subfig3 = axes('Position', [0.1, 0.1, 0.7, 0.25]); % [left, bottom, width, height]
subplot(3,1,3);
heatmap3 = heatmap(solution{3}.shipHyFuelCostMatrix);
heatmap3.XLabel = 'To Country'; heatmap3.YLabel = 'From Country'; 
heatmap3.XDisplayLabels = countryShortNameList; heatmap3.YDisplayLabels = countryShortNameList;
clim([0,1.2]);
annotation('textbox', [0.00, 0.09, 0.2, 0.0], 'String', 'c', ...
           'HorizontalAlignment', 'center', 'EdgeColor', 'none', ...
           'FontSize', 10, 'FontWeight', 'bold');

set(fig, 'Position', [100, 100, 400, 600]);  % 同样的参数
exportgraphics(gcf, 'figs/fig shipping fuel cost.pdf', 'ContentType', 'vector'); 

%% hydrogen and ammonia flow between countries (Sankey with ammonia)
nodeList = ["BE","DK","FR","DE","IE","NL","NO","PT","ES","SE","GB"];
nShippingLine = size(solution{1}.tradingArray,1);

adjMat1 = zeros(nCountry+1); adjMat2 = zeros(nCountry+1); adjMat3 = zeros(nCountry+1);
adjMat4 = zeros(nCountry+1); adjMat5 = zeros(nCountry+1); adjMat6 = zeros(nCountry+1);
for ij = 1:nShippingLine
    % hy
    if solution{1}.tradingArray(ij,4) > 0
        adjMat1(solution{1}.tradingArray(ij,1),solution{1}.tradingArray(ij,2)) = solution{1}.tradingArray(ij,4);
    else
        adjMat1(solution{1}.tradingArray(ij,2),solution{1}.tradingArray(ij,1)) = -solution{1}.tradingArray(ij,4);
    end
    if solution{2}.tradingArray(ij,4) > 0
        adjMat2(solution{2}.tradingArray(ij,1),solution{2}.tradingArray(ij,2)) = solution{2}.tradingArray(ij,4);
    else
        adjMat2(solution{2}.tradingArray(ij,2),solution{2}.tradingArray(ij,1)) = -solution{2}.tradingArray(ij,4);
    end
    if solution{3}.tradingArray(ij,4) > 0
        adjMat3(solution{3}.tradingArray(ij,1),solution{3}.tradingArray(ij,2)) = solution{3}.tradingArray(ij,4);
    else
        adjMat3(solution{3}.tradingArray(ij,2),solution{3}.tradingArray(ij,1)) = -solution{3}.tradingArray(ij,4);
    end
    % am
    if solution{1}.tradingArray(ij,5) > 0
        adjMat4(solution{1}.tradingArray(ij,1),solution{1}.tradingArray(ij,2)) = solution{1}.tradingArray(ij,5);
    else
        adjMat4(solution{1}.tradingArray(ij,2),solution{1}.tradingArray(ij,1)) = -solution{1}.tradingArray(ij,5);
    end
    if solution{2}.tradingArray(ij,5) > 0
        adjMat5(solution{2}.tradingArray(ij,1),solution{2}.tradingArray(ij,2)) = solution{2}.tradingArray(ij,5);
    else
        adjMat5(solution{2}.tradingArray(ij,2),solution{2}.tradingArray(ij,1)) = -solution{2}.tradingArray(ij,5);
    end
    if solution{3}.tradingArray(ij,5) > 0
        adjMat6(solution{3}.tradingArray(ij,1),solution{3}.tradingArray(ij,2)) = solution{3}.tradingArray(ij,5);
    else
        adjMat6(solution{3}.tradingArray(ij,2),solution{3}.tradingArray(ij,1)) = -solution{3}.tradingArray(ij,5);
    end
end
for i = 1:nCountry
    adjMat1(i,i) = 0; adjMat2(i,i) = 0; adjMat3(i,i) = 0;
    adjMat4(i,i) = 0; adjMat5(i,i) = 0; adjMat6(i,i) = 0;
end
% figure('Name','sankey demo6','Units','normalized','Position',[.05,.05,.59,.8])
fig = figure;
subfig1 = axes('Position', [0, 0.67, 0.5, 0.3]); % [left, bottom, width, height]
BCC1=biChordChart(adjMat1,'Arrow','on','Label',nodeList);
BCC1=BCC1.draw();

BCC1.tickState('on')
BCC1.setFont('FontName','Arial','FontSize',8)
BCC1.setLabelRadius(1.32);
text(0.05, 0.07, 'a', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');
text(0.68, 0.55, '2030 hydrogen', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');
%
subfig2 = axes('Position', [0, 0.35, 0.5, 0.3]); % [left, bottom, width, height]
BCC2=biChordChart(adjMat2,'Arrow','on','Label',nodeList);
BCC2=BCC2.draw();

BCC2.tickState('on')
BCC2.setFont('FontName','Arial','FontSize',8)
BCC2.setLabelRadius(1.32);
text(0.05, 0.07, 'c', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');
text(0.68, 0.55, '2040 hydrogen', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');
%
subfig3 = axes('Position', [0, 0.03, 0.5, 0.3]); % [left, bottom, width, height]
BCC3=biChordChart(adjMat3,'Arrow','on','Label',nodeList);
BCC3=BCC3.draw();

BCC3.tickState('on')
BCC3.setFont('FontName','Arial','FontSize',8)
BCC3.setLabelRadius(1.32);
text(0.05, 0.07, 'e', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');
text(0.68, 0.55, '2050 hydrogen', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');
%
subfig4 = axes('Position', [0.5, 0.67, 0.5, 0.3]); % [left, bottom, width, height]
BCC4=biChordChart(adjMat4,'Arrow','on','Label',nodeList);
BCC4=BCC4.draw();

BCC4.tickState('on')
BCC4.setFont('FontName','Arial','FontSize',8)
BCC4.setLabelRadius(1.32);
text(0.05, 0.07, 'b', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');
text(0.68, 0.55, '2030 ammonia', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');
%
subfig5 = axes('Position', [0.5, 0.35, 0.5, 0.3]); % [left, bottom, width, height]
BCC5=biChordChart(adjMat5,'Arrow','on','Label',nodeList);
BCC5=BCC5.draw();

BCC5.tickState('on')
BCC5.setFont('FontName','Arial','FontSize',8)
BCC5.setLabelRadius(1.32);
text(0.05, 0.07, 'd', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');
text(0.68, 0.55, '2040 ammonia', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');
%
subfig6 = axes('Position', [0.5, 0.03, 0.5, 0.3]); % [left, bottom, width, height]
BCC6=biChordChart(adjMat6,'Arrow','on','Label',nodeList);
BCC6=BCC6.draw();

BCC6.tickState('on')
BCC6.setFont('FontName','Arial','FontSize',8)
BCC6.setLabelRadius(1.32);
text(0.05, 0.07, 'f', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');
text(0.68, 0.55, '2050 ammonia', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');


set(fig, 'Position', [100, 100, 600, 800]);  % 同样的参数
exportgraphics(gcf, 'figs/fig hy am flow sankey.pdf', 'ContentType', 'vector'); 
%% hydrogen and ammonia flow between countries (Sankey without ammonia)
load(fullfile(checkpointDir,'stop3.mat'))
nodeList = ["BE","DK","FR","DE","IE","NL","NO","PT","ES","SE","GB","ITN"];
nNode = 12;
nShippingLine = size(solution{1}.tradingArray,1);

adjMat1 = zeros(nNode); adjMat2 = zeros(nNode); adjMat3 = zeros(nNode);
adjMat4 = zeros(nNode); adjMat5 = zeros(nNode); adjMat6 = zeros(nNode);
for ij = 1:nShippingLine
    % hy
    if solution{1}.tradingArray(ij,4) > 0
        adjMat1(solution{1}.tradingArray(ij,1),solution{1}.tradingArray(ij,2)) = solution{1}.tradingArray(ij,4);
    else
        adjMat1(solution{1}.tradingArray(ij,2),solution{1}.tradingArray(ij,1)) = -solution{1}.tradingArray(ij,4);
    end
    if solution{2}.tradingArray(ij,4) > 0
        adjMat2(solution{2}.tradingArray(ij,1),solution{2}.tradingArray(ij,2)) = solution{2}.tradingArray(ij,4);
    else
        adjMat2(solution{2}.tradingArray(ij,2),solution{2}.tradingArray(ij,1)) = -solution{2}.tradingArray(ij,4);
    end
    if solution{3}.tradingArray(ij,4) > 0
        adjMat3(solution{3}.tradingArray(ij,1),solution{3}.tradingArray(ij,2)) = solution{3}.tradingArray(ij,4);
    else
        adjMat3(solution{3}.tradingArray(ij,2),solution{3}.tradingArray(ij,1)) = -solution{3}.tradingArray(ij,4);
    end
    % am
    if solution{1}.tradingArray(ij,5) > 0
        adjMat4(solution{1}.tradingArray(ij,1),solution{1}.tradingArray(ij,2)) = solution{1}.tradingArray(ij,5);
    else
        adjMat4(solution{1}.tradingArray(ij,2),solution{1}.tradingArray(ij,1)) = -solution{1}.tradingArray(ij,5);
    end
    if solution{2}.tradingArray(ij,5) > 0
        adjMat5(solution{2}.tradingArray(ij,1),solution{2}.tradingArray(ij,2)) = solution{2}.tradingArray(ij,5);
    else
        adjMat5(solution{2}.tradingArray(ij,2),solution{2}.tradingArray(ij,1)) = -solution{2}.tradingArray(ij,5);
    end
    if solution{3}.tradingArray(ij,5) > 0
        adjMat6(solution{3}.tradingArray(ij,1),solution{3}.tradingArray(ij,2)) = solution{3}.tradingArray(ij,5);
    else
        adjMat6(solution{3}.tradingArray(ij,2),solution{3}.tradingArray(ij,1)) = -solution{3}.tradingArray(ij,5);
    end
end
for i = 1:nNode
    adjMat1(i,i) = 0; adjMat2(i,i) = 0; adjMat3(i,i) = 0;
    adjMat4(i,i) = 0; adjMat5(i,i) = 0; adjMat6(i,i) = 0;
end
% figure('Name','sankey demo6','Units','normalized','Position',[.05,.05,.59,.8])
fig = figure;
[colors] = generateColorData('gem12');
set(fig, 'DefaultAxesColorOrder', colors);
subfig1 = axes('Position', [0, 0.67, 0.5, 0.3]); % [left, bottom, width, height]
BCC1=biChordChart(adjMat1,'Arrow','on','Label',nodeList);
BCC1.CData = colors;
BCC1=BCC1.draw();

BCC1.tickState('on')
% BCC1.tickLabelState('on')
BCC1.setFont('FontName','Arial','FontSize',8)
BCC1.setLabelRadius(1.32);
text(0.05, 0.07, 'a', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');
text(0.55, 0.55, '2030', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');
%
subfig2 = axes('Position', [0, 0.35, 0.5, 0.3]); % [left, bottom, width, height]
BCC2=biChordChart(adjMat2,'Arrow','on','Label',nodeList);
BCC2.CData = colors;
BCC2=BCC2.draw();

BCC2.tickState('on')
BCC2.setFont('FontName','Arial','FontSize',8)
BCC2.setLabelRadius(1.32);
text(0.05, 0.07, 'c', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');
text(0.55, 0.55, '2040', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');
%
subfig3 = axes('Position', [0, 0.03, 0.5, 0.3]); % [left, bottom, width, height]
BCC3=biChordChart(adjMat3,'Arrow','on','Label',nodeList);
BCC3.CData = colors;
BCC3=BCC3.draw();

BCC3.tickState('on')
BCC3.setFont('FontName','Arial','FontSize',8)
BCC3.setLabelRadius(1.32);
text(0.05, 0.07, 'e', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');
text(0.55, 0.55, '2050', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');

% carbon reduction contributions
% 修改下计算程序，体现出每个国家对自己的脱碳贡献
subfig4 = axes('Position', [0.55, 0.69, 0.35, 0.27]); % [left, bottom, width, height]
colormap(colors);
subfig4.ColorOrder = colors;
bar1 = bar(solution{1}.carbonReductionContributionMatrix','stacked','BarWidth',0.5,'FaceAlpha',0.75);
legend(nodeList);
xticklabels({"BE","DK","FR","DE","IE","NL","NO","PT","ES","SE","GB"});
ylim([0,60]);
lgd = legend('Location', 'north','NumColumns',3);
text(-0.15, 0.01, 'b', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');
% lgd.Position = [0.244 0.84 0.4 0.06];
ylabel('CO_2 emission reduction (Mt/year)');
subfig5 = axes('Position', [0.55, 0.37, 0.35, 0.27]); % [left, bottom, width, height]
bar(solution{2}.carbonReductionContributionMatrix','stacked','BarWidth',0.5,'FaceAlpha',0.75);
xticklabels({"BE","DK","FR","DE","IE","NL","NO","PT","ES","SE","GB"});
ylim([0,60]);
ylabel('CO_2 emission reduction (Mt/year)');
text(-0.15, 0.01, 'd', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');

subfig6 = axes('Position', [0.55, 0.05, 0.35, 0.27]); % [left, bottom, width, height]
bar(solution{3}.carbonReductionContributionMatrix','stacked','BarWidth',0.5,'FaceAlpha',0.75);
xticklabels({"BE","DK","FR","DE","IE","NL","NO","PT","ES","SE","GB"});
ylim([0,60]);
ylabel('CO_2 emission reduction (Mt/year)');
text(-0.15, 0.01, 'f', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');

set(fig, 'Position', [100, 100, 600, 800]);  % 同样的参数
exportgraphics(gcf, 'figs/fig hy am flow sankey.pdf', 'ContentType', 'vector'); 
%% port aggregation
portCoordinate_noAggregation = [ [ferryPortShp_noAggregation.X]',[ferryPortShp_noAggregation.Y]' ];
portCoordinate_aggregated = [ [ferryPortShp_aggregated.X]',[ferryPortShp_aggregated.Y]' ];
geoscatter(portCoordinate_noAggregation(:,2), portCoordinate_noAggregation(:,1),'MarkerFaceColor','red');
hold on;
geoscatter(portCoordinate_aggregated(:,2), portCoordinate_aggregated(:,1),'MarkerFaceColor','blue');
hold off;

% -----------------------manuscript----------------------------------
%% LCOH map
clear
load(fullfile(checkpointDir,'stop3.mat'))
nGrid = 100;
EUshpEEZ = getEUEEZ(resolveProjectFile('eez_v12.shp'),EUcountryList);
EUcountryList = {'Belgium', 'Denmark', 'France', 'Germany', 'Ireland', 'Netherlands', 'Norway', 'Portugal', 'Spain', 'Sweden', 'United Kingdom'};
shortNameList = ["BE","DK","FR","DE","IE","NL","NO","PT","ES","SE","GB"];
fig = figure;
set(fig, 'Position', [100, 100, 940, 600]);  % 同样的参数
subplot1 = axes('Position', [0.1, 0.1, 0.7, 0.9]); % [left, bottom, width, height]
colormap(nclCM(15,100));
for ic = 1:nCountry
    countryName = EUcountryList{ic};
    countryEEZ = EUshpEEZ(strcmp(string({EUshpEEZ.TERRITORY1}), string(countryName)));
    map = geoshow(latGrid_mesh{ic},lonGrid_mesh{ic},LCOH{ic},'DisplayType','surface');
    hold on;
    
end
geoshow(EUshpEEZ,'DisplayType','Polygon','FaceColor','none');
hold off;
xlabel('Longtitute'); ylabel('Latitude');
c = colorbar;
clim([90 200]);
c.Label.String = 'LCOH (€/MWh)'; 
text(1.106, 1.0224, '/above','Units', 'normalized', 'VerticalAlignment', 'top');

countryEEZcentre = [
    0.37   0.50
    0.44  0.59
    0.22  0.39
    0.38   0.55
    0.1 0.5
    0.43  0.56
    0.38   0.77
    0.12 0.18
    0.12 0.3
    0.61  0.62
    0.3   0.62
    ];
for ic = 1:nCountry
    text(countryEEZcentre(ic,1), countryEEZcentre(ic,2), shortNameList(ic), ...
        'Units', 'normalized','VerticalAlignment', 'middle', 'Color', 'white','FontWeight', 'bold');
end
text(-0.06, 1.06, 'a', ...
        'Units', 'normalized', 'HorizontalAlignment','left', 'VerticalAlignment', 'top', 'Color', 'black','FontWeight', 'bold');

grid on;
hold on;
%
for ic = 1:nCountry
    countryEEZ = EUshpEEZ(strcmp(string({EUshpEEZ.TERRITORY1}), string(EUcountryList{ic})));
    [climate,spatiResolution,lonGrid_mesh, latGrid_mesh] = loadCountryClimate(countryEEZ,100);
    [size1,size2,size3] = size(climate.windSpeed);
    [f{ic}, xi{ic}] = ksdensity(reshape(climate.windSpeed,[size1*size2*size3,1]));  % 计算概率密度
end
%
for ic = 1:nCountry
    subplot2 = axes('Position', [0.88, 0.95 - ic*0.07, 0.07, 0.05 ]); % [left, bottom, width, height]
    h = area(xi{ic}, f{ic});  % 绘制概率密度曲线
    h.FaceColor = colors(ic,:);
    h.FaceAlpha = 0.1;
    h.EdgeColor = colors(ic,:);
    % axis off;
    if ic == 1
        text(-0.3, 1.7, 'b', ...
        'Units', 'normalized', 'HorizontalAlignment','left', 'VerticalAlignment', 'top', 'Color', 'black','FontWeight', 'bold');
    end
    if ic ~= 11
        set(gca, 'XTickLabel', []);
    end
    if ic == 6
        ylabel('Probability density');
    end
    if ic == 11
        xlabel("Wind speed (m/s)");
        subplot2.XTick = [0,20];
    end
    subplot2.YTick = [0,0.1];
    text(1, 1, shortNameList(ic), ...
        'Units', 'normalized', 'HorizontalAlignment', 'right','VerticalAlignment', 'top', 'Color', 'black');
    hold on;
    xlim([0,20]);
    ylim([0,0.15]);
    [maxDensity, idx] = max(f{ic});
    maxDensityPoint = xi{ic}(idx);
    plot([maxDensityPoint maxDensityPoint], [0, maxDensity], '-', 'LineWidth', 0.5,'Color',[0.5,0.5,0.5]);
end


exportgraphics(gcf, 'figs/fig LCOH map manu.pdf', 'ContentType', 'vector');
%% LCOH supply curve
colors = generateColorData('gem12');
fig = figure;
% fig 1
subfig1 = axes('Position', [0.1, 0.1, 0.25, 0.7]); % [left, bottom, width, height]
hold on;
fill([0,130,130,0],[0,0,68.92,68.92],[0.9, 0.9, 0.9], 'EdgeColor', 'none','FaceAlpha',0.25,'DisplayName','Blue hydrogen price');
for i = 1:size(EUcountryList,2)
    countryName = char(EUcountryList(i));
    plot(LCOHcurve2030{i}(:,1)/1e3,LCOHcurve2030{i}(:,2),'LineWidth', 1,'DisplayName',countryName,'Color',colors(i,:));
    hold on;
end
xlim([0, 1.3*1e2]); ylim([40,140]);
lgd = legend('Location', 'northoutside','NumColumns',4);
lgd.Position = [0.288 0.84 0.4 0.06];
ylabel('LCOH (€/MWh)');

% add marks
% UK: 55 GW
[~,index] = min(abs(LCOHcurve2030{11}(:,1)-55000));
x_val = LCOHcurve2030{11}(index,1)/1e3; y_val = LCOHcurve2030{11}(index,2);
plot([x_val,x_val],[0,y_val],'black--','HandleVisibility', 'off');
plot([0,x_val],[y_val,y_val],'black--','HandleVisibility', 'off');
plot(x_val,y_val,'o','MarkerSize',3,'MarkerEdgeColor',colors(11,:),'MarkerFaceColor','white',...
    'LineWidth',1,'HandleVisibility', 'off');
% ireland: 5GW
[~,index] = min(abs(LCOHcurve2030{5}(:,1)-5000));
x_val = LCOHcurve2030{5}(index,1)/1e3; y_val = LCOHcurve2030{5}(index,2);
plot([x_val,x_val],[0,y_val],'black--','HandleVisibility', 'off');
plot([0,x_val],[y_val,y_val],'black--','HandleVisibility', 'off');
plot(x_val,y_val,'o','MarkerSize',3,'MarkerEdgeColor',colors(5,:),'MarkerFaceColor','white',...
    'LineWidth',1,'HandleVisibility', 'off');
text(0.1, 1, 'a', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');

% subfig2
subfig2 = axes('Position', [0.4, 0.1, 0.25, 0.7]); % [left, bottom, width, height]
hold on;
fill([0,130,130,0],[0,0,68.92,68.92],[0.9, 0.9, 0.9], 'EdgeColor', 'none','FaceAlpha',0.25);
for i = 1:size(EUcountryList,2)
    countryName = char(EUcountryList(i));
    plot(LCOHcurve2040{i}(:,1)/1e3,LCOHcurve2040{i}(:,2),'LineWidth', 1,'DisplayName',countryName,'Color',colors(i,:));
    hold on;
end
xlim([0, 1.3*1e2]); ylim([40,140]);
xlabel('Hydrogen production capacity (GW)');
subfig2.YTick = [];
% add marks
% UK: 80 GW
[~,index] = min(abs(LCOHcurve2040{11}(:,1)-80000));
x_val = LCOHcurve2040{11}(index,1)/1e3; y_val = LCOHcurve2040{11}(index,2);
plot([x_val,x_val],[0,y_val],'black--','HandleVisibility', 'off');
plot([0,x_val],[y_val,y_val],'black--','HandleVisibility', 'off');
plot(x_val,y_val,'o','MarkerSize',3,'MarkerEdgeColor',colors(11,:),'MarkerFaceColor','white',...
    'LineWidth',1,'HandleVisibility', 'off');
% ireland: 20GW
[~,index] = min(abs(LCOHcurve2040{5}(:,1)-20000));
x_val = LCOHcurve2040{5}(index,1)/1e3; y_val = LCOHcurve2040{5}(index,2);
plot([x_val,x_val],[0,y_val],'black--','HandleVisibility', 'off');
plot([0,x_val],[y_val,y_val],'black--','HandleVisibility', 'off');
plot(x_val,y_val,'o','MarkerSize',3,'MarkerEdgeColor',colors(5,:),'MarkerFaceColor','white',...
    'LineWidth',1,'HandleVisibility', 'off');
text(0.1, 1, 'b', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');
% fig 3
subfig3 = axes('Position', [0.7, 0.1, 0.25, 0.7]); % [left, bottom, width, height]
hold on;
fill([0,130,130,0],[0,0,68.92,68.92],[0.9, 0.9, 0.9], 'EdgeColor', 'none','FaceAlpha',0.25);
for i = 1:size(EUcountryList,2)
    countryName = char(EUcountryList(i));
    plot(LCOHcurve2050{i}(:,1)/1e3,LCOHcurve2050{i}(:,2),'LineWidth', 1,'DisplayName',countryName,'Color',colors(i,:));
    hold on;
end
xlim([0, 1.3*1e2]); ylim([40,140]);
% add marks
% UK: 125 GW
[~,index] = min(abs(LCOHcurve2050{11}(:,1)-125000));
x_val = LCOHcurve2050{11}(index,1)/1e3; y_val = LCOHcurve2050{11}(index,2);
plot([x_val,x_val],[0,y_val],'black--','HandleVisibility', 'off');
plot([0,x_val],[y_val,y_val],'black--','HandleVisibility', 'off');
plot(x_val,y_val,'o','MarkerSize',3,'MarkerEdgeColor',colors(11,:),'MarkerFaceColor','white',...
    'LineWidth',1,'HandleVisibility', 'off');
% ireland: 37GW
[~,index] = min(abs(LCOHcurve2050{5}(:,1)-37000));
x_val = LCOHcurve2050{5}(index,1)/1e3; y_val = LCOHcurve2050{5}(index,2);
plot([x_val,x_val],[0,y_val],'black--','HandleVisibility', 'off');
plot([0,x_val],[y_val,y_val],'black--','HandleVisibility', 'off');
plot(x_val,y_val,'o','MarkerSize',3,'MarkerEdgeColor',colors(5,:),'MarkerFaceColor','white',...
    'LineWidth',1,'HandleVisibility', 'off');
subfig3.YTick = [];
text(0.1, 1, 'c', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','FontWeight','bold');
hold off;
set(fig, 'Position', [100, 100, 600, 400]);  % 同样的参数
exportgraphics(gcf, 'figs/fig LCOH curves manu.pdf', 'ContentType', 'vector'); 
%% table: likely to compete with blue hydrogen
%% unit commitment
% load stop3.mat
fig = figure;
colors = generateColorData('gem12');
set(fig, 'DefaultAxesColorOrder', colors);
indexSet1 = {'a: 2030-sum-0%','b: 2040-sum-20%','c: 2050-sum-100%';'d: 2030-win-0%','e: 2040-win-20%','f: 2050-win-100%'}; 
indexSet2 = {'g: 2030-sum-0%-ex','h: 2040-sum-20%-ex','i: 2050-sum-100%-ex';'j: 2030-win-0%-ex','k: 2040-win-20%-ex','l: 2050-win-100%-ex'};
for iYear = 1:3
    for iSeason = 1:2 % only present summer and winter
        subfig1{iYear,iSeason} = axes('Position', [(iYear-1)*0.3+0.08, 0.7 - 0.15*(iSeason-1), 0.25, 0.1]); % [left, bottom, width, height]
        area([interconnectorPowerNoExport{iYear,iSeason},electricityGenerationNoExport{iYear,iSeason},windCurtailmentNoExport{iYear,iSeason}]/1e3, ...
            'LineStyle','none','FaceAlpha',0.5);
        subfig1{iYear,iSeason}.Color = 'none';
        xlim([1,72]); ylim([-1,42]);
        ax1 = axes('Position', subfig1{iYear,iSeason}.Position, 'Color', 'none', 'YAxisLocation', 'right', 'XAxisLocation', 'bottom', 'XTick', []);
        line(1:72,curtailmentRateNoExport{iYear,iSeason},'Parent', ax1,'Color','black');
        ax1.Color = 'none';
        xlim([1,72]);ylim([0,1]);

        text(0.03, 1, indexSet1(iSeason,iYear), 'Units', 'normalized', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top','FontWeight','bold');

        subfig2{iYear,iSeason} = axes('Position', [(iYear-1)*0.3+0.08, 0.4 - 0.15*(iSeason-1), 0.25, 0.1]); % [left, bottom, width, height]
        area([interconnectorPowerExport{iYear,iSeason},electricityGenerationExport{iYear,iSeason},windCurtailmentExport{iYear,iSeason}]/1e3, ...
            'LineStyle','none','FaceAlpha',0.5);
        subfig2{iYear,iSeason}.Color = 'none';
        xlim([1,72]); ylim([-1,42]);

        if iYear ==3 & iSeason ==2
            lgd = legend('Interconnector',"Coal","Waste","Peat", "Oil","Gasoil", "Gas","Water", "Solar","Wind","Offshore wind",'Wind curtailment');
            lgd.Position = [0.407 0.85 0 0];
            lgd = legend('NumColumns',4);
            lgd.Color = [1,1,1];
        end
        ax2 = axes('Position', subfig2{iYear,iSeason}.Position, 'Color', 'none', 'YAxisLocation', 'right', 'XAxisLocation', 'bottom', 'XTick', []);
        line(1:72,curtailmentRateExport{iYear,iSeason},'Parent', ax2,'Color','black');
        ax2.Color = 'none';
        xlim([1,72]);ylim([0,1]);
        if iYear ==3 & iSeason ==2
            lgd = legend('Curtailment rate');
            lgd.Position = [0.833 0.827 0 0];
            lgd.Color = [1,1,1];
        end

        text(0.03, 1, indexSet2(iSeason,iYear), 'Units', 'normalized', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top','FontWeight','bold');

    end
end


set(fig, 'Position', [100, 100, 600, 600]);  % 同样的参数

text(-0.7, -0.55, 'Time (hour)', 'Units', 'normalized', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom','FontWeight','bold');
text(-2.52, 2.7, 'Generation (GW)', 'Units', 'normalized', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom','FontWeight','bold','Rotation', 90);
text(1.12, 2.7, 'Wind curtailment rate', 'Units', 'normalized', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom','FontWeight','bold','Rotation', 270);

exportgraphics(gcf, 'figs/fig unit commitment main.pdf', 'ContentType', 'vector');
%% wind decomposition
clc

% 生成随机数据
[colors] = generateColorData('gem12');

% fig1
Data = windConsump(1,:);
Name1 = {'2030-mid'};
Name2 = {'Wind used by power system', 'Wind used by gas system', 'Wind export otherwise curtailed', 'Wind curtailed anyway'};
fig = circleBarPlot(Data,Name1,Name2,colors,1);
text(0.1, 0.13, 'a', 'Units', 'normalized', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom','FontWeight','bold');
text(0,0,num2str(carbonReduction(1),'%.4g'),'FontWeight','bold', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
exportgraphics(gcf, 'figs/fig wind decomposition a.png', 'Resolution',1200);
% fig2
Data = windConsump(2,:);
Name1 = {'2040-mid'};
Name2 = {'Wind used by power system', 'Wind used by gas system', 'Wind export otherwise curtailed', 'Wind curtailed anyway'};
fig = circleBarPlot(Data,Name1,Name2,colors,0);
text(0.1, 0.13, 'b', 'Units', 'normalized', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom','FontWeight','bold');
text(0,0,num2str(carbonReduction(2),'%.4g'),'FontWeight','bold', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
exportgraphics(gcf, 'figs/fig wind decomposition b.png', 'Resolution',1200);
% fig3
Data = windConsump(3,:);
Name1 = {'2050-mid'};
Name2 = {'Wind used by power system', 'Wind used by gas system', 'Wind export otherwise curtailed', 'Wind curtailed anyway'};
fig = circleBarPlot(Data,Name1,Name2,colors,0);
text(0.1, 0.13, 'c', 'Units', 'normalized', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom','FontWeight','bold');
text(0,0,num2str(carbonReduction(3),'%.0f'),'FontWeight','bold', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
exportgraphics(gcf, 'figs/fig wind decomposition c.png', 'Resolution',1200);

%% hydrogen and ammonia flow between countries
clc
EUcountryshp = shaperead(resolveProjectFile('world-administrative-boundaries.shp'));
EUcountryList = ["Belgium", "Denmark", "France", "Germany", "Ireland", "Netherlands", "Norway", "Portugal", "Spain", "Sweden", "United Kingdom"];
ourCountryListShp = [EUcountryshp([14;13;8;33;15;49;12;4;44;48;28])];



fig = figure;
set(fig, 'Position', [100, 100, 900, 800]);  % 同样的参数
colors = colormap(nclCM(15,100));
color1 = colormap(nclCM('cmp_b2r'));
% ax = worldmap([25 75], [-20 40]);
map1 = geoshow(EUcountryshp,'DisplayType','Polygon','FaceColor','none');
hold on;
% calculate the face color
portmax = max(max(abs(totalExport)));
countryColorOrder = ceil((totalExport ./ portmax + 1.0001) * 32);
for ic = 1:nCountry 
    geoshow(ourCountryListShp(ic),'DisplayType','Polygon','FaceColor',color1(countryColorOrder(3,ic),:),'FaceAlpha',0.5);
    hold on;
end
ax = gca;
latlim = [35 73]; lonlim = [-15 35];
xlim(lonlim);ylim(latlim)


countryCenter = [
    0.428788531198687	0.459010954679804
    0.509859475415764	0.555911792624730
    0.410715018074217	0.406296562955855
    0.510346026865162	0.460450888911705
    0.240845763040240	0.508385129061104
    0.449467172333334	0.490029753200002
    0.495493165672039	0.624191592122539
    0.229899804046859	0.263403247284346
    0.307722356016732	0.277129915250967
    0.579556361150236	0.604947912394368
    0.336216314442164	0.493424106447640
    0.2                 0.8
    ];

% annotation('arrow', [countryCenter(11,1), countryCenter(1,1)], [countryCenter(11,2), countryCenter(1,2)], ...
%     'LineWidth', 5, 'Color', colors(10,:));

% annotation('textbox', [0.2, 0.52, 0.3, 0.3], ... % [左, 下, 宽, 高] 归一化坐标
%            'String', 'ITN', ...
%            'FitBoxToText', 'on', ...  % 自动调整文本框大小以适应文本
%            'BackgroundColor', colors(1,:), ...  % 背景颜色（白色）
%            'FaceAlpha', 0.5, ...  % 背景透明度
%            'EdgeColor', 'none');  % 边框颜色（无边框）

nShippingLine = size(solution{3}.tradingArray,1);
interflow = [];
for ij = 1:nShippingLine
    ic = solution{3}.tradingArray(ij,1); jc = solution{3}.tradingArray(ij,2); 
    if ic ~= jc
        interflow = [interflow,solution{3}.tradingArray(ij,4)];
    end
end

flowMax = max(abs(interflow));
for ij = 1:nShippingLine
    ic = solution{3}.tradingArray(ij,1); jc = solution{3}.tradingArray(ij,2); 
    arrowColorIndex = ceil(abs(solution{3}.tradingArray(ij,4)) / flowMax * 100);
    arrowWidth = ceil(abs(solution{3}.tradingArray(ij,4)) / flowMax * 10);
    if arrowColorIndex ~= 0 & ic~=jc
        arrowColor = colors(arrowColorIndex,:);
        if solution{3}.tradingArray(ij,4) > 0
            annotation('arrow', [countryCenter(ic,1), countryCenter(jc,1)], [countryCenter(ic,2), countryCenter(jc,2)], ...
                'LineWidth', 3, 'Color', arrowColor);
        elseif solution{3}.tradingArray(ij,4) < 0
            annotation('arrow', [countryCenter(jc,1), countryCenter(ic,1)], [countryCenter(jc,2), countryCenter(ic,2)], ...
                'LineWidth', 3, 'Color', arrowColor);
        end
        arrowCenter = [mean([countryCenter(ic,1), countryCenter(jc,1)]), mean([countryCenter(ic,2), countryCenter(jc,2)])];
        % text(arrowCenter(1),arrowCenter(2),'a','Units', 'normalized', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom','FontWeight','bold');
        flowValue = num2str(abs(solution{3}.tradingArray(ij,4)),'%.0f');
        annotation('textbox', [arrowCenter(1),arrowCenter(2), 0.05, 0.02], ... % [左, 下, 宽, 高] 归一化坐标
           'String', flowValue, ...
           'FitBoxToText', 'on', ...  % 自动调整文本框大小以适应文本
           'Color','black', ...
           'BackgroundColor', 'none', ...  % 背景颜色（白色）
           'FaceAlpha', 0.5, ...  % 背景透明度
           'EdgeColor', 'none');  % 边框颜色（无边框）
        a=1;
    end
end
colormap(colors);
hcb = colorbar('Location', 'north');
hcb.Position = [0.15 0.75 0.3 0.01];
% 
% annotation('arrow', [0, 1], [0, 1], ...
%             'LineWidth', 10, 'Color', 'b');
exportgraphics(gcf, 'figs/fig hy flow manu.pdf', 'ContentType', 'vector');
%% fig wind decomposition v2
clc
[colors] = generateColorData('gem12');
shortNameList = ["BE","DK","FR","DE","IE","NL","NO","PT","ES","SE","GB"];
% fig1

Data = EUwindConsump_new{1};
Name1 = shortNameList;
Name2 = {'Wind used by power system', 'Wind used by gas system', 'Wind export or curtailed', 'Wind curtailed anyway'};

% 数据展示范围及刻度
YLim = [0,700];
YTick = [];
% =========================================================================
% 开始绘图
if isempty(YLim) || isempty(YTick)
    tFig = figure('Visible', 'off');
    tAx = axes('Parent',tFig);
    tAx.NextPlot = 'add';
    bar(tAx, Data, 'stacked')
    if isempty(YLim), YLim = tAx.YLim; else, tAx.YLim = YLim; end
    if isempty(YTick), YTick = tAx.YTick; end
    close(tFig)
end
fig = figure;
set(fig, 'Position', [100, 100, 900, 900]);  % 同样的参数
ax = axes('Position', [0.05, 0.51, 0.45, 0.45]); % [left, bottom, width, height]
lgdHdl = circleBarPlot(Data,Name1,Name2,colors,1,YLim,YTick,ax);
text(-14,9,'TWh', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');
text(0.0, 0.0, 'a', 'Units', 'normalized', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom','FontWeight','bold');
text(0,0,'2030','FontWeight','bold', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
legend(lgdHdl, Name2, 'Box','off', 'Position',[0.28,0.62,0,0]);

% fig2
Data = EUwindConsump_new{2};
ax = axes('Position', [0.51, 0.51, 0.45, 0.45]); % [left, bottom, width, height]
circleBarPlot(Data,Name1,Name2,colors,0,YLim,YTick,ax);
text(-14,9,'TWh', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');
text(0.0, 0.0, 'b', 'Units', 'normalized', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom','FontWeight','bold');
text(0,0,'2040','FontWeight','bold', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');

% fig3
Data = EUwindConsump_new{3};
ax = axes('Position', [0.05, 0.05, 0.45, 0.45]); % [left, bottom, width, height]
circleBarPlot(Data,Name1,Name2,colors,0,YLim,YTick,ax);
text(-14,9,'TWh', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');
text(0.0, 0.0, 'c', 'Units', 'normalized', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom','FontWeight','bold');
text(0,0,'2050','FontWeight','bold', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');

exportgraphics(gcf, 'figs/fig wind decomposition.pdf', 'ContentType', 'vector');

%% 各个国家的表格转图
costTable = readtable(projectFile('tables','tables.xlsx'),'Sheet','cost table');
regions = {"BE","DK","FR","DE","IE","NL","NO","PT","ES","SE","GB"};
scenarios = {'Average LCOH', 'Marginal LCOH', 'Low-price hydrogen'};

% Generate Random Data
avrgCost2030 = table2array(costTable(2:12,2)); avrgRank2030 = table2array(costTable(2:12,3));
mgnCost2030 = table2array(costTable(2:12,4)); mgnRank2030 = table2array(costTable(2:12,5));
cap2030 = table2array(costTable(2:12,6));
avrgCost2040 = table2array(costTable(14:24,2)); avrgRank2040 = table2array(costTable(14:24,3));
mgnCost2040 = table2array(costTable(14:24,4)); mgnRank2040 = table2array(costTable(14:24,5));
cap2040 = table2array(costTable(14:24,6));
avrgCost2050 = table2array(costTable(26:36,2)); avrgRank2050 = table2array(costTable(26:36,3));
mgnCost2050 = table2array(costTable(26:36,4)); mgnRank2050 = table2array(costTable(26:36,5));
cap2050 = table2array(costTable(26:36,6));
addRow = nan(11,1); 


% Create Heatmap
fig = figure;
% fig 1
subfig1 = axes('Position', [0.1, 0.15, 0.2, 0.7]); % [left, bottom, width, height]

cost2030 = [avrgCost2030,mgnCost2030,addRow];
rank2030 = [avrgRank2030,mgnRank2030];
imagesc(cost2030); % Heatmap for mean wind speed changes

% Define custom red-blue colormap
colors = colormap(nclCM(15,100));
title('2030');
caxis([40,100]);      % Center the colormap at 0

set(gca, 'XTick', 1:length(scenarios), 'XTickLabel', scenarios);
set(gca, 'YTick', 1:length(regions), 'YTickLabel', regions);

hold on;

% Overlay Scatter Points
for i = 1:length(regions)
    for j = 1:length(scenarios)-1
        % Format the numeric value as text
        % value = cost2030(i, j);
        text(j, i, sprintf('%.0f', rank2030(i,j)), 'HorizontalAlignment', 'center', ...
             'VerticalAlignment', 'middle', 'Color', 'k'); % Text color is black
    end
end

% Add extra column with circles
offset = length(scenarios) - 1; % Position for the extra column
for i = 1:length(regions)
    if cap2030(i) == 0
        circleSize = 1; % Circle size corresponds to the value in extraColumn
        scatter(offset + 1, i, circleSize * 10, 'k', 'LineWidth', 0.5); % Draw circle with size scaling
    elseif cap2030(i) == 100
        circleSize = 10; % Circle size corresponds to the value in extraColumn
        scatter(offset + 1, i, circleSize * 10, 'k', 'LineWidth', 0.5); % Draw circle with size scaling
    else
        circleSize = 1 + cap2030(i) * 0.09;
        scatter(offset + 1, i, circleSize * 10, 'k', 'LineWidth', 0.5); % Draw circle with size scaling
    end
end

% Make NaN cells (right column) background white
colormap([1 1 1; colors]); % Add white color for NaN at the beginning of the colormap

% fig 2
subfig2 = axes('Position', [0.35, 0.15, 0.2, 0.7]); % [left, bottom, width, height]

cost2040 = [avrgCost2040,mgnCost2040,addRow];
rank2040 = [avrgRank2040,mgnRank2040];
imagesc(cost2040); % Heatmap for mean wind speed changes

% Define custom red-blue colormap
colors = colormap(nclCM(15,100));
title('2040');
caxis([40,100]);      % Center the colormap at 0
set(gca, 'XTick', 1:length(scenarios), 'XTickLabel', scenarios);
set(gca, 'YTick', 1:length(regions), 'YTickLabel', regions);

hold on;

% Overlay Scatter Points
for i = 1:length(regions)
    for j = 1:length(scenarios)-1
        % Format the numeric value as text
        % value = cost2030(i, j);
        text(j, i, sprintf('%.0f', rank2040(i,j)), 'HorizontalAlignment', 'center', ...
             'VerticalAlignment', 'middle', 'Color', 'k'); % Text color is black
    end
end

% Add extra column with circles
offset = length(scenarios) - 1; % Position for the extra column
for i = 1:length(regions)
    if cap2040(i) == 0
        circleSize = 1; % Circle size corresponds to the value in extraColumn
        scatter(offset + 1, i, circleSize * 10, 'k', 'LineWidth', 0.5); % Draw circle with size scaling
    elseif cap2040(i) == 100
        circleSize = 10; % Circle size corresponds to the value in extraColumn
        scatter(offset + 1, i, circleSize * 10, 'k', 'LineWidth', 0.5); % Draw circle with size scaling
    else
        circleSize = 1 + cap2040(i) * 0.09;
        scatter(offset + 1, i, circleSize * 10, 'k', 'LineWidth', 0.5); % Draw circle with size scaling
    end
end

% Make NaN cells (right column) background white
colormap([1 1 1; colors]); % Add white color for NaN at the beginning of the colormap

% fig 3
subfig3 = axes('Position', [0.6, 0.15, 0.2, 0.7]); % [left, bottom, width, height]

cost2050 = [avrgCost2050,mgnCost2050,addRow];
rank2050 = [avrgRank2050,mgnRank2050];
imagesc(cost2050); % Heatmap for mean wind speed changes

% Define custom red-blue colormap
colors = colormap(nclCM(15,100));
title('2050');
caxis([40,100]);      % Center the colormap at 0
set(gca, 'XTick', 1:length(scenarios), 'XTickLabel', scenarios);
set(gca, 'YTick', 1:length(regions), 'YTickLabel', regions);
hold on;

% Overlay Scatter Points
for i = 1:length(regions)
    for j = 1:length(scenarios)-1
        % Format the numeric value as text
        % value = cost2030(i, j);
        text(j, i, sprintf('%.0f', rank2050(i,j)), 'HorizontalAlignment', 'center', ...
             'VerticalAlignment', 'middle', 'Color', 'k'); % Text color is black
    end
end

% Add extra column with circles
offset = length(scenarios) - 1; % Position for the extra column
for i = 1:length(regions)
    if cap2050(i) == 0
        circleSize = 1; % Circle size corresponds to the value in extraColumn
        scatter(offset + 1, i, circleSize * 10, 'k', 'LineWidth', 0.5); % Draw circle with size scaling
    elseif cap2050(i) == 100
        circleSize = 10; % Circle size corresponds to the value in extraColumn
        scatter(offset + 1, i, circleSize * 10, 'k', 'LineWidth', 0.5); % Draw circle with size scaling
    else
        circleSize = 1 + cap2050(i) * 0.09;
        scatter(offset + 1, i, circleSize * 10, 'k', 'LineWidth', 0.5); % Draw circle with size scaling
    end
end

% Make NaN cells (right column) background white
colormap([1 1 1; colors]); % Add white color for NaN at the beginning of the colormap

c = colorbar;
ax = gca;
axPos = ax.Position; % [left, bottom, width, height]
c.Position(1) = axPos(1) + axPos(3) + 0.01; % 使 colorbar 放在右侧稍远一些
c.Position(3) = 0.02; % 设置 colorbar 宽度
ylabel(c, 'LCOH (€/MWh)');

hold off;

set(fig, 'Position', [100, 100, 600, 600]);  % 同样的参数
exportgraphics(gcf, 'figs/fig cost table.pdf', 'ContentType', 'vector');
%% cost reduction
clc
[colors] = generateColorData('gem12');
year = [2020,2030,2040,2050];
fixedReduction = -[0,0.21,0.35,0.49];
floatingReduction = -[0,0.02,0.17,0.4];
fig = figure;
plot(year,[fixedReduction;floatingReduction],'LineWidth',2);
hold on;
[colors] = generateColorData('gem12');
scatter(year,[fixedReduction],'lineWidth',2,'MarkerEdgeColor',colors(1,:));
scatter(year,[floatingReduction],'lineWidth',2,'MarkerEdgeColor',colors(2,:));
xlabel('Year'); ylabel('Percentage of reduction');


legend('Fixed offshore wind', 'Floating offshore wind');
set(fig, 'Position', [100, 100, 600, 300]);  % 同样的参数
exportgraphics(gcf, 'figs/fig cost reduction.pdf', 'ContentType', 'vector');
