function minDis = calculateMinDistance(windDecreaseFactor,nGridWake,resolution)
%% method 1
wakeEffectIndex = windDecreaseFactor>0.11;
distanceMatrix = sqrt(repmat(([1:nGridWake]*resolution).^2,[nGridWake,1]) ...
    + repmat(([1:nGridWake]'*resolution).^2,[1,nGridWake]));

minDis = max(max(distanceMatrix(wakeEffectIndex)));

%% method 2

end