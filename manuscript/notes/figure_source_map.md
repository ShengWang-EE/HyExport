# Figure Source Map

Date: 2026-06-17

Purpose: map each current main-manuscript figure to the result it supports, the source code that produces it, and the checkpoint variables needed to reproduce it. This is a working document for the Nature Communications revision.

## Active Sources

- Main manuscript: `manuscript/sn-article.tex`
- Main figure folder used by LaTeX: `manuscript/figs/`
- Figure-generation script: `scripts/plotFigures.m`
- Main checkpoints: `results/checkpoints/stop1.mat`, `results/checkpoints/stop2.mat`, `results/checkpoints/stop3.mat`
- Current detailed SI draft: `manuscript/supplementary/J14___Supplementary_Information_v0_2/sn-article.tex`

Naming note: `scripts/plotFigures.m` currently exports several root-level files under `figs/` with spaces in the names, while the manuscript uses copied files under `manuscript/figs/` with underscores. Keep both paths explicit until the final figure build is standardized.

## Current Main Figures

| Manuscript figure | Current file | Script source | Main data/checkpoint | Current figure claim | NC action |
|---|---|---|---|---|---|
| Fig. 1, `fig LCOH map` | `manuscript/figs/fig_LCOH_map_manu.pdf` | `scripts/plotFigures.m` lines 858-947, exports `figs/fig LCOH map manu.pdf` as a 600 dpi image-based PDF | `stop3.mat`, inherited from `stop1.mat`: `LCOH`, `latGrid_mesh`, `lonGrid_mesh`, `EUcountryList`, `nCountry`; also reruns `loadCountryClimate` for wind-speed densities | Offshore hydrogen cost differs spatially; Ireland and UK have rich wind resources but Denmark has the lowest LCOH due to combined wind and bathymetry conditions. | Image-based export avoids excessive vector complexity from EEZ boundaries and gridded surfaces. The next design improvement would be simplifying the dense 11-country wind-density strips. |
| Fig. 2, `fig LCOH curve` | `manuscript/figs/fig_LCOH_curves_manu.pdf` | `scripts/plotFigures.m` lines 948-1039, exports `figs/fig LCOH curves manu.pdf` | `stop3.mat`, inherited from `stop1.mat`: `LCOHcurve2030`, `LCOHcurve2040`, `LCOHcurve2050` | Cost-supply curves show that the lowest-cost country is not necessarily the country with the largest strategic export value. | Keep as a main figure, but reduce line clutter. Highlight Denmark, UK, Ireland, Netherlands, Germany, and France; move full 11-country curves to SI if the main figure becomes unreadable. |
| Fig. 3, `fig lcoh rank` | `manuscript/figs/fig_cost_table.pdf` | `scripts/plotFigures.m` lines 1274-1436, exports `figs/fig cost table.pdf` | `tables/tables.xlsx`, sheet `cost table`; values should be reconciled with `stop1.mat` output variables `averageLCOH`, `marginalLCOH`, `hyUnderBlue` | Average LCOH, marginal LCOH, and blue-hydrogen-competitive capacity rank countries differently. | Restored to the main manuscript after the user requested the original figure sequence. |
| Fig. 4, `fig unit commitment` | `manuscript/figs/fig_unit_commitment_main.pdf` | `scripts/plotFigures.m` legacy main-figure export | `stop3.mat`: `curtailmentRateNoExport`, `curtailmentRateExport`, `windCurtailmentNoExport`, `windCurtailmentExport`, `electricityGenerationNoExport`, `electricityGenerationExport` | Power-system operation differs across years, seasons, hydrogen blending ratios and export conditions. | Restored original detailed main figure after the user requested the original figure sequence. |
| Fig. 5, `fig wind decomposition` | `manuscript/figs/fig_wind_decomposition.pdf` | `scripts/plotFigures.m` legacy main-figure export | `stop3.mat`: `EUwindConsump_new` | Domestic power-gas absorption limits create exportable surplus; the UK and Ireland become high-surplus countries by 2050. | Restored original utilisation figure after the user requested the original figure sequence. |
| Fig. 6, `fig sankey` | `manuscript/figs/fig_hy_am_flow_sankey.pdf` | `scripts/plotFigures.m` lines 737-848, exports `figs/fig hy am flow sankey.pdf`; `scripts/analysis/runOutsideOptionSensitivity.m` for robustness table | `stop3.mat`: `solution{year}.tradingArray`, `solution{year}.carbonReductionContributionMatrix`; `results/tables/NC_outside_option_sensitivity.csv` after rerun | Optimized cross-border flows and international imports determine carbon mitigation, with robustness against non-European outside-option import prices. | Keep the trade-flow idea, but improve readability. Use outside-option threshold scan as the main robustness candidate; keep domestic absorption diagnostics in SI only. |
| New Fig. 4 second draft, counterfactual | `manuscript/figs/fig_nc_lcoh_counterfactual.pdf` | `scripts/analysis/runLCOHOnlyCounterfactual.m` and `scripts/figures/plotNCStoryComparison.m`, both called from `main.m` | `stop3.mat`, `results/tables/NC_story_comparison.csv`, `results/tables/NC_story_comparison_country.csv` | A lowest-LCOH-only baseline identifies different leading exporters than the integrated model, showing why domestic absorption, demand, and trade constraints matter. | Now cited in the main Results section. Keep detailed country table in SI. |
| New Fig. 6 second draft, outside-option threshold | `manuscript/figs/fig_nc_outside_option_robustness.pdf` | `scripts/analysis/runOutsideOptionSensitivity.m` and `scripts/figures/plotNCOutsideOptionRobustness.m`, both called from `main.m` | `results/tables/NC_outside_option_sensitivity.csv`, `results/tables/NC_outside_option_sensitivity_country.csv`; source rationale in `manuscript/notes/outside_option_price_sources.md` | European offshore hydrogen supply is displaced when the external low-carbon import option is near 2-3 EUR/kg-H2, but the Ireland/UK strategic-export conclusion reappears around and above 4 EUR/kg-H2. | Now cited in the main Results section as a threshold/conditional robustness result. Full year-by-year price scan belongs in SI. |

