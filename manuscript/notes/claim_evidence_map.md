# Claim Evidence Map

Date: 2026-06-17

Purpose: check whether the Nature Communications story is supported by the current manuscript, figures, SI, and checkpoints. This is a working audit before rewriting the abstract, Results, and Discussion.

## Working Central Claim

Europe's offshore hydrogen trade is not determined by the lowest production cost alone. It emerges from the interaction between offshore hydrogen cost-supply curves, domestic power-gas absorption limits, cross-border shipping economics, and national hydrogen/ammonia demand. This shifts decarbonisation value towards west-to-east trade flows, with Ireland and the UK becoming strategically important suppliers despite not always having the lowest LCOH.

## Claim Status

| Source | Current claim | Evidence currently available | Status | Required action |
|---|---|---|---|---|
| Title, line 103 | Cross-border offshore hydrogen trade mitigates carbon emissions for Europe's net-zero transition. | Fig. 6/Sankey and `solution{year}.carbonReductionContributionMatrix`; Methods trading model. | Partially supported | Title is broad but acceptable. It should become more specific to systems interaction or west-to-east offshore hydrogen value. |
| Abstract, lines 141-143 | Offshore green hydrogen could reduce 175.16 Mt/year CO2 emissions in Europe. | Current `stop3.mat` gives 43.5323, 129.3212, and 175.1608 Mt CO2/year for 2030, 2040, 2050 from `solution{year}.carbonReductionContributionMatrix`. | Supported for base case | Remove duplicate sentence in the abstract and state this as a 2050 base-case model result, not a universal potential. |
| Abstract, line 143 | UK is the largest hydrogen supplier from 2030 to 2040, surpassed by Ireland in 2050 with 161 TWh exports to France and Spain. | `solution{year}.tradingArray` and `totalExport`. Current checkpoint supports UK dominance in 2030. In 2050, GB remains largest in gross export, while Ireland is largest net exporter among the 11 studied European coastal countries if international import is excluded. Ireland-to-France-plus-Spain is about 159 TWh in current checkpoint. | Partially supported / wording risk | Define metric before claiming rank: gross export, net export, optimized export flow, export potential, or carbon contribution. Recommended wording: "Ireland becomes the largest net exporter among the studied European coastal countries in 2050." Verify/recompute after code fixes. |
| Abstract/Discussion, lines 143 and 365-366 | West-to-east offshore hydrogen flow reshapes Europe's energy supply and improves energy security. | Fig. 6/Sankey supports west-to-east flow. Energy-security/trilemma language is interpretive and not directly quantified. | Partially supported | Keep west-to-east flow. Weaken energy-security claim or add policy/citation support; avoid claiming it "solves" the energy trilemma. |
| Introduction, lines 181-184 | This is the first study to quantify offshore hydrogen's Europe-wide decarbonisation role with unified cost, domestic-system, and trade models. | Methods sections and SI support the integrated workflow. Literature comparison is currently narrative. | Partially supported | Avoid "for the first time" unless backed by a careful literature gap. Prefer "we develop an integrated..." |
| Results, lines 191-193 | Ireland and UK have rich wind resources; Denmark has lowest LCOH due to wind/bathymetry advantages. | Fig. 1/LCOH map and wind-speed density; SI wind/resource model. | Supported | Keep but compress. This is background evidence, not the main NC novelty. |
| Results, lines 202-208 | Denmark is most cost-competitive; Ireland and UK are sufficiently cost-competitive but need system-level assessment. | Fig. 2/LCOH curves and Fig. 3 cost-rank figure; `LCOHcurve2030/2040/2050`, `averageLCOH`, `marginalLCOH`, `hyUnderBlue`. | Supported | Cost-rank detail restored to the main text after the user requested the original figure sequence. |
| Results, lines 281-287 | Export access reduces Ireland's 2050 summer curtailment to 11.53% and enables average 27 GW export. | Fig. 4/unit commitment; `curtailmentRateExport`, `windCurtailmentExport`, `solutionExport`. | Partially supported | Recompute/check headline values after recent code fixes. Redesign figure to make this mechanism readable. |
| Results, lines 298-303 | Ireland becomes Europe's second-largest available export-potential country by 2050 with 167 TWh. | Fig. 5/wind decomposition; `EUwindConsump_new`. | Partially supported | Separate "available export potential" from optimized export flow. This assumption depends on extrapolating Ireland's domestic utilisation to other countries by demand proportionality. Add sensitivity or soften. |
| Results, lines 333-341 | Combining cost-supply, export potential, and shipping costs produces optimized future trade flows and mitigation. | Fig. 6/Sankey; `solution{year}.tradingArray`, `totalExport`, `carbonReductionContributionMatrix`; `optimalTransportation.m`. | Supported for base case | Make the model objective and flow units explicit in the Results and caption. Clarify whether plotted flows are hydrogen, ammonia, or combined hydrogen-equivalent energy. |
| Results, line 337 | International hydrogen import becomes essential in 2040. | Fig. 6 and `totalExport` international column/row. | Supported for base case | Define `ITN` as international import and document assumed cost/availability in Methods/SI. |
| Discussion, lines 347 and 350 | LCOH can reduce to 43.15 €/MWh; Ireland and UK account for 399 TWh supply capacity and 47.75% of carbon reduction in 2050. | Some support likely in `stop1.mat`, `stop2.mat`, and Fig. 2/5/6, but these exact numbers were not yet traced in this pass. | Needs verification | Add these to the headline-number audit before rewriting. If not directly reproducible, remove or reframe. |
| Discussion, lines 359-362 | More ambitious offshore goals could cover 162 TWh international imports in 2050, equivalent to 37 GW offshore electrolysers and wind farms. | Current trade model shows international imports, but the 162 TWh-to-37 GW conversion needs explicit calculation and assumptions. | Partially supported | Add a short calculation table or move to a policy implication with clear assumptions. |
| Data/code statements, lines 448-454 | Data sources are public and code is available on GitHub. | Code exists locally; public sources are cited; large local input data/checkpoints are not fully submission-packaged. | Partially supported | Prepare a reproducibility package: raw data list, generated checkpoint policy, scripts to regenerate figures, and code archive/repository DOI if possible. |

