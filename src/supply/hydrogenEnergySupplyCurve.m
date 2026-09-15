function [energyCurve, accumulatedCurve] = hydrogenEnergySupplyCurve(capacityCurve, capacityFactor, year)
% Convert offshore installed MW to average hydrogen-equivalent MW.
% Keep installed-capacity curves unchanged for resource maps and rankings.
availability = 0.95; % Same availability used in main.m offshore generation.
energyCurve = capacityCurve;
energyCurve(:,1) = capacityCurve(:,1) * capacityFactor * availability * offshoreHydrogenEfficiency(year);
% Integrate the left-endpoint marginal costs; zero output has zero total cost.
accumulatedCurve = [energyCurve(:,1), [0; cumsum(diff(energyCurve(:,1)) .* energyCurve(1:end-1,2))]];
end
