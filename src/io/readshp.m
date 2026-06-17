function [struct] = readshp(shpfile)
%READSHP Summary of this function goes here
%   Detailed explanation goes here
shpfile = resolveProjectFile(shpfile);
struct = shaperead(shpfile);

structLength = size(struct,1);
for i = 1:structLength
    if max(abs([struct(i).X]))>200
        struct(i).X = km2deg(struct(i).X)/1000;
        struct(i).Y = km2deg(struct(i).Y)/1000;
    end

    struct(i).Lon = struct(i).X;
    struct(i).Lat = struct(i).Y;
end

