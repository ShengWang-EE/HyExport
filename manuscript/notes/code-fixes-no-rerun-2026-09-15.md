# Code fixes — results deliberately not regenerated

Scope: fixes requested after review of the current main.m call chain. No MATLAB analysis, checkpoint, figure, CSV result or manuscript numerical value was regenerated.

- main.m now selects the existing 15 MW turbine branch.
- Residual wind electricity is converted to hydrogen energy before imposing trade supply limits. The net yield is derived from electrolyzerSizing, the same sizing model used for production costs. The initial fix retained the existing 65% setting; this has now been superseded by the year-dependent efficiency correction below.
- Installed-MW supply curves remain available for resource maps/rankings. Trade optimisation and the LCOH-only counterfactual convert these to average hydrogen MW using national mean capacity factor, the existing 0.95 availability assumption and net hydrogen yield. Cumulative costs start at zero.
- Both the counterfactual capacity limit and its cost-curve coordinates use the converted energy basis.
- Ship investment uses the existing 2030/2040/2050 prices, converted from USD to EUR. Capital annualisation discounts annual payments, and the objective receives the same year-specific parameters as transport postprocessing.
- Separate nonnegative directional flows/fleets assign fuel to the actual origin; aggregate signed flow and fleet outputs remain available for downstream consumers. Vessel counts retain the previous continuous-fleet approximation.
- Trade-figure exports now target manuscript/main/figs, matching the active LaTeX file.

Validation: independent numerical checks of energy conversion, capital present-value recovery and reverse-route energy balance passed. A small MATLAB regression function is in tests/testTradeAccounting.m. MATLAB failed at startup with a Qt/processor 'neon' compatibility error, so that regression function and the complete optimisation model have NOT run in this session.

Current stop*.mat files and published numerical tables/figures predate these fixes. A future refresh must start with the upstream supply calculation (including the changed turbine), not just redraw figures from old checkpoints. This change does not establish revised export rankings or mitigation totals. The existing ammonia accounting factor and other assumptions outside the reviewed fixes are unchanged.

## Subsequent correction: manuscript efficiency trajectory

- Added electrolyserEfficiency(year): 0.79 in 2030, 0.805 in 2040 (explicit linear interpolation assumption), 0.82 in 2050.
- electrolyzerSizing now accepts a model year; calls without a year use the 2030 baseline. Its compression, water and battery loads are preserved. Net platform HHV yields are approximately 0.6580023, 0.6684283 and 0.6787902, respectively.
- Production-cost evaluation shares geospatial/wind inputs but sizes the hydrogen equipment separately for each year. Each year's cost grid is used to build its supply curve before applying the existing technology-cost reductions. It does not merely rescale a fixed-efficiency LCOH denominator.
- Trade energy-curve conversion, supply limits and the LCOH-only counterfactual now pass the model year explicitly.
- Domestic PTG uses the same annual electrolyser efficiency. Corrected the energy equality from output = input / efficiency to output = input * efficiency, with the corresponding inverse conversion in its electricity-input upper bound. The simple OPF uses an optional year (2030 by default); the main multi-period OPF uses options.year.
- Extended the small regression test to cover all three years and a synthetic production-cost case. Independent numerical year/interpolation, energy-balance and inverse-capacity checks passed; MATLAB execution remains unverified because of the previously observed startup error. No analysis results were rerun or updated.

## Subsequent correction: annual equipment prices

- Added hydrogenCostParameters(year), selecting the original unrounded rate values corresponding to the SI 2030/2040/2050 columns (AEC CAPEX 625/400/300 kEUR/MW; OPEX 12.5/8/6 kEUR/MW/year). Compressor, battery, water, platform, replacement and pipeline rates follow the same year selection, retaining the existing currency conversions.
- evaluateHydrogenCost now requires year and windCostFactor, works with scalar prices, and no longer takes the first element of three-year CAPEX/OPEX arrays. The ammonia route removes the selected year's hydrogen-pipeline expenditure.
- The year-specific grid builder passes the year and the existing depth-dependent wind cost reduction. Wind learning scales the wind-farm total and its linked development expenditure; it does not multiply annual equipment costs a second time.
- owfCostReduction applies its outer reduction only to electricity costs. The hydrogen/ammonia curves already include annual sizing, equipment rates and wind learning.
- Added small regression checks for annual AEC rates, wind-only cost sensitivity and avoiding duplicate H/A cost reduction. MATLAB regression execution remains unverified owing to the earlier startup failure. No model, checkpoints, numerical tables, figures or manuscript results were rerun.

## Water mass and equipment capacity correction

- Corrected water molar mass from 18 to 0.018 kg/mol; water flow is kg/s and standard pressure is Pa.
- Removed the extra wind-farm-capacity multiplier from water-treatment capacity; both CAPEX and OPEX now use the total water-processing MW once.
- Added synthetic regression checks for water mass per standard cubic metre of hydrogen and water-cost increments independent of wind capacity. MATLAB checks remain unexecuted due to the previously observed MATLAB startup failure.
- No production models, results, figures or manuscript values were rerun or updated.
