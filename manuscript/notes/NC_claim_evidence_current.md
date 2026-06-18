# Current NC Claim-Evidence Audit

Date: 2026-06-18

Scope: current main manuscript after commit `a153453` and the current generated NC tables under `results/tables/`.

## Central Claim

Europe's strategic offshore hydrogen exporters cannot be inferred from LCOH alone. They emerge from the interaction of offshore production costs, domestic power-gas absorption, shipping economics, national hydrogen/ammonia demand, and external import competition.

Status: strong enough for Nature Communications framing, but it needs stronger SI support for novelty and domestic-absorption sensitivity.

## Claim-Evidence Map

| Claim location | Claim | Evidence | Status | Next fix |
|---|---|---|---|---|
| Title, `sn-article.tex:105` | Energy-system interactions reshape offshore hydrogen trade and carbon mitigation in Europe. | Entire Results sequence; especially LCOH-only counterfactual and trade/carbon results. | Supported | Keep. |
| Abstract, `sn-article.tex:143` | This is the first integrated European-scale framework linking cost-supply curves, hourly power-gas operation, cross-border hydrogen/ammonia shipping and European demand. | Methods describe all modules; current SI describes cost, domestic and trade modules separately. | Partial | Add novelty comparison table to SI and one sharper Introduction sentence. |
| Abstract, `sn-article.tex:143` | LCOH-only allocation identifies Denmark or the Netherlands, while integrated model identifies the UK and Ireland by 2050. | `results/tables/NC_story_comparison.csv`; Fig. `fig_nc_lcoh_counterfactual.pdf`. | Supported | Add SI method subsection for LCOH-only baseline. |
| Abstract, `sn-article.tex:143` | UK and Ireland each reach about 162 TWh yr^-1 net exports in 2050. | `NC_story_comparison.csv`: UK 162.141, Ireland 161.861 TWh yr^-1 under base integrated model. | Supported | Add source-number table so this remains auditable. |
| Abstract, `sn-article.tex:143` | Modelled offshore hydrogen contributes about 175.5 Mt CO2 yr^-1 mitigation. | `NC_story_comparison.csv`: 175.499942 Mt CO2 yr^-1 in 2050 integrated model. | Supported but method-sensitive | Clarify carbon mitigation attribution and displacement baseline in SI/Methods. |
| Abstract and Results, `sn-article.tex:323-325` | External imports near 2-3 EUR kg^-1 displace European offshore supply; around 4 EUR kg^-1 restores UK/Ireland export pattern. | `NC_outside_option_sensitivity.csv`: 2050 European offshore supply is 0, 98, and 766.6 TWh at 2, 3, and 4 EUR kg^-1. | Supported | Add SI method subsection and full year-by-year table/figure. |
| Introduction, `sn-article.tex:176` | Separate national LCOH studies cannot show production-cost interactions with domestic absorption, shipping, demand and imports. | Existing cited LCOH studies plus this paper's integrated model. | Partial | Add explicit literature-feature comparison; keep novelty strong. |
| Results 1, `sn-article.tex:182-195` | Denmark dominates LCOH, while Ireland/UK are sufficiently cost-competitive but not lowest-cost winners. | Fig. LCOH map/curves; Fig. 3 cost-rank figure. | Supported | Cost table restored to the main text after the user requested the original figure sequence. |
| Results 2, `sn-article.tex:265-280` | Domestic power-gas constraints create exportable surplus; Ireland reaches 170 TWh yr^-1 export potential. | Unit-commitment results and `EUwindConsump_new`; Fig. unit commitment and wind decomposition. | Partial | Add domestic absorption sensitivity to SI and improve figure expression. |
| Results 4, `sn-article.tex:307-318` | Production cost alone misidentifies strategic exporters. | `NC_story_comparison.csv`; Fig. counterfactual. | Supported | SI should define baseline clearly and provide country table. |
| Results 4, `sn-article.tex:305-317` | Integrated trade reallocates carbon-mitigation value across Europe. | Sankey figure and `solution.carbonReductionContributionMatrix`; `NC_story_comparison.csv`. | Supported but method-sensitive | Clarify H2/ammonia energy-equivalent units and carbon attribution. |
| Discussion, `sn-article.tex:342` | The central innovation is methodological and quantitative; integrated treatment exposes ranking reversal. | Counterfactual, integrated trade model, outside-option scan. | Supported, but needs external comparison | Step 2 novelty table. |
| Discussion, `sn-article.tex:344` | Domestic absorption outside Ireland is estimated by scaling Ireland whole-system result. | Main Methods and `NC_domestic_absorption_sensitivity.csv`. | Partial | Step 3: move sensitivity into SI and cite it in Discussion. |
| Discussion, `sn-article.tex:346-348` | More offshore production and infrastructure coordination could reduce residual external imports. | Integrated imports of 116 and 62 TWh yr^-1 in 2040 and 2050. | Supported as implication | Keep wording as "could", not "will". |

