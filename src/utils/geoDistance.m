function d = geoDistance(lonLat1, lonLat2)
d = distance(lonLat1(:,2), lonLat1(:,1), lonLat2(:,2), lonLat2(:,1));
end
