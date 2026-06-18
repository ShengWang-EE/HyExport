# NC Headline Number Audit

Date: 2026-06-18

Purpose: make the manuscript's headline numerical claims auditable from derived result tables without requiring a reviewer to inspect MATLAB checkpoint variables.

Primary source table: `results/tables/NC_headline_numbers.csv`.

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
