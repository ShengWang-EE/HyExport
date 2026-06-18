# Data Availability And Source Data Plan

Date: 2026-06-18

This file records the current data-sharing plan for the Nature Communications manuscript package.

## Current Status

Status: draft_with_placeholders

The repository now contains the manuscript, MATLAB source code, final figure PDFs, and lightweight derived result tables that support the main counterfactual, outside-option sensitivity, domestic-absorption sensitivity, and headline-number claims. The remaining submission-facing gap is a DOI-minted archive for the version of record and lightweight source-data exports for the older LCOH/map figures whose underlying arrays still live mainly in large MATLAB checkpoints or large public geospatial/climate inputs.

## Data Routes

| Dataset family | Current location | Access route | Submission status |
|---|---|---|---|
| Main manuscript text and compiled PDF | `manuscript/` | GitHub repository | Available |
| MATLAB code | `main.m`, `scripts/`, `src/`, `setupHyExport.m` | GitHub repository | Available; DOI archive still needed |
| Main figure PDFs | `manuscript/figs/` | GitHub repository | Available |
| Headline result numbers | `results/tables/NC_headline_numbers.csv` | GitHub repository | Available |
| Counterfactual source data | `results/tables/NC_story_comparison.csv`, `results/tables/NC_story_comparison_country.csv` | GitHub repository | Available |
| Outside-option sensitivity source data | `results/tables/NC_outside_option_sensitivity.csv`, `results/tables/NC_outside_option_sensitivity_country.csv` | GitHub repository | Available |
| Domestic-absorption sensitivity source data | `results/tables/NC_domestic_absorption_sensitivity.csv`, `results/tables/NC_domestic_absorption_sensitivity_country.csv` | GitHub repository | Available |
| Source-data coverage inventory | `results/tables/NC_source_data_inventory.csv` | GitHub repository | Available |
| Large public raw climate and bathymetry files | `data/raw/` locally, with large files ignored by Git | Reused public data sources cited in the manuscript and SI | Not redistributed through GitHub because of size |
| Large intermediate MATLAB checkpoints | `results/checkpoints/` locally, with large files ignored by Git | Regenerable from public inputs and code | Not required as source data if lightweight exports are completed |

## Files Intentionally Not Tracked In Git

The repository excludes large files through `.gitignore`, including:

- `*.nc`
- large country bathymetry `.mat` files
- `results/checkpoints/`
- large EEZ map shapefiles under `map/Europe/EEZ/`

These exclusions keep the GitHub repository usable. For final submission, the preferred route is to archive the code, derived source-data CSV files, and any non-redistributable data-fetch instructions in a DOI-minting repository such as Zenodo, Figshare or an institutional data repository. Do not invent a DOI in the manuscript until the record exists.

## Remaining Actions Before Submission

1. Export lightweight source-data files for Fig. 1-3 and any remaining main figures that still depend only on large checkpoints.
2. Create a versioned GitHub release and archive it in a DOI-minting repository.
3. Insert the DOI or persistent URL into the Data availability and Code availability statements.
4. If any reused third-party dataset cannot be redistributed, name the provider and access route explicitly in the final Data availability statement.
