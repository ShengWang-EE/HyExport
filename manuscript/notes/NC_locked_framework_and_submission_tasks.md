# Locked manuscript framework and submission tasks

Date: 2026-06-18

Purpose: lock the current Nature Communications manuscript structure after restoring the original main figures. Future revisions should improve this framework rather than replace the original figure sequence unless the user explicitly approves a stronger alternative.

## Locked central story

Strategic offshore hydrogen exporters in Europe cannot be inferred from LCOH alone. They emerge from the interaction of geospatial production costs, domestic power-gas absorption, shipping economics, hydrogen/ammonia demand geography, carbon-mitigation value and competing external imports.

## Locked Results sequence

1. Cost evidence: offshore hydrogen costs do not determine export value alone.
2. Domestic absorption evidence: power-gas constraints create exportable offshore surplus.
3. Integrated trade evidence: cross-border hydrogen/ammonia trade reallocates carbon-mitigation value.
4. Diagnostic counterfactual: LCOH-only allocation misidentifies strategic exporters.
5. Robustness boundary: external import prices define the threshold for European offshore supply.

## Locked main figure roles

| Figure | Role in the argument | Main message |
|---|---|---|
| Fig. 1 | Spatial cost and wind-resource setup | Ireland and the UK have strong wind resources, but resource quality alone does not make them the lowest-LCOH producers. |
| Fig. 2 | Country cost-supply evidence | Cost-supply curves show that offshore hydrogen competitiveness changes with year, country and deployed capacity. |
| Fig. 3 | Cost-rank comparison | Average LCOH, marginal LCOH and blue-hydrogen-competitive capacity produce different country rankings. |
| Fig. 4 | Domestic operation mechanism | Export access reduces Ireland's offshore wind curtailment in the hourly power-gas model. |
| Fig. 5 | Europe-wide export-potential bridge | Domestic absorption leaves uneven exportable surplus, with the UK and Ireland becoming high-surplus systems by 2050. |
| Fig. 6 | Main trade and carbon-mitigation result | Integrated hydrogen/ammonia flows reallocate carbon-mitigation value across Europe. This is the restored original final main figure. |
| Fig. 7 | Diagnostic, not a replacement figure | A lowest-LCOH-only allocation selects different leading exporters and proves why the integrated model is needed. |
| Fig. 8 | Robustness and boundary condition | The UK/Ireland export conclusion depends on the delivered price of competing external low-carbon imports. |

## Figure revision rule

Original figures are the baseline. Future figure work should either improve the existing figure in place or add clearly superior information. Do not remove, demote or replace original main figures unless the user explicitly approves the replacement after seeing the alternative.

## Remaining work before submission

### Priority 1: make the strong novelty claim defensible

- Keep the novelty strong, but make the evidence explicit.
- Add or finalize the feature-comparison argument showing why this is the first integrated European-scale assessment linking:
  - offshore hydrogen cost-supply curves
  - hourly domestic power-gas absorption
  - cross-border hydrogen/ammonia shipping
  - external import competition
  - LCOH-only counterfactual
  - carbon-mitigation attribution
- The likely fix is a short main-text sentence plus a Supplementary Table.

### Priority 2: align SI with the current main story

- Ensure SI sections match the current eight-figure main sequence.
- Add precise SI support for the Ireland-to-Europe domestic absorption extrapolation.
- Add or verify SI material for:
  - LCOH-only counterfactual definition
  - outside-option price scan
  - domestic absorption sensitivity
  - carbon-mitigation accounting
  - Gurobi/MILP trade model details

### Priority 3: make all headline numbers auditable

- Verify every headline number in Abstract, Results and Discussion against `results/tables/`.
- Export source-data CSVs for every main figure where the current source is only a large checkpoint or workbook.
- Update `NC_source_data_inventory.csv` until every main display has either an available source table or a documented repository route.

### Priority 4: improve original figures without replacing them

- Improve Fig. 1, Fig. 2, Fig. 4, Fig. 5 and Fig. 6 only on top of the restored original design.
- Priorities:
  - readability of dense labels and legends
  - figure-internal font consistency
  - line and color clarity
  - caption and panel-letter consistency
- Do not move original main figures to SI unless explicitly approved.

### Priority 5: submission package preflight

- Run a claim-evidence audit against title, abstract, introduction, Results topic sentences and Discussion.
- Run a citation/reference audit for placeholder references, missing DOI information and citation drift.
- Finalize Data Availability and Code Availability statements with repository/DOI wording.
- Prepare Nature Communications submission materials:
  - cover letter
  - author contributions
  - competing interests
  - funding/acknowledgements
  - AI-use disclosure if required
  - related/preprint disclosure if relevant
- Rebuild and visually inspect the final PDF and SI PDF.

## Current readiness judgement

The current framework is sound and should be preserved. The manuscript is not yet submission-ready because SI alignment, source-data audit, citation hygiene, and final figure/readability QA still need to be completed.