## Reverse Outline Of Current Results

1. Cost competitiveness: establishes resource/cost geography and LCOH rankings.
2. Domestic integration: uses Ireland as a detailed operational case to estimate curtailment and export access value.
3. Europe-wide export potential: extrapolates Ireland utilisation patterns to other countries.
4. Trade and carbon mitigation: optimizes shipping-based cross-border flows and reports decarbonisation contribution.

Current break point: the transition from the Ireland domestic-system model to Europe-wide domestic utilisation is the weakest evidence bridge. NC revision should either add sensitivity analysis or explicitly frame this as a transparent approximation.

## Metric Definitions To Lock

- Offshore production capacity: physical offshore wind/hydrogen capacity target.
- Available export potential: surplus after estimated domestic electricity and gas/hydrogen absorption.
- Gross optimized export flow: all outbound modeled trade from a country, regardless of inbound imports.
- Net optimized export flow: outbound modeled trade minus inbound modeled trade.
- Carbon mitigation contribution: CO2 reduction attributed to the supplier-destination matrix in `carbonReductionContributionMatrix`.
- International import: imported hydrogen/ammonia from outside the 11 studied coastal European countries, currently labelled `ITN`.

These terms should not be interchanged in the abstract, Results, captions, or Discussion.

## Strongest Current Evidence

- Base-case carbon mitigation totals are directly reproducible from `results/tables/NC_story_comparison.csv`: 43.4568, 129.7737, and 175.4999 Mt CO2/year. The corresponding European offshore supplier contributions are 43.4568, 103.1895, and 158.3014 Mt CO2/year.
- The cost-supply story is well supported by existing curves, maps, and cost tables.
- The systems-interaction story is plausible and important: Ireland/UK are not always lowest-LCOH countries, but export surplus and demand geography make them strategically important.

## Weakest Current Evidence

- Europe-wide domestic absorption and export potential rely on demand-proportional extrapolation from Ireland.
- The abstract's 2050 "Ireland surpasses the UK" claim is only safe if written as net export among studied European coastal countries, not gross export.
- Sensitivity analysis is not yet visible in the manuscript figure set.
- Energy-security and trilemma claims are stronger than the quantified evidence.

## Recommended Next Revision Step

Before rewriting the prose, build `results/tables/NC_headline_numbers.csv` from current checkpoints. It should include every number that appears in the abstract, Results, and Discussion, with columns for source checkpoint, variable, unit, manuscript location, and whether it needs rerun after code changes.
