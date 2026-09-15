# NC Data Availability Audit

Date: 2026-06-18

Target journal: Nature Communications.

## Policy-Relevant Requirements

Nature Portfolio requires original research articles to include a Data availability statement that makes the minimum dataset needed to interpret, verify and extend the work transparent. Large datasets should preferably live in public repositories rather than supplementary files, and custom code central to the conclusions should have a clear Code availability statement. A DOI-minted archive is strongly preferable for the version of record.

## Current Package

Current status: draft_with_placeholders.

Strengths:

- The GitHub repository contains the manuscript, MATLAB code, main figure PDFs, and all lightweight CSV result tables currently used for the NC revision.
- `results/tables/NC_headline_numbers.csv` traces headline manuscript values.
- Counterfactual, outside-option, and domestic-absorption sensitivity results have compact CSV files that can serve as source data.
- Large raw files and large intermediate checkpoints are excluded from Git, which is appropriate for repository usability.

Gaps:

- No DOI-minted repository snapshot exists yet.
- Fig. 1-5 and the Sankey/trade matrix still depend on large checkpoints or large geospatial/climate arrays rather than lightweight source-data CSV exports.
- The final Data availability statement should name the DOI or persistent URL after archival.
- Public input datasets are cited in the manuscript/SI, but a single data-source route table would make the package easier for reviewers to inspect.

## Ready-To-Paste Data Availability Draft

The public datasets reused in this study are cited in the References and described in the Methods and Supplementary Information. Derived source-data tables supporting the main counterfactual, outside-option sensitivity, domestic-absorption sensitivity, carbon-mitigation accounting and headline numerical claims are provided in the project repository under `results/tables/`, with source-data coverage summarized in `results/tables/NC_source_data_inventory.csv`. Final figure files are provided under `manuscript/main/figs/`. Large public raw climate, bathymetry and geospatial inputs and large intermediate MATLAB checkpoint files are not redistributed through GitHub because of file-size constraints; the raw inputs are available from the cited public data providers and the checkpoints can be regenerated from the provided MATLAB code. A DOI-minted archive of the version used for publication will be added before final submission/publication.

## Ready-To-Paste Code Availability Draft

MATLAB code used in this study is available on GitHub at `https://github.com/ShengWang-EE/HyExport`. The version used for publication should be archived in a DOI-minting repository before final submission/publication, and the DOI should be added to this statement.

## Next Data Tasks

1. Export source-data CSV files for Fig. 1-5 and Fig. 7/Sankey.
2. Add a public-input dataset inventory with provider, cited reference, local path and redistribution status.
3. Create a GitHub release and Zenodo/Figshare/institutional repository archive.
4. Replace the publication-archive placeholder with the real DOI or persistent URL.
