# Paper Figures and Tables

This folder contains the scripts and data needed to reproduce all figures and tables in:

> Xiao Hui Tai, Suraj R. Nair, Shikhar Mehra, and Joshua E. Blumenstock.
> *Satellite and Mobile Phone Data Reveal How Violence Affects Seasonal Migration in Afghanistan.*

All scripts must be run with `code/` as the working directory.

---

## Quick start

Run everything in one command:

```bash
cd path/to/repo/code

# All R figures (fig1–fig5, figS1–figS13 except figS3 and figS11)
Rscript run_paper_figures_tables.R

# Python figures (figS3, figS11)
python3 run_paper_figures_tables.py
```

Output PDFs are written to `paper_figures_tables/output/`.

---

## Running individual scripts

```bash
cd path/to/repo/code

# R figures
Rscript paper_figures_tables/fig2.R

# Python figures
python3 paper_figures_tables/FigS3.py
python3 paper_figures_tables/FigS11.py
```

---

## Contents

### Main figures

| Script | Output | Description |
|---|---|---|
| `fig1.R` | `fig1a.pdf`, `fig1c.pdf` | MODIS pixel dates (district 2407); in/out-migration time series |
| `fig2.R` | `fig2a.pdf`–`fig2d.pdf` | Event-study and distributional migration results |
| `fig3.R` | `fig3a.pdf`, `fig3b.pdf` | Violence × Taliban interaction on in-migration |
| `fig4.R` | `fig4a.pdf`–`fig4c.pdf` | Migrant composition and source-district type effects |
| `fig5.R` | `fig5a.pdf`, `fig5b.pdf` | Eradication interaction on in-migration |

### Supplementary figures

| Script | Output | Description |
|---|---|---|
| `figS1.R` | `figS1.pdf` | District map of poppy cultivation and Taliban presence |
| `figS2.R` | `figS2.pdf` | Agricultural calendar and satellite best dates |
| `FigS3.py` | stdout (table) | MODIS–Landsat peak-date comparison for 10 validation districts |
| `figS4.R` | `figS4.pdf` | Randomization inference |
| `figS5.R` | `figS5.pdf` | Two-way EDA |
| `figS6.R` | `figS6.pdf` | Robustness: alternative outcome definition |
| `figS7.R` | `figS7.pdf` | Robustness: trimmed poppy sample |
| `figS8.R` | `figS8.pdf` | Robustness: pre- and post-2017 subsamples |
| `figS9.R` | `figS9.pdf` | Robustness: alternative violence definitions |
| `figS10.R` | `figS10.pdf` | Robustness: leave-one-year-out |
| `FigS11.py` | `figS11.pdf` | Road network buffer illustration (district 101) |
| `figS12.R` | `figS12.pdf` | Road-network violence measure |
| `figS13.R` | `figS13.pdf` | Origin-destination migration matrix |

### Supplementary tables

Tables are pre-computed from the full dataset and provided as LaTeX source in plain text files. Copy the contents directly into your document.

| File | Table |
|---|---|
| `tableS1.txt` | Table S1 — Robustness checks: alternative reference periods |
| `tableS2.txt` | Table S2 — Robustness checks: timing shifts (±14 days) |
| `tableS3.txt` | Table S3 — Return migration |
| `tableS4.txt` | Table S4 — Source district characteristics |
| `tableS5.txt` | Table S5 — Violence and Taliban interactions |
| `tableS6.txt` | Table S6 — Eradication interactions |

---

## System requirements

### R packages

Install all required packages at once:

```r
install.packages(c("ggplot2", "dplyr", "gridExtra", "tidyr", "scales",
                   "sf", "viridis", "colorspace", "knitr"))
```

| Package | Used in |
|---|---|
| `ggplot2` | All figure scripts |
| `dplyr` | All figure scripts |
| `gridExtra` | All figure scripts |
| `sf` | `fig1.R`, `figS1.R`, `figS2.R` |
| `viridis` | `figS1.R`, `figS5.R` |
| `scales` | `fig2.R`, `figS2.R` |
| `tidyr` | `fig4.R` |
| `colorspace` | `figS13.R` |
| `knitr` | `figS8.R`, `figS9.R` (LaTeX table output to stdout) |

### Python packages

We recommend using a virtual environment to keep dependencies isolated. From the repo root:

```bash
# Create and activate the virtual environment
python3 -m venv pft_env
source pft_env/bin/activate        # macOS / Linux
# pft_env\Scripts\activate          # Windows

# Install required packages
pip install geopandas matplotlib networkx numpy pandas shapely

# Run the Python figure scripts (from code/)
cd path/to/repo/code
python3 run_paper_figures_tables.py

# Deactivate when done
deactivate
```

The quick-start commands in the section above assume the virtual environment is already activated.

| Package | Used in |
|---|---|
| `geopandas` | `FigS11.py` |
| `matplotlib` | `FigS11.py` |
| `networkx` | `FigS11.py` |
| `numpy` | `FigS3.py` |
| `pandas` | `FigS3.py`, `FigS11.py` |
| `shapely` | `FigS11.py` |

---

## Data

Input data live in `data/`. Most files are pre-computed from the full estimation pipeline; the provenance of each file is documented in `estimation/fig*_replication_dataprep.R`.

| File | Used by | Description |
|---|---|---|
| `fig1a.rds` | `fig1.R` | MODIS pixel-level best dates for district 2407 |
| `fig1c.RData` | `fig1.R` | In/out-migration time series + conflict events for district 2407 |
| `fig2.Rdata` | `fig2.R` | Event-study estimates and distributional outcomes |
| `fig3.Rdata` | `fig3.R` | Regression outcomes with violence and Taliban indicators |
| `fig4.Rdata` | `fig4.R` | Migrant composition and source-district regression estimates |
| `fig5.Rdata` | `fig5.R` | Eradication regression outcomes |
| `figS1.Rdata`–`figS13.Rdata` | `figS*.R` | Pre-computed model results for each supplementary figure |
| `figS3_landsat_modis_top10.csv` | `FigS3.py` | MODIS–Landsat peak-date comparison (10 districts) |
| `figS11_afg_road_network.geojson` | `FigS11.py` | Road network near district 101 |
| `district398.geojson` | `fig1.R`, `FigS11.py` | Afghan district polygons |
| `violenceDest_2020.rds` | (loaded via figS*.Rdata) | Violence events at destination districts |
