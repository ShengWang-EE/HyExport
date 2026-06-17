function [windMatrix,numDays] = loadWindDataFromNC(fileNameList)
%LOADWINDDATAFROMNC Summary of this function goes here
%   Detailed explanation goes here
deleteLine = [];
for i = 1:length(fileNameList)
    fileName = fileNameList(i).name;
    if ~contains(fileName,'nc')
        deleteLine = [deleteLine,i];
    end
end
fileNameList(deleteLine) = [];
for i = 1:length(fileNameList)
    fileName = fileNameList(i).name;
    fileInfo = ncinfo(fileName);
    % get date
    fileNameLength = length(fileName);
    for j = 1:fileNameLength-1
        if fileName(j) == '2' && fileName(j+1) == '0'
            year1 = str2num(fileName(j:j+3));
            month1 = str2num(fileName(j+4:j+5));
            day1 = str2num(fileName(j+6:j+7));
            break
        end
    end
    % 从2023年1月1日开始算起
    iday = daysact(datetime(2023,1,1), datetime(year1,month1,day1));
    numDays = daysact(datetime(2023,1,1), datetime(2023,12,31));
    islot.begin = iday*24+1; islot.end = (iday+1)*24;
    % extract variables
    lon = ncread(fileName, 'lon'); lat = ncread(fileName, 'lat');
    ULML = ncread(fileName, 'ULML'); VLML = ncread(fileName, 'VLML');
    RHOA = ncread(fileName, 'RHOA'); TLML = ncread(fileName, 'TLML');
    SPEED = ncread(fileName, 'SPEED');
    if i == 1
        windVelocity = cell(length(lon), length(lat));
        for ilon = 1:length(lon)
            for ilat = 1:length(lat)
                windVelocity{ilon,ilat}.ULML = zeros(numDays*24,1);
                windVelocity{ilon,ilat}.VLML = zeros(numDays*24,1);
            end
        end
    end
    counter = 0;
    for ilon = 1:length(lon)
        for ilat = 1:length(lat)
            counter = counter + 1;
            windMatrix.lon(1,counter) = lon(ilon);
            windMatrix.lat(1,counter) = lat(ilat);
            windMatrix.pointer(ilon,ilat) = counter;
            windMatrix.ULML(islot.begin:islot.end,counter) = ULML(ilon,ilat,:);
            windMatrix.VLML(islot.begin:islot.end,counter) = VLML(ilon,ilat,:);
            windMatrix.RHOA(islot.begin:islot.end,counter) = RHOA(ilon,ilat,:);
            windMatrix.TLML(islot.begin:islot.end,counter) = TLML(ilon,ilat,:);
            windMatrix.SPEED(islot.begin:islot.end,counter) = SPEED(ilon,ilat,:);
        end
    end
    windMatrix.lon0 = lon;
    windMatrix.lat0 = lat;
end
% add default value
missingRows = find(windMatrix.ULML(:,1) == 0);
for i = missingRows(:)'
    windMatrix.ULML(i,:) = windMatrix.ULML(i-24,:);
    windMatrix.VLML(i,:) = windMatrix.VLML(i-24,:);
    windMatrix.RHOA(i,:) = windMatrix.RHOA(i-24,:);
    windMatrix.TLML(i,:) = windMatrix.TLML(i-24,:);
    windMatrix.SPEED(i,:) = windMatrix.SPEED(i-24,:);
end
end

