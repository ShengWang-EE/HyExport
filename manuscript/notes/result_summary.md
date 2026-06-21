# Result Summary

Last updated: 2026-06-19

This file tracks manuscript-facing results. Current headline values should be read together with `NC_headline_numbers.md` and `results/tables/NC_headline_numbers.csv`.

## Current Headline Results

- The integrated 2050 supply mix mitigates about 175.5 Mt CO2 yr^-1, of which 158.3 Mt CO2 yr^-1 is attributed to European offshore suppliers.
- The UK is the leading net exporter in the integrated model in 2030, 2040 and 2050, with 78, 122 and 162 TWh yr^-1.
- Ireland nearly matches the UK by 2050, with 162 TWh yr^-1 of integrated net exports after rounding.
- Ireland has about 170 TWh yr^-1 of available export potential in the 2050 domestic-absorption screen.
- The lowest-LCOH-only baseline instead identifies Denmark, the Netherlands and Denmark as the leading net exporters in 2030, 2040 and 2050.
- Delivered outside-option prices near 3 EUR kg^-1 H2-equivalent still suppress European offshore supply; around 3.3-3.5 EUR kg^-1 restores the UK/Ireland export pattern.

## Terms That Must Be Kept Separate

- offshore hydrogen production capacity
- available export potential
- optimised export flow
- carbon mitigation contribution
- domestic absorption
- international import

## Results Needing Stronger Support

- Europe-wide domestic utilisation extrapolated from the Ireland power-gas operation model.
- Full source-data export for Fig. 2 LCOH curves after the matching original checkpoint is recovered.
- Full hourly source-data export for Fig. 4 dispatch traces if required.
- Full flow and carbon-contribution matrices for Fig. 6 source-data packaging.

## Current Checkpoint Sources

- `results/checkpoints/stop1.mat`: cost maps and supply curves.
- `results/checkpoints/stop2.mat`: domestic utilisation and export potential.
- `results/checkpoints/stop3.mat`: international trade and carbon mitigation outputs.
- `results/checkpoints/mpcIreland.mat`: Ireland power-gas system case.
