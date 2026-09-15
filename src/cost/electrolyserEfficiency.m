function efficiency = electrolyserEfficiency(year)
% Manuscript Methods: AEC efficiency is 79% in 2030 and 82% in 2050.
% 2040 is linearly interpolated (80.5%); this is a modelling assumption.
year = str2double(string(year));
assert(isscalar(year) && ismember(year,[2030 2040 2050]), 'Use a model year: 2030, 2040 or 2050.');
efficiency = 0.79 + (year-2030)/20 * (0.82-0.79);
end
