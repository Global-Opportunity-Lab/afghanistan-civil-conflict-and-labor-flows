# Estimation Pipeline

This folder contains all R scripts needed to reproduce the results in:

> Xiao Hui Tai, Suraj R. Nair, Shikhar Mehra, and Joshua E. Blumenstock.
> *Satellite and Mobile Phone Data Reveal How Violence Affects Seasonal Migration in Afghanistan.*

The scripts require access to the full CDR and satellite datasets, which are not publicly available due to confidentiality restrictions. A self-contained demo using sample data is in `code/demo/`.

---

## Setup

Before running any script, open `config.R` and set the four root directory variables at the top to match your environment:

```r
WORK_ROOT <- "/home/path_to_dir"           # analysis working directory
CDR_ROOT  <- "/data/cdr"               # SPECIFY CDR/displacement-metrics data tree
SAT_ROOT  <- "/data/afg_satellite"          # satellite data tree
TMP_ROOT  <- "/data/tmp"              # scratch directory for agrPixels
```

All other paths in `config.R` are derived from these four. Every estimation script calls `source("config.R")` at the top, so no other path changes are needed. Run all scripts with `code/estimation/` as the working directory.

---

## Execution Order

Scripts are numbered to reflect their intended execution order.

### Stage 1 — Data preparation (run in sequence)

| Script | Output | Description |
|---|---|---|
| `1a_covariates.R` | `COVARIATES_RDS` | Builds district-year covariates panel: area, poppy cultivation, SIGAR control scores, conflict exposure |
| `1b_bestDates.R` | `BEST_DATES_SAT`, `AG_HECTARES_RDS` | Identifies peak NDVI dates per district-year from satellite imagery; computes agricultural pixel counts |
| `1c_makeDailyPanel.R` | `DD_OUTCOMES_RDS`, `DD_OUTCOMES_OUT_RDS`, `K30_INMIG_RDS`, `K30_IMPACTED_RDS`, `K30_OUTMIG_RDS` | Aggregates raw k=30 CDR files into daily in- and out-migration panels |
| `1d_makeRegPanel.R` | `INMIG_OUTCOME_RDS`, `RESULTS_INMIG_RDS`, `DIST_YEARS_RDS`, `VIOLENCE_DEST_RDS` | Runs daily district-level regressions; extracts peak excess in-migration and conflict exposure around harvest |
| `1e_makeSourcePanel.R` | Subgroup results/outcomes (`SUBGROUP_HVT_BASE`, etc.) | Repeats 1d regressions separately for source-district subgroups (high-poppy × violence × Taliban presence) |



### Stage 2 — Supplementary data prep (run before their dependent table scripts)

| Script | Output | Needed by |
|---|---|---|
| `4a_dataPrep_tables.R` | Robustness-check outcomes (1–45 day window, 14-day rolling mean, return-migration variants, ±14-day shift) | `4c_tablesS1-3.R` |
| `4b_dataPrep2_tables.R` | k=15 and k=45 reference-period outcomes | `4c_tablesS1-3.R` |
| `randomizationInference.R` | Per-permutation RDS files in `RANDOM_DIR` | `3c_figS4.R` |
| `5a_figS12_dataprep.py` | `VIOLENCE_ROAD_CSV` | Road-conflict proximity analysis; identifies ACLED events near road networks in the pre-harvest window |
| `3bb_fig_S3_data_prep.py` | `figS3_landsat_modis_top10.csv` | Downloads MODIS and Landsat NDVI imagery via GEE; computes modal peak-NDVI date per district-year for Figure S3 validation |

`randomizationInference.R` is designed to be called from the command line with a numeric argument (0–249) and can be parallelized across jobs. Run all 250 permutations before running `3c_figS4.R`.


### Stage 3 — Figures

| Script | Output file(s) | Paper figure |
|---|---|---|
| `2a_fig1.R` | `8-1-23outcomek30ByDistrict_2407_noViolence.pdf` | Figure 1 |
| `2b_fig2.R` | `8-1-23fig2a.pdf`, `1-9-24fig2c.pdf`, `1-12-24fig2d.pdf` | Figure 2 |
| `2c_fig3.R` | `1-9-24fig3a.pdf`, `10-24-23fig3b.pdf` | Figure 3 |
| `2d_fig4.R` | `1-12-24fig4a.pdf`, `1-9-24fig4b.pdf`, `1-9-24fig4c.pdf` | Figure 4 |
| `2e_fig5.R` | `1-10-24fig5a.pdf`, `1-10-24fig6b_2020.pdf` | Figure 5 |
| `3a_figS1.R` | `10-13-23map.pdf` | Figure S1 |
| `3b_figS2.R` | `agrTimelineDates.pdf`, `agrTimelineViz_blank.pdf` | Figure S2 |
| `3c_figS4.R` | `randomNDVI.pdf` | Figure S4 |
| `3d_figS5.R` | `9-26-23twoWayEDA.pdf` | Figure S5 |
| `3e_figS6.R` | `1-10-24figA2.pdf` | Figure S6 |
| `3f_figS7.R` | `1-10-24fig3b_robust.pdf` | Figure S7 |
| `3g_figS8.R` | `1-10-24fig3b_post2017.pdf`, `1-10-24fig3b_robust2.pdf` | Figure S8 |
| `3h_figS9.R` | `12-14-23fig3b_violenceDef.pdf` | Figure S9 |
| `3i_figS10.R` | `1-10-24fig4c_robust.pdf` | Figure S10 |
| `5a_figS12_dataprep.py` | (see Stage 2) | Figure S12 — run data prep first |
| `5a_figS12.R` | `10-24-23fig3b_alt.pdf` | Figure S12 |
| `6a_figS13.R` | `ODmatrix.pdf` | Figure S13 |

### Stage 4 — Tables

| Script | Output | Paper table |
|---|---|---|
| `4c_tablesS1-3.R` | LaTeX via `stargazer` to console/file | Tables S1–S3 |
| `6b_tablesS4-6.R` | LaTeX via `stargazer` to console/file | Tables S4–S6 |

---

## Key files

| File | Purpose |
|---|---|
| `config.R` | Central path configuration — edit the four root variables before running anything |

