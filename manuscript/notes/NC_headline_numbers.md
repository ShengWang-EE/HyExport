# NC Headline Number Audit

Date: 2026-06-19

Purpose: make the manuscript's headline numerical claims auditable from derived result tables without requiring a reviewer to inspect MATLAB checkpoint variables.

Primary source table: `results/tables/NC_headline_numbers.csv`.

Auxiliary source tables added in this pass:

- `results/tables/NC_lcoh_rank_table.csv`: Fig. 3 cost-rank values exported from `tables/tables.xlsx`, sheet `cost table`.
- `results/tables/NC_ireland_curtailment_summary.csv`: Ireland seasonal curtailment values used in the domestic-absorption Results text.
- `results/tables/NC_domestic_export_potential.csv`: country-year decomposition values from `EUwindConsump_new`, including available export potential.

## Carbon-Mitigation Accounting

The main manuscript now separates two related but different quantities:

| Quantity | 2030 | 2040 | 2050 | Source |
|---|---:|---:|---:|---|
| Total carbon mitigation in the integrated supply mix (Mt CO2 yr^-1) | 43.5 | 129.8 | 175.5 | `NC_story_comparison.csv`, `TotalCarbonReduction_Mt` |
| European offshore supplier contribution (Mt CO2 yr^-1) | 43.5 | 103.2 | 158.3 | `NC_story_comparison.csv`, `EuropeanOffshoreCarbonContribution_Mt` |
| External import flow (TWh yr^-1) | 0.0 | 116.2 | 62.2 | `NC_story_comparison.csv`, `InternationalImport_TWh` |

The difference between total mitigation and European offshore contribution appears when the external import node contributes to meeting demand. The manuscript should therefore not describe the 2050 value of 175.5 Mt CO2 yr^-1 as the contribution from the 11 European offshore supplier countries alone.

## Code Path

- `src/optimization/optimalTransportation.m`: builds `carbonReductionContributionMatrix`.
- `scripts/analysis/runLCOHOnlyCounterfactual.m`: writes `NC_story_comparison.csv`.
- `scripts/analysis/runOutsideOptionSensitivity.m`: writes outside-option sensitivity carbon and supply values.
- `scripts/analysis/runDomesticAbsorptionSensitivity.m`: writes domestic-absorption sensitivity values.

## Manuscript Rule

Use "total mitigation" for sums over all rows of `carbonReductionContributionMatrix`, including the external import row. Use "European offshore supplier contribution" only for sums over the 11 modelled European supplier-country rows.

## 2026-06-19 Headline-Number Check

The following manuscript-facing numbers were checked against lightweight source tables or directly exported checkpoint summaries:

| Claim group | Manuscript values | Source |
|---|---:|---|
| Ireland/UK marginal LCOH in 2030 | 76.10 and 79.02 EUR MWh^-1 | `NC_lcoh_rank_table.csv` |
| Ireland/UK marginal LCOH in 2050 | 54.42 and 52.51 EUR MWh^-1 | `NC_lcoh_rank_table.csv` |
| Ireland no-export curtailment | summer 62.36% to 69.80%; winter 32.05% to 13.47% | `NC_ireland_curtailment_summary.csv` |
| Ireland 2050 summer curtailment with export | 10.46% | `NC_ireland_curtailment_summary.csv` |
| Country export-potential screen | UK 176/195/263 TWh yr^-1; Ireland 16/87/170 TWh yr^-1; Netherlands 64/155 TWh yr^-1; Denmark 30 TWh yr^-1 in 2030 | `NC_domestic_export_potential.csv` |
| Integrated trade ranks and net exports | UK 78/122/162 TWh yr^-1; Ireland 14/83/162 TWh yr^-1; Denmark 118 TWh yr^-1 in 2050 | `NC_story_comparison_country.csv` |
| LCOH-only counterfactual | top net exporters DK 44, NL 147 and DK 171 TWh yr^-1 | `NC_story_comparison.csv` |
| Outside-option threshold | 2050 imports 818, 721 and 63 TWh yr^-1 at 2, 3 and 4 EUR kg^-1 H2-equivalent | `NC_outside_option_sensitivity.csv` |

No headline value in the current main manuscript failed this pass. The wording distinction that still matters most is `available export potential` versus optimised `net export`.

## Remaining Source-Data Gaps

1. Fig. 2 LCOH curves are restored from the original PDF because the current local `stop3.mat` changes the Norway curve and no longer matches the manuscript values. Before final repository archival, recover the matching original checkpoint or export the original curve points to CSV.
2. Fig. 1 map surfaces and Fig. 6 full flow/carbon matrices still need full source-data export if Nature requests panel-level source data. The headline numbers are covered, but the plotted dense matrices are not yet fully represented as lightweight CSVs.
3. Fig. 4 now has text-level curtailment source data, but full hourly dispatch traces remain checkpoint-backed.
