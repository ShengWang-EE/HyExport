function newmpc = addOffshoreToMpc(mpc,OWFcapacity_shortTerm,LCOE,powerPerGridNew,lonGrid_mesh,latGrid_mesh)
%% know the geolocation of OWFs
[LCOEinOrder, idx] = sort(LCOE(:));
[row, col] = ind2sub(size(LCOE), idx);

totalCapacity = 0;
for i = 1:size(row,1)
    totalCapacity = totalCapacity + powerPerGridNew(row(i),col(i));
    OWFcapacityIncrease(i) = powerPerGridNew(row(i),col(i));
    if totalCapacity > OWFcapacity_shortTerm
        OWFcapacityIncrease(i) = OWFcapacity_shortTerm - (totalCapacity - powerPerGridNew(row(i),col(i)));
        break
    end
end
%% know the connecting bus of OWFs
nb = size(mpc.busName,1); nGb = size(mpc.GbusName,1);
for i = 1:numel(OWFcapacityIncrease)
    lon = lonGrid_mesh(row(i),col(i)); lat = latGrid_mesh(row(i),col(i));
    EbusCoordinate = table2array(mpc.busName(:,3:4));
    GbusCoordinate = table2array(mpc.GbusName(:,2:3));
    [minDistanceToPowerGrid,EbusIndex(i)] = min(geoDistance(repmat([lon,lat],[nb,1]),EbusCoordinate));
    [minDistanceToGasNetwork,GbusIndex(i)] = min(geoDistance(repmat([lon,lat],[nGb,1]),GbusCoordinate));
end
%% add OWF to mpc
addgen = [];
addgencost = [];
addgenType = strings(0,1);
for i = 1:numel(OWFcapacityIncrease)
    addgen = [addgen; EbusIndex(i),0,0,OWFcapacityIncrease(i),-OWFcapacityIncrease(i),1,100,1,OWFcapacityIncrease(i),0,0,0,0,0,0,0,0,0,0,0,0];
    addgencost = [addgencost; 2,0,0,3,0,0,0];
    addgenType = [addgenType; "Offshore"];
end
newmpc = mpc;
newmpc.gen = [mpc.gen;addgen];
newmpc.gencost = [mpc.gencost;addgencost];
newmpc.genType = [mpc.genType;addgenType];
end
