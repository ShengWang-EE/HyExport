function [minDistanceWT,wakeEffectSingle] = evaluateWakeEffect(windTurbine,resolution,nGridWake)
% wake effect area for a single WT
for ix = 1:nGridWake
    dx = ix * resolution;
    for iy = 1:nGridWake
        dy = iy * resolution;
        sigma(ix,iy) = 0.5 * (windTurbine.rotorRadius + 0.56 / log(windTurbine.hubHeight/windTurbine.roughness) .* dx);
        windDecreaseFactor(ix,iy) = (1 - sqrt(1 - windTurbine.C_T / 2 ./ (sigma(ix,iy) / windTurbine.rotorRadius)^2) ) * exp(-dy.^2 / 2 / sigma(ix,iy).^2);
    end
end
% 就取实数部分也行
windDecreaseFactor_real = real(windDecreaseFactor);
% 截取一段进行画图
indexRow = max(find(max(windDecreaseFactor_real,[],2) > 1e-2));
indexColumn = ceil(indexRow / 6);
wakeEffectSingle = windDecreaseFactor_real(1:indexRow,1:indexColumn);
% 风机间距
minDistanceWT = calculateMinDistance(windDecreaseFactor,nGridWake,resolution);
end
