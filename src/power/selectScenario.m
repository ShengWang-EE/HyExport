function [startHour,endHour,startDay,endDay] = selectScenario(season,electricityDemandCuve,onshoreWindAvaliableCapacity)
% plot([electricityDemandCuve(6400:7100),sum(onshoreWindAvaliableCapacity(6400:7100,:),2)]);
switch season
    case 'winter' % scenatio 1: high demand (winter), low wind
startDay = 328; endDay = 330;
startHour = (startDay-1)*24+1;
endHour = endDay*24;
% plot([electricityDemandCuve(startHour:endHour),sum(onshoreWindAvaliableCapacity(startHour:endHour,:),2)]);
    case 'summer' % scenario 2: low demand (summer), high wind
startDay = 181; endDay = 183;
startHour = (startDay-1)*24+1;
endHour = endDay*24;
% plot([electricityDemandCuve(startHour:endHour),sum(onshoreWindAvaliableCapacity(startHour:endHour,:),2)]);
    case 'spring' % scenario 3: mid demand, mid wind
startDay = 272; endDay = 274;
startHour = (startDay-1)*24+1;
endHour = endDay*24;
% plot([electricityDemandCuve(startHour:endHour),sum(onshoreWindAvaliableCapacity(startHour:endHour,:),2)]);
    case 'all'
        startDay = 1; endDay = 365;
        startHour = (startDay-1)*24+1;
        endHour = endDay*24;
end
end