function lgdHdl = circleBarPlot(Data,Name1,Name2,Clist,legendOn,YLim,YTick,ax)

% 创建图窗
% fig = figure('Units','normalized', 'Position',[.2,.1,.5,.8]);


% ax = axes('Parent',fig, 'Position',[0,0,1,1]);
ax.NextPlot = 'add';
ax.XColor = 'none';
ax.YColor = 'none';
ax.DataAspectRatio = [1,1,1];
% 绘制坐标轴和刻度线
TLim = [pi/2, -pi - pi/6];
t01 = linspace(0, 1, 80);
N = size(Data, 1);
tT = t01.*diff(TLim) + TLim(1);
tX = cos(tT).*(N + N/2 + 1);
tY = sin(tT).*(N + N/2 + 1);
plot(ax, tX, tY, 'LineWidth',.8, 'Color','k');
ax.XLim = [-1,1].*(N + N/2 + 2);
ax.YLim = [-1,1].*(N + N/2 + 2);
tT = (YTick - YLim(1))./diff(YLim).*diff(TLim) + TLim(1);
tX = [cos(tT).*(N + N/2 + 1); cos(tT).*(N + N/2 + 1 + N/50); tT.*nan];
tY = [sin(tT).*(N + N/2 + 1); sin(tT).*(N + N/2 + 1 + N/50); tT.*nan];
plot(ax, tX(:), tY(:), 'LineWidth',.8, 'Color','k')
for i = 1:length(YTick)
    iT = tT(i); iR = iT/pi*180;
    YTickHdl = text(ax, tX(2,i), tY(2,i),...
        num2str(YTick(i)), 'HorizontalAlignment','center');
    if mod(iR, 360) > 180 && mod(iR, 360) < 360
        YTickHdl.Rotation = iR + 90;
        YTickHdl.VerticalAlignment = 'top';
    else
        YTickHdl.Rotation = iR - 90;
        YTickHdl.VerticalAlignment = 'bottom';
    end
end

Data = cumsum([zeros(N, 1), Data], 2);
% 绘制柱状图
lgdHdl = [];
for i = 1:N
    for j = 1:(size(Data, 2) - 1)
        tR = [(N + N/2 + 1 - i - .4).*ones(1, 80), (N + N/2 + 1 - i + .4).*ones(1, 80)];
        tT = (t01.*(Data(i, j + 1) - Data(i, j)) + Data(i, j) - YLim(1))./diff(YLim).*diff(TLim) + TLim(1);
        tX = cos([tT, tT(end:-1:1)]).*tR;
        tY = sin([tT, tT(end:-1:1)]).*tR;
        tHdl = fill(ax, tX, tY, Clist(j,:), 'LineWidth',1, 'EdgeColor','k','FaceAlpha', 0.5,'DisplayName',Name2{j});
        if i == 1
            lgdHdl(j) = tHdl;
        end
    end
end
% 绘制数据名称
for i = 1:N
    text(ax, 0, N + N/2 + 1 - i, [Name1{i},'  '], ...
        'HorizontalAlignment','right');
end
% 绘制图例
if legendOn == 1
% legend(lgdHdl, Name2, 'Box','off', 'Location','best',...
%     'Position',[.22, .93 - .04*(size(Data, 2) - 1), .1, .04*(size(Data, 2) - 1)]);
% legend(lgdHdl, Name2, 'Box','off', 'Location','northwest');
end

end