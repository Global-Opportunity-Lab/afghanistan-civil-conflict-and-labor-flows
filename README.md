# afghanistan-civil-conflict-and-labor-flows

This repository contains code and data necessary to replicate the findings of the paper:

Xiao Hui Tai, Suraj R. Nair, Shikhar Mehra, and Joshua E. Blumenstock. Satellite and Mobile Phone Data Reveal How Violence Affects Seasonal Migration in Afghanistan.

This work is licensed under the Apache License, Version 2.0.

# Instructions
One of the main datasets for the paper contains detailed information on over 20 billion mobile phone transactions in Afghanistan. These data contain proprietary and confidential information belonging to a major telecommunications operator, which we do not have permission to release.

However, all the code required to process the data and produce the results are in the following folders (these cannot be run without data access):

- `home_location_detector`: Python notebooks to infer each subscriber's daily home location from raw CDR (Steps 1–3)
- `displacement-metrics`: Python notebooks and scripts to compute migration metrics from the inferred home locations
- `best_dates`: Python notebooks to generate peak-NDVI best dates and agricultural land masks from MODIS via Google Earth Engine
- `estimation`: R scripts to create the analysis dataset and produce all results; also contains Python scripts for data preparation (`3bb_fig_S3_data_prep.py`, `5a_figS12_dataprep.py`)

The following scripts can be run, and do not require data access:

- `paper_figures_tables`: Scripts to produce main and supplementary figures / tables. 

# Full estimation pipeline

Users with access to the full CDR and satellite datasets can run the complete estimation pipeline in `code/estimation/`. Before running any script, edit the four root path variables at the top of `code/estimation/config.R` to match your environment:

```r
WORK_ROOT <- "/path/to/your/working/directory"
CDR_ROOT  <- "/path/to/cdr/data"
SAT_ROOT  <- "/path/to/satellite/data"
TMP_ROOT  <- "/path/to/scratch/directory"
```

All R scripts call `source("config.R")` and derive every other path from these four variables. See `code/estimation/README.md` for the full execution order and a description of each script's inputs and outputs.

The full estimation pipeline was run on a server with the following specs: 
OS: Rocky Linux 8.10 (Green Obsidian), Kernel 4.18.
CPU: Intel Xeon Silver 4214R @ 2.40GHz (up to 3.5GHz turbo), 24 cores and 754 GB RAM

The home location detection pipeline takes 3-4 days to run completely on the full CDR data from 2013 - 2020.
The satellite imagery pipeline is similarly time consuming. 

# Python pipeline

Users with access to the full CDR and satellite datasets must run the Python pipeline before the R estimation scripts. Each notebook reads `CDR_ROOT`, `TMP_ROOT`, and/or `SAT_ROOT` from a config cell at the top — set these to match your environment before running.

## Home location detection

Run in order:

| Script | Input | Output |
|---|---|---|
| `home_location_detector/Step1.compute_daily_modal_location.ipynb` | Raw CDR files + tower lookup | Daily modal location per subscriber (`DAILY_MODAL_RAW_DIR`) |
| `home_location_detector/Step2.restructure_daily_modal_for_home_detector.ipynb` | Step 1 output | Daily modal locations bucketed by subscriber hash prefix (`DAILY_MODAL_BUCKETED_DIR`) |
| `home_location_detector/Step3.infer_home_location.ipynb` | Step 2 output | Inferred daily home locations (`HOME_LOCATIONS_DIR`) |

## Migration metrics

Run after home location detection:

| Script | Input | Output |
|---|---|---|
| `displacement-metrics/compute_visits_per_district_day.ipynb` | Home locations (all files loaded at once) | Visit matrices aggregated to district-day level (`VISITS_OUT_DIR`) |
| `displacement-metrics/compute_visits_per_district_day_in_small_sets.ipynb` | Home locations (one file at a time, Dask-parallelised) | Same output as above, split into intermediate files before aggregation (`VISITS_TEMP_DIR`) |
| `displacement-metrics/mig_stats.py` | Home locations | District-day migration statistics: in-migrants, stays, returns (`MIG_STATS_CSV`) |
| `displacement-metrics/count_unique_users_and_calls.ipynb` | Home locations + raw CDR | Summary counts (unique users, total calls) — for reporting only |

## Satellite best dates (Google Earth Engine)

These scripts query MODIS and Landsat via the Earth Engine Python API and can be run independently of the CDR pipeline:

| Script | Output |
|---|---|
| `best_dates/PoppyBestDatesGeneration.ipynb` | Peak NDVI date per pixel-year (`PIXEL_MAXDATA_DIR`) |
| `best_dates/bestDatesM2_AgrYN.ipynb` | Agricultural land indicator per pixel-year (`AGR_YN_DIR`) |
| `estimation/3bb_fig_S3_data_prep.py` | MODIS–Landsat peak-date comparison for 10 validation districts (`figS3_landsat_modis_top10.csv`) |

## Estimation scripts

After running the home location detection and migration metrics steps above, run all scripts in `code/estimation/` as described in `code/estimation/README.md`.

### Disclaimer
All scripts were written without the use of AI. While the code was checked for correctness, comments and documentation may be lacking in some places. Please contact the authors with any clarifications. 

# Paper figures and tables

The `paper_figures_tables` folder contains scripts and pre-computed full-data outputs to reproduce every figure and table in the paper exactly.

The README.md file in the folder has further details about each script. 

## Setup

**R packages** — install once in R:

```r
install.packages(c("ggplot2", "dplyr", "gridExtra", "tidyr", "scales",
                   "sf", "viridis", "colorspace", "knitr"))
```

**Python packages** — create a virtual environment in the repo root, then install:

```bash
python3 -m venv pft_env
source pft_env/bin/activate          # macOS / Linux
# pft_env\Scripts\activate           # Windows
pip install -r code/requirements_paper_figures_tables.txt
```

## Running

With the virtual environment active, run from the `code/` directory:

```bash
cd path/to/repo/code

Rscript run_paper_figures_tables.R      # all R figures
python3 run_paper_figures_tables.py     # FigS3 (stdout) and FigS11
```

PDFs are written to `paper_figures_tables/output/`. Supplementary tables are provided as text files in `paper_figures_tables/tableS*.txt`. See `paper_figures_tables/README.md` for a full inventory of scripts, outputs, and data files.

# System requirements

## R packages

The table below lists all R packages used across the paper figures scripts and the full estimation pipeline.

| Package | Used in | Purpose |
|---|---|---|
| `dplyr` | Paper figures + estimation | Data manipulation |
| `ggplot2` | Paper figures + estimation | Figures |
| `gridExtra` | Paper figures + estimation | Multi-panel figure layout |
| `scales` | Paper figures + estimation | Axis formatting |
| `tidyr` | Paper figures + estimation | Data reshaping |
| `lmtest` | Paper figures + estimation | Clustered standard errors |
| `sandwich` | Paper figures + estimation | Variance-covariance matrices |
| `stargazer` | Estimation only | Regression tables |
| `sf` | Paper figures + estimation | Spatial data |
| `viridis` | Paper figures + estimation | Color palettes |
| `colorspace` | Estimation only | Color palettes |
| `knitr` | Estimation only | Table formatting |
| `lubridate` | Estimation only | Date arithmetic |

Install all packages at once:

```r
install.packages(c("dplyr", "ggplot2", "gridExtra", "scales", "tidyr",
                   "lmtest", "sandwich", "sf", "viridis", "lubridate",
                   "stargazer", "colorspace", "knitr"))
```

## Python packages

Different parts of the Python pipeline have different dependencies. Install all at once with:

```bash
pip install dask[distributed] earthengine-api geopandas matplotlib networkx numpy pandas \
            rasterio rioxarray shapely
```

| Package | Used in | Purpose |
|---|---|---|
| `dask[distributed]` | Home location detection, displacement metrics | Parallel processing of large CDR files |
| `earthengine-api` | Best dates, `3bb_fig_S3_data_prep.py`, `FigS3.py` | Google Earth Engine Python API (`ee`) |
| `geopandas` | Home location detection, best dates, road conflict | Spatial dataframes |
| `matplotlib` | `5a_figS12_dataprep.py`, `FigS11.py` | Figure S11/S12 map output |
| `networkx` | Road conflict analysis | Road network graph operations |
| `numpy` | Throughout | Array operations |
| `pandas` | Throughout | Tabular data |
| `rasterio` | `3bb_fig_S3_data_prep.py`, `FigS3.py` | GeoTIFF I/O and raster merging |
| `rioxarray` | `3bb_fig_S3_data_prep.py`, `FigS3.py` | Raster I/O via xarray (`rxr`) |
| `shapely` | Road conflict analysis, best dates | Geometry objects |

Scripts that use Google Earth Engine (`best_dates/` notebooks, `3bb_fig_S3_data_prep.py`, and `FigS3.py`) require a GEE account. Authenticate once with:

```bash
earthengine authenticate
```

## Software and hardware

- R version 4.0 or higher (tested on R 4.5)
- Python 3.8 or higher
- No non-standard hardware required for the R pipeline; the CDR processing notebooks (`home_location_detector/`, `displacement-metrics/`) were run on a server with 16–32 cores and 256 GB RAM
