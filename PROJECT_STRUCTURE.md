# HyExport Project Structure

## Entry points

- `main.m`: main analysis workflow, kept at the project root for interactive debugging.
- `setupHyExport.m`: adds `src/`, `map/`, and `matpower7.1/` to the MATLAB path and returns the project root.
- `scripts/runHyExport.m`: compatibility wrapper that runs `main.m`.
- `scripts/buildMpcIreland.m`: builds and saves the Ireland MATPOWER/Gas-Electric case.
- `scripts/plotFigures.m`: manuscript figure generation script.

## Source code

- `src/cost/`: offshore wind, hydrogen, ammonia, and cost-reduction models.
- `src/io/`: shapefile, climate, bathymetry, wind, and project file loading helpers.
- `src/optimization/`: transport optimization and gas-electric OPF model.
- `src/power/`: power-system simulation, renewable generation, turbine, and wake-effect helpers.
- `src/supply/`: offshore resource supply-curve calculations.
- `src/visualization/`: plotting utilities.
- `src/utils/`: project-root and file-resolution helpers.

## Data and outputs

- `tables/`: spreadsheet and CSV inputs.
- `map/`: shapefiles and geospatial inputs.
- `data/raw/`: loose raw data files that are not part of `tables/` or `map/`.
- `results/checkpoints/`: generated `.mat` checkpoints such as `stop1.mat`, `stop2.mat`, `stop3.mat`, and `mpcIreland.mat`.
- `results/figures/`: loose figure outputs moved from the project root.
- `figs/`: manuscript figure outputs used by the plotting script.
- `archive/legacy/`: older copied scripts and machine-specific variants.
- `archive/autosaves/`: MATLAB `.asv` autosave files.