## Proposed NC Main Figure Logic

### Fig. 1: Integrated Modelling Framework And Study Scope

Claim: the paper links offshore production costs, domestic absorption constraints, shipping economics, and hydrogen/ammonia demand in one systems workflow.

Evidence/source candidates:
- SI figure `figs/fig technical route.pdf`
- SI figure `figs/fig optimization structure.pdf`
- Methods sections in main manuscript lines 372-434
- SI sections on offshore cost models, domestic energy-system optimization, and international trading

Role: methodological bridge. This should make clear that the paper is not only an LCOH map or an Ireland case study.

### Fig. 2: Offshore Hydrogen Cost-Supply Curves

Claim: cost competitiveness varies across Europe, but LCOH rank alone does not determine the eventual export and mitigation value.

Suggested panels:
- Map or simplified spatial cost overview.
- 2030/2040/2050 cost-supply curves with highlighted countries.
- Optional compact rank/inset for marginal and average LCOH.

Move to SI:
- Full 11-country density strips.
- Full cost-rank heatmap/table.

### Fig. 3: Domestic Absorption And Exportable Surplus

Claim: domestic power-gas constraints leave substantial exportable offshore wind/hydrogen potential in island systems.

Suggested panels:
- Ireland dispatch or curtailment summary with and without export.
- Curtailment reduction in representative years/seasons.
- Export access mechanism: curtailed wind converted to exportable hydrogen.

Move to SI:
- Full 12-panel unit commitment time series.
- Detailed dispatch category stacks.

### Fig. 4: Europe-Wide Offshore Wind Use And Export Potential

Claim: domestic absorption limits and national demand create geographically uneven export potential, with the UK and Ireland becoming high-surplus countries.

Suggested panels:
- Stacked bars by country and year: domestic electricity use, domestic gas/hydrogen use, exportable surplus, unavoidable curtailment.
- Slope chart for net export potential of key countries.

Move to SI:
- Full circular decomposition if kept.
- Country-level raw decomposition tables.

### Fig. 5: Optimized Trade Flows

Claim: shipping-based trade reallocates offshore hydrogen value from western supply regions to continental demand centers.

Suggested panels:
- 2030, 2040, 2050 flow maps or simplified Sankey/chord diagrams.
- Explicitly distinguish hydrogen-only, ammonia-only, or combined hydrogen-equivalent energy flow.

Move to SI:
- Dense all-route matrices.
- Shipping fuel-cost matrices.

### Fig. 6: Carbon Mitigation And Robustness

Claim: the modeled offshore hydrogen system reduces approximately 175.4 Mt CO2/year by 2050, but this should be shown with robustness against a defensible external low-carbon hydrogen/ammonia import price.

Suggested panels:
- Carbon mitigation by destination country and supplier group.
- Contribution of Ireland, UK, Denmark/Netherlands, other Europe, and international imports.
- Outside-option threshold panel showing European offshore supply, international imports, and Ireland/UK net exports across delivered import prices.
- Domestic absorption diagnostic only in SI unless stronger external evidence is added.

Current blocker: outside-option threshold scan needs to be run and then converted into a clean NC-style robustness panel.

## SI Figure Anchors

The current SI draft already contains material that can absorb dense methods and diagnostics:

- Offshore wind resource and turbine modelling: wind speed map, wind turbine curve, coordinate rotation, wake effect.
- Offshore cost model: technical route, LCOE composition, water depth, distance to port, LCOH structure, cost reduction.
- Domestic system model: optimization framework, Ireland power system, Ireland gas system, future gas demand, unit commitment without offshore.
- Trade model: hydrogen demand, offshore wind capacity table, shipping fuel cost.

## Immediate Figure Tasks

1. Standardize figure filenames between `scripts/plotFigures.m`, root `figs/`, and `manuscript/figs/`.
2. Decide whether main Fig. 1 should be a new framework schematic assembled from SI framework/technical-route figures.
3. Move the legacy detailed 12-panel dispatch figure to SI if the Methods/SI needs a full operational example.
4. Keep the restored original `fig_wind_decomposition.pdf` in the main text unless the user explicitly approves another redesign.
5. Verify whether Fig. 6 reports hydrogen-only, ammonia-only, or combined hydrogen-equivalent flows, then make that terminology consistent in the caption and Results.
6. Align the SI with the new counterfactual and outside-option threshold results, including full country and price-scan tables.