## Strongest Evidence

1. `NC_story_comparison.csv` directly supports the headline ranking reversal:
   - 2050 LCOH-only top net exporter: DK, 171.48 TWh yr^-1.
   - 2050 integrated top net exporter: GB, 162.14 TWh yr^-1.
   - Ireland nearly matches GB at 161.86 TWh yr^-1.
   - UK changes from 44.42 TWh yr^-1 net import in LCOH-only baseline to 162.14 TWh yr^-1 net export in the integrated model.

2. `NC_outside_option_sensitivity.csv` supports conditional robustness:
   - 2050 outside option 2 EUR kg^-1: European offshore supply 0 TWh.
   - 2050 outside option 3 EUR kg^-1: European offshore supply 98.16 TWh.
   - 2050 outside option 4 EUR kg^-1: European offshore supply 766.62 TWh; UK and Ireland return as large net exporters.

3. `NC_domestic_absorption_sensitivity.csv` already provides the missing stress test:
   - 2050 low absorption: UK remains top net exporter at 227.41 TWh, Ireland 142.13 TWh.
   - 2050 base absorption: UK 162.14 TWh, Ireland 161.86 TWh.
   - 2050 high absorption: Ireland becomes top net exporter at 154.77 TWh, UK falls to 63.44 TWh.
   - Interpretation: the exact UK/Ireland ordering depends on domestic absorption, but Ireland's strategic role survives the sensitivity range.

## Current Weak Points

1. Novelty is asserted more strongly than it is externally documented.
   - Fix: add SI novelty comparison table and sharpen Introduction.

2. Domestic absorption extrapolation is acknowledged but not yet visibly defended.
   - Fix: add SI sensitivity subsection and cite it from Discussion.

3. Carbon mitigation attribution is central but still too code-dependent.
   - Fix: add source-number table and carbon attribution explanation.

4. Main figure sequence is improved, but the Sankey/trade figure still reads denser than the other NC-style figures.
   - Fix: redesign the trade/carbon figure if another figure-quality pass is requested.

## Canonical Terms

- LCOH-only baseline: demand allocation to the lowest LCOH offshore supply segments, excluding domestic absorption, shipping costs, demand geography and competitive external-import prices.
- Integrated model: optimisation model combining cost-supply curves, available export potential, shipping costs, national hydrogen/ammonia demand and external imports.
- Available export potential: offshore hydrogen energy remaining after estimated domestic absorption; not the same as optimised net export.
- Net export: gross export minus gross import from the trade optimisation.
- External import: hydrogen/ammonia supplied from outside the 11 studied coastal European countries.
- Outside-option price: delivered hydrogen-equivalent external import price used in the threshold scan.
- Carbon mitigation contribution: supplier-destination CO2 reduction attributed through `carbonReductionContributionMatrix`.

## Next Action

Proceed to Step 2:

1. Add a novelty comparison table to SI.
2. Add one short Introduction sentence that points to the comparison without weakening the novelty claim.
3. Keep the main text concise; put the detailed feature-by-feature defence in SI.
