function [lonLimits,latLimits] = rasterWgsLimits(rasterRef)
if isprop(rasterRef,'LongitudeLimits')
    lonLimits = rasterRef.LongitudeLimits;
    latLimits = rasterRef.LatitudeLimits;
else
    xLimits = rasterRef.XWorldLimits;
    yLimits = rasterRef.YWorldLimits;
    xCorner = [xLimits(1),xLimits(1),xLimits(2),xLimits(2)];
    yCorner = [yLimits(1),yLimits(2),yLimits(1),yLimits(2)];
    [latCorner,lonCorner] = projinv(rasterRef.ProjectedCRS,xCorner,yCorner);
    lonLimits = [min(lonCorner),max(lonCorner)];
    latLimits = [min(latCorner),max(latCorner)];
end
end
