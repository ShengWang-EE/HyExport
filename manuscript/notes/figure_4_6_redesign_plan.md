# Fig. 4 and Fig. 6 Redesign Plan

Date: 2026-06-17

Purpose: lock the scientific role and panel logic of the two new Nature Communications story figures before polishing style.

## Fig. 4: Cost-only allocation misidentifies strategic exporters

Single-sentence claim:

> A lowest-LCOH-only allocation identifies a different export geography from the integrated model, showing that production cost alone is insufficient for assessing strategic offshore hydrogen exporters.

Panel logic:

| Panel | Role | Keep in main figure? | Notes |
|---|---|---|---|
| a. Top net exporter matrix | Ranking or benchmark comparison | Yes | Directly shows that LCOH-only selects DK/NL/DK, while the integrated model selects GB/GB/IE for 2030/2040/2050. This should be the anchor panel. |
| b. Ireland and UK net export response | Claim-supporting evidence | Yes | Shows that the LCOH-only baseline underestimates the Ireland/UK strategic role, especially in 2050. |
| c. Residual international imports | Failure mode or limitation | Yes | Shows that the integrated model reveals residual import dependence that the LCOH-only baseline hides by ignoring domestic absorption and trade constraints. |

Supplement:

- Full country-level comparison table.
- Any alternative gross-export ranking.
- Dense country-by-country carbon contribution variants.

Results topic sentence:

> Comparing the integrated model with a lowest-LCOH-only allocation shows that the apparent low-cost export geography is not the same as the system-optimal trade geography.

Legend logic:

- Define LCOH-only baseline as an allocation by production cost only.
- Define integrated model as including domestic absorption, shipping, and demand balance.
- State the key numbers: 2050 LCOH-only top net exporter DK at 148 TWh/year; integrated top net exporter IE at 161 TWh/year, with GB at 131 TWh/year.

## Fig. 6: External import price defines a threshold for European offshore supply

Single-sentence claim:

> European offshore hydrogen exports are not unconditionally robust to cheap global imports, but Ireland and the UK re-emerge as major exporters once external low-carbon hydrogen/ammonia is not available at ultra-low delivered prices.

Panel logic:

| Panel | Role | Keep in main figure? | Notes |
|---|---|---|---|
| a. European offshore supply and outside import versus price | Threshold evidence | Yes | Anchor panel. Show offshore supply increasing and outside imports falling with outside-option price. |
| b. Ireland and UK 2050 net export versus price | Claim-supporting evidence | Yes | Focus on the headline 2050 strategic-export conclusion. |
| c. Supplier carbon contribution at selected prices | Translational consequence | Optional main / likely SI | Use only if space allows. Could be moved to SI if Fig. 6 becomes too busy. |

Supplement:

- Full 2030/2040/2050 threshold curves.
- Country table for all outside-option prices.
- Domestic absorption diagnostic.

Results topic sentence:

> The outside-option scan identifies a price threshold rather than unconditional robustness: very cheap external imports displace European offshore supply, whereas higher delivered import prices restore the Ireland/UK export role.

Legend logic:

- Define outside-option price as delivered hydrogen-equivalent import price.
- State source basis: low end informed by optimistic IRENA global trade/cost assumptions; wider range reflects delivery, infrastructure, finance and policy uncertainty.
- State threshold result: 2-3 EUR/kg-H2 displaces most European offshore supply; around and above 4 EUR/kg-H2 restores the integrated trade pattern.

## Visual Style

- Use restrained colour logic:
  - LCOH-only baseline: grey.
  - Integrated model: deep blue.
  - Ireland: green.
  - United Kingdom/GB: blue.
  - International/outside option: red or muted orange.
- Avoid long in-panel text.
- Use direct labels for the key countries rather than large legends where possible.
- Export vector PDFs to `manuscript/figs/` and high-resolution PNGs to `results/figures/`.

## Style Pass After Nature-Portfolio Benchmarking

Date: 2026-06-17

References checked:

- Nature Communications article format guidance: main Article figures should be commensurate with manuscript length and legends are limited to 350 words.
- Nature Communications hydrogen infrastructure example: country-level net hydrogen-balance heatmaps and infrastructure maps use compact panels, line widths, colour scales and ISO country codes rather than oversized explanatory graphics.
- Nature Energy European H2/CO2 network example: system-cost and network figures use restrained palettes, clear scenario panels, and data-dense but compact layouts.

Design changes made:

- Fig. 4 was changed from a large exporter-card matrix plus ordinary bars to a country-level net-export balance heatmap, with a small leading-exporter switch panel and a residual outside-import panel.
- Fig. 6 was changed from two thick line plots to a 2050 stacked supply-mix panel plus a compact exporter-response heatmap.
- Both figures now use direct colour-scale encoding, shorter in-panel labels, fewer legends, and vector PDF export for the manuscript folder.
