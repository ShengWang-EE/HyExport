# Paper Handoff

Last updated: 2026-06-18

## Ready Inputs

- Main manuscript draft exists at `manuscript/sn-article.tex`.
- SI draft exists at `manuscript/supplementary/J14___Supplementary_Information_v0_2/sn-article.tex`.
- Main figures exist in `manuscript/figs/`.
- SI figures exist in `manuscript/supplementary/J14___Supplementary_Information_v0_2/figs/`.
- NC revision plan exists at `manuscript/notes/NC_revision_plan.md`.
- Diagnostic Fig. 7 and robustness Fig. 8 candidates exist at `manuscript/figs/fig_nc_lcoh_counterfactual.pdf` and `manuscript/figs/fig_nc_outside_option_robustness.pdf`.
- Main manuscript now includes the counterfactual Results subsection, the outside-option threshold Results subsection, updated figure legends, and a revised abstract/Discussion opening aligned with the new story.

## Not Yet Ready

- SI-to-main-text cross-reference map.
- Final NC-style visual polishing for the revised figures.
- Main-text replacement plan for the older unit-commitment, wind-decomposition, and Sankey figures.
- Final data availability and code availability statements.
- Final author contributions.
- Clean compile after the revised manuscript and SI are integrated.

## Next Best Step

Align the Supplementary Information with the revised main-text claims and decide which dense old figures move to SI.

The lowest-LCOH-only counterfactual, second-draft Fig. 4, outside-option threshold scan, and second-draft Fig. 6 now exist and are cited in `manuscript/sn-article.tex`. `stop3.mat` and `NC_story_comparison.csv` have been refreshed with the current `optimalTransportation` code. `manuscript/notes/outside_option_price_sources.md` records the source basis for treating the 2-6 EUR/kg-H2 range as a threshold scan. Domestic absorption sensitivity also exists, but should be treated as SI/internal diagnostic material.

Important interpretation: the outside-option result is conditional, not unconditionally robust. External prices near 2-3 EUR/kg-H2 displace much of the European offshore supply, while prices near and above 4 EUR/kg-H2 restore the Ireland/UK strategic-export result.
