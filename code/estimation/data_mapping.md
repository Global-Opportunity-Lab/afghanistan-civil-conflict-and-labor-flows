# Data Path Mapping

This document maps every hardcoded file path that appeared in the original estimation scripts to the corresponding `config.R` variable. Each section covers one script.

All scripts now begin with `source("config.R")`. To run on a new machine, edit the four root variables at the top of `config.R`:
- `WORK_ROOT` — analysis working directory on the compute server
- `CDR_ROOT` — root of the CDR/displacement-metrics data tree
- `SAT_ROOT` — root of the satellite data tree
- `TMP_ROOT` — scratch directory for `agrPixels`

---

## `config.R`

New file. Defines all path variables derived from four root directories. No hardcoded paths were replaced here; this file *is* the replacement.

---

## `1a_covariates.R`

| Original hardcoded path | Config variable |
|---|---|
| `/data/afg_anon/displacement_analysis/district_ids_with_info.rds` | `DISTRICT_IDS` |
| `/home/xtai/climate/data/poppy_1994-2020.csv` | `POPPY_CSV` |
| `/home/xtai/climate/data/7-14-22agHectares.rds` | `AG_HECTARES_RDS` |
| `/data/afg_satellite/xtai/afghanShapeAllInfo.Rdata` | `AFG_SHAPE_DATA` |
| `/home/xtai/tmp/agrPixels.Rds` | `AGR_PIXELS` |
| `/data/afg_anon/displacement_analysis/SIGARcontrol.csv` | `SIGAR_CSV` |
| `saveRDS(..., "/home/xtai/climate/3-8-23migrationCleanCode/output/3-13-23covariates.rds")` | `COVARIATES_RDS` |

---

## `1b_bestDates.R`

| Original hardcoded path | Config variable |
|---|---|
| `system("ls /data/afg_satellite/bestdates/pixel_maxdata_real_June/")` | `system(paste0("ls ", PIXEL_MAXDATA_DIR, "/"))` |
| `read.csv(paste0(".../pixel_maxdata_real_June/", fileList[i]))` | `read.csv(file.path(PIXEL_MAXDATA_DIR, fileList[i]))` |
| `read.csv(paste0(".../agrYN/", fileList[i]))` | `read.csv(file.path(AGR_YN_DIR, fileList[i]))` |
| `sf::st_read("/data/afg_satellite/shp/district398/district398.shp")` | `sf::st_read(DISTRICT_SHP)` |
| `saveRDS(outFile, ".../4-25-22agrBestDates_withDistIDs.rds")` | `AGR_BEST_DATES_RDS` |
| `readRDS(".../4-25-22agrBestDates_withDistIDs.rds")` | `AGR_BEST_DATES_RDS` |
| `readRDS(".../4-25-22agrBestDates_withDistIDs_NDVI.rds")` | `AGR_BEST_DATES_NDVI_RDS` |
| `saveRDS(bestDates, ".../6-22-22bestDatesLong_M4.rds")` | `BEST_DATES_SAT` |
| `readRDS(".../6-22-22bestDatesLong_M4.rds")` | `BEST_DATES_SAT` |
| `write.csv(..., ".../6-22-22bestDatesLong_M4.csv")` | `BEST_DATES_SAT_CSV` |
| `saveRDS(agHectaresLong, ".../7-14-22agHectares.rds")` | `AG_HECTARES_RDS` |

---

## `1c_makeDailyPanel.R`

| Original hardcoded path | Config variable |
|---|---|
| `list.files(".../time_delta_30_days/")` | `list.files(CDR_K30_DIR)` |
| `read.csv(paste0(".../time_delta_30_days/", fileList[1]))` | `read.csv(file.path(CDR_K30_DIR, fileList[1]))` |
| `read.csv(paste0(".../time_delta_30_days/", fileList[i]))` (loop) | `read.csv(file.path(CDR_K30_DIR, fileList[i]))` |
| `read.csv(paste0(".../time_delta_30_days/impact_day_2000.csv"))` | `read.csv(file.path(CDR_K30_DIR, "impact_day_2000.csv"))` |
| `saveRDS(outData, ".../k30_inMigration_homeDetector_2020.rds")` | `K30_INMIG_RDS` |
| `saveRDS(getImpacted, ".../impacted_homeDetector_2020.rds")` | `K30_IMPACTED_RDS` |
| `readRDS(".../6-22-22bestDatesLong_M4.rds")` (two occurrences) | `BEST_DATES_SAT` |
| `readRDS(".../k30_inMigration_homeDetector_2020.rds")` | `K30_INMIG_RDS` |
| `readRDS(".../impacted_homeDetector_2020.rds")` | `K30_IMPACTED_RDS` |
| `saveRDS(ddOutcomes, ".../6-5-23ddOutcomes_2020.rds")` | `DD_OUTCOMES_RDS` |
| `saveRDS(outData, ".../k30_outMigration_homeDetector_2020.rds")` | `K30_OUTMIG_RDS` |
| `readRDS(".../k30_outMigration_homeDetector_2020.rds")` | `K30_OUTMIG_RDS` |
| `saveRDS(ddOutcomes, ".../7-31-23ddOutcomes_out_2020.rds")` | `DD_OUTCOMES_OUT_RDS` |

---

## `1d_makeRegPanel.R`

| Original hardcoded path | Config variable |
|---|---|
| `readRDS(".../6-5-23ddOutcomes_2020.rds")` | `DD_OUTCOMES_RDS` |
| `saveRDS(tmpOut, ".../6-5-23results_inMigration_2020.rds")` | `RESULTS_INMIG_RDS` |
| `saveRDS(distYears, ".../6-5-23distYearsIncluded_2020.rds")` | `DIST_YEARS_RDS` |
| `readRDS(".../6-5-23results_inMigration_2020.rds")` | `RESULTS_INMIG_RDS` |
| `saveRDS(newResponse, ".../6-5-23inMigRegOutcome_2020.rds")` | `INMIG_OUTCOME_RDS` |
| `readRDS(".../10-25-22results2014_in_LPM_bestDatesM4_homeDetctor.rds")` | `LEGACY_RESULTS2014` |
| `readRDS(".../6-22-22bestDatesLong_M4.rds")` | `BEST_DATES_SAT` |
| `read.csv("/data/afg_satellite/Conflict_district.csv")` | `CONFLICT_CSV` |
| `saveRDS(newViolence, ".../6-5-23violenceDest_2020.rds")` | `VIOLENCE_DEST_RDS` |

---

## `1e_makeSourcePanel.R`

| Original hardcoded path | Config variable |
|---|---|
| `readRDS(".../3-13-23covariates.rds")` | `COVARIATES_RDS` |
| `read.csv("/data/afg_anon/displacement_analysis/SIGARcontrol.csv")` | `SIGAR_CSV` |
| `read.csv("/data/afg_satellite/Conflict_district.csv")` | `CONFLICT_CSV` |
| `list.files(".../time_delta_30_days/")` | `list.files(CDR_K30_DIR)` |
| `read.csv(paste0(".../time_delta_30_days/", fileName))` | `read.csv(file.path(CDR_K30_DIR, fileName))` |
| `readRDS(".../6-22-22bestDatesLong_M4.rds")` | `BEST_DATES_SAT` |
| `saveRDS(ddOutcomes, ".../6-5-23ddOutcomes_violence_HNL_T_2020.rds")` | `DD_OUTCOMES_VIOLENCE_RDS` |
| `readRDS(".../6-5-23ddOutcomes_violence_HNL_T_2020.rds")` (×4) | `DD_OUTCOMES_VIOLENCE_RDS` |
| `saveRDS(tmpOut, paste0(".../6-5-23results_H_V_T", suffix, "_2020.rds"))` | `paste0(RESULTS_HVT_BASE, suffix, "_2020.rds")` |
| `saveRDS(tmpOut, paste0(".../6-5-23results_H_V_NonT", suffix, ...))` | `paste0(RESULTS_HVNONT_BASE, suffix, "_2020.rds")` |
| `saveRDS(tmpOut, paste0(".../6-5-23results_H_NonV_T", suffix, ...))` | `paste0(RESULTS_HNONVT_BASE, suffix, "_2020.rds")` |
| `saveRDS(tmpOut, paste0(".../6-5-23results_H_NonV_NonT", suffix, ...))` | `paste0(RESULTS_HNONVNONT_BASE, suffix, "_2020.rds")` |
| `readRDS(".../7-31-23ddOutcomes_2020_check.rds")` (×2) | `DD_OUTCOMES_CHECK_RDS` |
| `saveRDS(tmpOut, paste0(".../7-31-23results_H", suffix, "_2020_check.rds"))` | `paste0(RESULTS_H_CHECK_BASE, suffix, "_2020_check.rds")` |
| `saveRDS(tmpOut, paste0(".../7-31-23results_L", suffix, "_2020_check.rds"))` | `paste0(RESULTS_L_CHECK_BASE, suffix, "_2020_check.rds")` |
| `readRDS(paste0(".../6-5-23results_H_V_T", suffix, ...))` | `readRDS(paste0(RESULTS_HVT_BASE, suffix, "_2020.rds"))` |
| `readRDS(paste0(".../6-5-23results_H_V_NonT", suffix, ...))` | `readRDS(paste0(RESULTS_HVNONT_BASE, suffix, "_2020.rds"))` |
| `readRDS(paste0(".../6-5-23results_H_NonV_T", suffix, ...))` | `readRDS(paste0(RESULTS_HNONVT_BASE, suffix, "_2020.rds"))` |
| `readRDS(paste0(".../6-5-23results_H_NonV_NonT", suffix, ...))` | `readRDS(paste0(RESULTS_HNONVNONT_BASE, suffix, "_2020.rds"))` |
| `paste0(".../6-5-23H_V_T", suffix, "_2020.rds")` (outFiles vector) | `paste0(SUBGROUP_HVT_BASE, suffix, "_2020.rds")` |
| `paste0(".../6-5-23H_V_NonT", suffix, "_2020.rds")` | `paste0(SUBGROUP_HVNONT_BASE, suffix, "_2020.rds")` |
| `paste0(".../6-5-23H_NonV_T", suffix, "_2020.rds")` | `paste0(SUBGROUP_HNONVT_BASE, suffix, "_2020.rds")` |
| `paste0(".../6-5-23H_NonV_NonT", suffix, "_2020.rds")` | `paste0(SUBGROUP_HNONVNONT_BASE, suffix, "_2020.rds")` |
| `readRDS(paste0(".../7-31-23results_H", suffix, "_2020_check.rds"))` | `readRDS(paste0(RESULTS_H_CHECK_BASE, suffix, "_2020_check.rds"))` |
| `readRDS(paste0(".../7-31-23results_L", suffix, "_2020_check.rds"))` | `readRDS(paste0(RESULTS_L_CHECK_BASE, suffix, "_2020_check.rds"))` |
| `paste0(".../7-31-23H", suffix, "_2020_check.rds")` | `paste0(SUBGROUP_H_CHECK_BASE, suffix, "_2020_check.rds")` |
| `paste0(".../7-31-23L", suffix, "_2020_check.rds")` | `paste0(SUBGROUP_L_CHECK_BASE, suffix, "_2020_check.rds")` |

---

## `2a_fig1.R`

| Original hardcoded path | Config variable |
|---|---|
| `readRDS(".../6-22-22bestDatesLong_M4.rds")` | `BEST_DATES_SAT` |
| `readRDS(".../k30_inMigration_homeDetector_2020.rds")` | `K30_INMIG_RDS` |
| `readRDS(".../impacted_homeDetector_2020.rds")` | `K30_IMPACTED_RDS` |
| `readRDS(".../k30_outMigration_homeDetector_2020.rds")` | `K30_OUTMIG_RDS` |
| `readRDS("/data/afg_anon/displacement_analysis/district_ids_with_info.rds")` | `DISTRICT_IDS` |
| `read.csv(".../poppy_1994-2020.csv")` | `POPPY_CSV` |
| `read.csv("/data/afg_satellite/Conflict_district.csv")` | `CONFLICT_CSV` |
| `pdf(paste0(".../general/8-1-23outcomek30ByDistrict_2407_noViolence.pdf"), ...)` | `pdf(file.path(OUT_GENERAL, "..."), ...)` |

---

## `2b_fig2.R`

| Original hardcoded path | Config variable |
|---|---|
| `readRDS(".../6-5-23distYearsIncluded_2020.rds")` | `DIST_YEARS_RDS` |
| `readRDS(".../3-13-23covariates.rds")` (×2) | `COVARIATES_RDS` |
| `readRDS(".../6-5-23results_inMigration_2020.rds")` | `RESULTS_INMIG_RDS` |
| `pdf(paste0(".../general/8-1-23fig2a.pdf"), ...)` | `pdf(file.path(OUT_GENERAL, "8-1-23fig2a.pdf"), ...)` |
| `readRDS(".../6-5-23inMigRegOutcome_2020.rds")` | `INMIG_OUTCOME_RDS` |
| `pdf(paste0(".../general/1-9-24fig2c.pdf"), ...)` | `pdf(file.path(OUT_GENERAL, "1-9-24fig2c.pdf"), ...)` |
| `readRDS(".../6-5-23ddOutcomes_2020.rds")` | `DD_OUTCOMES_RDS` |
| `readRDS(".../6-22-22bestDatesLong_M4.rds")` | `BEST_DATES_SAT` |
| `pdf(paste0(".../general/1-12-24fig2d.pdf"), ...)` | `pdf(file.path(OUT_GENERAL, "1-12-24fig2d.pdf"), ...)` |

---

## `2c_fig3.R`

| Original hardcoded path | Config variable |
|---|---|
| `readRDS(".../6-5-23inMigRegOutcome_2020.rds")` | `INMIG_OUTCOME_RDS` |
| `readRDS(".../3-13-23covariates.rds")` | `COVARIATES_RDS` |
| `readRDS(".../6-5-23violenceDest_2020.rds")` | `VIOLENCE_DEST_RDS` |
| `pdf(paste0(".../general/1-9-24fig3a.pdf"), ...)` | `pdf(file.path(OUT_GENERAL, "1-9-24fig3a.pdf"), ...)` |
| `pdf(paste0(".../general/10-24-23fig3b.pdf"), ...)` | `pdf(file.path(OUT_GENERAL, "10-24-23fig3b.pdf"), ...)` |

---

## `2d_fig4.R`

| Original hardcoded path | Config variable |
|---|---|
| `readRDS(".../6-22-22bestDatesLong_M4.rds")` (×2) | `BEST_DATES_SAT` |
| `readRDS(".../6-5-23ddOutcomes_violence_HNL_T_2020.rds")` | `DD_OUTCOMES_VIOLENCE_RDS` |
| `readRDS(".../7-31-23ddOutcomes_2020_checks.rds")` | `DD_OUTCOMES_CHECKS_RDS` |
| `readRDS(paste0(".../6-5-23H_V_T", suffix, ...))` | `readRDS(paste0(SUBGROUP_HVT_BASE, suffix, "_2020.rds"))` |
| `readRDS(paste0(".../6-5-23H_V_NonT", suffix, ...))` | `readRDS(paste0(SUBGROUP_HVNONT_BASE, suffix, "_2020.rds"))` |
| `readRDS(paste0(".../6-5-23H_NonV_T", suffix, ...))` | `readRDS(paste0(SUBGROUP_HNONVT_BASE, suffix, "_2020.rds"))` |
| `readRDS(paste0(".../6-5-23H_NonV_NonT", suffix, ...))` | `readRDS(paste0(SUBGROUP_HNONVNONT_BASE, suffix, "_2020.rds"))` |
| `readRDS(paste0(".../7-31-23L", suffix, "_2020_check.rds"))` | `readRDS(paste0(SUBGROUP_L_CHECK_BASE, suffix, "_2020_check.rds"))` |
| `readRDS(".../3-13-23covariates.rds")` (×3) | `COVARIATES_RDS` |
| `saveRDS(plotDTF, ".../general/1-12-24fig4a.rds")` | `FIG4A_DATA_RDS` |
| `readRDS(".../general/1-12-24fig4a.rds")` | `FIG4A_DATA_RDS` |
| `pdf(paste0(".../general/1-12-24fig4a.pdf"), ...)` | `pdf(file.path(OUT_GENERAL, "1-12-24fig4a.pdf"), ...)` |
| `readRDS(paste0(".../7-31-23H", suffix, "_2020_check.rds"))` | `readRDS(paste0(SUBGROUP_H_CHECK_BASE, suffix, "_2020_check.rds"))` |
| `readRDS(paste0(".../7-31-23L", suffix, "_2020_check.rds"))` | `readRDS(paste0(SUBGROUP_L_CHECK_BASE, suffix, "_2020_check.rds"))` |
| `saveRDS(outDTF, ".../general/10-6-23sourceHL.rds")` | `SOURCE_HL_RDS` |
| `readRDS(".../general/10-6-23sourceHL.rds")` | `SOURCE_HL_RDS` |
| `pdf(paste0(".../general/1-9-24fig4b.pdf"), ...)` | `pdf(file.path(OUT_GENERAL, "1-9-24fig4b.pdf"), ...)` |
| `readRDS(paste0(".../6-5-23H_V_T", suffix, ...))` (second set) | `readRDS(paste0(SUBGROUP_HVT_BASE, suffix, "_2020.rds"))` |
| `readRDS(paste0(".../6-5-23H_V_NonT", suffix, ...))` | `readRDS(paste0(SUBGROUP_HVNONT_BASE, suffix, "_2020.rds"))` |
| `readRDS(paste0(".../6-5-23H_NonV_T", suffix, ...))` | `readRDS(paste0(SUBGROUP_HNONVT_BASE, suffix, "_2020.rds"))` |
| `readRDS(paste0(".../6-5-23H_NonV_NonT", suffix, ...))` | `readRDS(paste0(SUBGROUP_HNONVNONT_BASE, suffix, "_2020.rds"))` |
| `saveRDS(outDTF, ".../general/10-6-23sourceH.rds")` | `SOURCE_H_RDS` |
| `readRDS(".../general/10-6-23sourceH.rds")` | `SOURCE_H_RDS` |
| `pdf(paste0(".../general/1-9-24fig4c.pdf"), ...)` | `pdf(file.path(OUT_GENERAL, "1-9-24fig4c.pdf"), ...)` |

---

## `2e_fig5.R`

| Original hardcoded path | Config variable |
|---|---|
| `readRDS(".../3-30-23violenceDest.rds")` | `VIOLENCE_DEST_OLD_RDS` |
| `readRDS(".../6-5-23inMigRegOutcome_2020.rds")` | `INMIG_OUTCOME_RDS` |
| `readRDS(".../3-13-23covariates.rds")` | `COVARIATES_RDS` |
| `read.csv(".../eradication_2014-2016.csv")` | `ERADICATION_CSV` |
| `pdf(paste0(".../general/1-10-24fig5a.pdf"), ...)` | `pdf(file.path(OUT_GENERAL, "1-10-24fig5a.pdf"), ...)` |
| `pdf(paste0(".../general/1-10-24fig6b_2020.pdf"), ...)` | `pdf(file.path(OUT_GENERAL, "1-10-24fig6b_2020.pdf"), ...)` |

---

## `3a_figS1.R`

| Original hardcoded path | Config variable |
|---|---|
| `load("/data/afg_satellite/xtai/afghanShapeAllInfo.Rdata")` | `load(AFG_SHAPE_DATA)` |
| `readRDS(".../3-13-23covariates.rds")` | `COVARIATES_RDS` |
| `read.csv("/data/afg_anon/tower_datasets/tower_groups/v2020/tower_groups.csv")` | `TOWER_GROUPS` |
| `pdf(paste0(".../general/10-13-23map.pdf"), ...)` | `pdf(file.path(OUT_GENERAL, "10-13-23map.pdf"), ...)` |

---

## `3b_figS2.R`

| Original hardcoded path | Config variable |
|---|---|
| `readRDS(".../6-22-22bestDatesLong_M4.rds")` | `BEST_DATES_SAT` |
| `readRDS(".../6-5-23inMigRegOutcome_2020.rds")` | `INMIG_OUTCOME_RDS` |
| `readRDS(".../3-13-23covariates.rds")` | `COVARIATES_RDS` |
| `pdf(".../8-9-24review1/agrTimelineDates.pdf", ...)` | `pdf(file.path(OUT_REVIEW1, "agrTimelineDates.pdf"), ...)` |
| `sf::st_read("/data/afg_satellite/shp/district398/district398.shp", quiet = TRUE)` | `sf::st_read(DISTRICT_SHP, quiet = TRUE)` |
| `pdf(".../8-9-24review1/agrTimelineViz_blank.pdf", ...)` | `pdf(file.path(OUT_REVIEW1, "agrTimelineViz_blank.pdf"), ...)` |

---

## `3c_figS4.R`

| Original hardcoded path | Config variable |
|---|---|
| `system("ls .../8-9-24review1/random/*", intern = TRUE)` | `list.files(RANDOM_DIR, full.names = TRUE)` |
| `readRDS(".../3-13-23covariates.rds")` (×2) | `COVARIATES_RDS` |
| `readRDS(".../6-5-23inMigRegOutcome_2020.rds")` | `INMIG_OUTCOME_RDS` |
| `pdf(paste0(".../8-9-24review1/randomNDVI.pdf"), ...)` | `pdf(file.path(OUT_REVIEW1, "randomNDVI.pdf"), ...)` |

---

## `3d_figS5.R`

| Original hardcoded path | Config variable |
|---|---|
| `readRDS(".../6-5-23inMigRegOutcome_2020.rds")` | `INMIG_OUTCOME_RDS` |
| `readRDS(".../3-13-23covariates.rds")` | `COVARIATES_RDS` |
| `readRDS(".../6-5-23violenceDest_2020.rds")` | `VIOLENCE_DEST_RDS` |
| `pdf(paste0(".../general/9-26-23twoWayEDA.pdf"), ...)` | `pdf(file.path(OUT_GENERAL, "9-26-23twoWayEDA.pdf"), ...)` |

---

## `3e_figS6.R`

| Original hardcoded path | Config variable |
|---|---|
| `readRDS(".../6-5-23inMigRegOutcome_2020.rds")` | `INMIG_OUTCOME_RDS` |
| `readRDS(".../3-13-23covariates.rds")` | `COVARIATES_RDS` |
| `readRDS(".../6-5-23violenceDest_2020.rds")` | `VIOLENCE_DEST_RDS` |
| `pdf(paste0(".../general/1-10-24figA2.pdf"), ...)` | `pdf(file.path(OUT_GENERAL, "1-10-24figA2.pdf"), ...)` |

---

## `3f_figS7.R`

| Original hardcoded path | Config variable |
|---|---|
| `readRDS(".../6-5-23inMigRegOutcome_2020.rds")` | `INMIG_OUTCOME_RDS` |
| `readRDS(".../3-13-23covariates.rds")` | `COVARIATES_RDS` |
| `readRDS(".../6-5-23violenceDest_2020.rds")` | `VIOLENCE_DEST_RDS` |
| `pdf(paste0(".../general/1-10-24fig3b_robust.pdf"), ...)` | `pdf(file.path(OUT_GENERAL, "1-10-24fig3b_robust.pdf"), ...)` |

---

## `3g_figS8.R`

| Original hardcoded path | Config variable |
|---|---|
| `readRDS(".../6-5-23inMigRegOutcome_2020.rds")` | `INMIG_OUTCOME_RDS` |
| `readRDS(".../3-13-23covariates.rds")` | `COVARIATES_RDS` |
| `readRDS(".../6-5-23violenceDest_2020.rds")` | `VIOLENCE_DEST_RDS` |
| `pdf(paste0(".../general/1-10-24fig3b_post2017.pdf"), ...)` | `pdf(file.path(OUT_GENERAL, "1-10-24fig3b_post2017.pdf"), ...)` |
| `pdf(paste0(".../general/1-10-24fig3b_robust2.pdf"), ...)` | `pdf(file.path(OUT_GENERAL, "1-10-24fig3b_robust2.pdf"), ...)` |

---

## `3h_figS9.R`

| Original hardcoded path | Config variable |
|---|---|
| `readRDS(".../6-5-23inMigRegOutcome_2020.rds")` | `INMIG_OUTCOME_RDS` |
| `readRDS(".../3-13-23covariates.rds")` | `COVARIATES_RDS` |
| `readRDS(".../6-5-23violenceDest_2020.rds")` | `VIOLENCE_DEST_RDS` |
| `pdf(paste0(".../general/12-14-23fig3b_violenceDef.pdf"), ...)` | `pdf(file.path(OUT_GENERAL, "12-14-23fig3b_violenceDef.pdf"), ...)` |

---

## `3i_figS10.R`

| Original hardcoded path | Config variable |
|---|---|
| `readRDS(paste0(".../6-5-23H_V_T", suffix, ...))` | `readRDS(paste0(SUBGROUP_HVT_BASE, suffix, "_2020.rds"))` |
| `readRDS(paste0(".../6-5-23H_V_NonT", suffix, ...))` | `readRDS(paste0(SUBGROUP_HVNONT_BASE, suffix, "_2020.rds"))` |
| `readRDS(paste0(".../6-5-23H_NonV_T", suffix, ...))` | `readRDS(paste0(SUBGROUP_HNONVT_BASE, suffix, "_2020.rds"))` |
| `readRDS(paste0(".../6-5-23H_NonV_NonT", suffix, ...))` | `readRDS(paste0(SUBGROUP_HNONVNONT_BASE, suffix, "_2020.rds"))` |
| `readRDS(".../3-13-23covariates.rds")` | `COVARIATES_RDS` |
| `pdf(paste0(".../general/1-10-24fig4c_robust.pdf"), ...)` | `pdf(file.path(OUT_GENERAL, "1-10-24fig4c_robust.pdf"), ...)` |

---

## `4a_dataPrep_tables.R`

| Original hardcoded path | Config variable |
|---|---|
| `read.csv(".../mig_stats_agg.csv")` | `read.csv(MIG_STATS_CSV)` |
| `readRDS(".../6-22-22bestDatesLong_M4.rds")` | `BEST_DATES_SAT` |
| `saveRDS(ddOutcomes, ".../1-23-24ddOutcomes_goes_back_90.rds")` | `DD_OUTCOMES_GOBACK_RDS` |
| `readRDS(".../1-23-24ddOutcomes_goes_back_90.rds")` | `DD_OUTCOMES_GOBACK_RDS` |
| `saveRDS(tmpOut, ".../1-23-24results_inMigrant_goes_back_90.rds")` | `RESULTS_GOBACK_90_RDS` |
| `readRDS(".../1-23-24results_inMigrant_goes_back_90.rds")` | `RESULTS_GOBACK_90_RDS` |
| `readRDS(".../6-5-23distYearsIncluded_2020.rds")` | `DIST_YEARS_RDS` |
| `saveRDS(newResponse, ".../1-23-24inMigGoesBackRegOutcome_90.rds")` | `OUTCOME_GOBACK_90_RDS` |
| `readRDS(".../6-5-23results_inMigration_2020.rds")` (×2) | `RESULTS_INMIG_RDS` |
| `saveRDS(newResponse, ".../9-26-23inMigRegOutcome_1-45_2020.rds")` | `OUTCOME_1_45_RDS` |
| `saveRDS(newResponse, ".../9-26-23inMigRegOutcome_1-45_14days_2020.rds")` | `OUTCOME_1_45_14D_RDS` |
| `readRDS(".../6-5-23ddOutcomes_2020.rds")` | `DD_OUTCOMES_RDS` |
| `saveRDS(newResponse, ".../8-9-24review1/outcome14days.rds")` | `OUTCOME_PLUS14_RDS` |

---

## `4b_dataPrep2_tables.R`

| Original hardcoded path | Config variable |
|---|---|
| `list.files(".../time_delta_45_days/")` (×2) | `list.files(CDR_K45_DIR)` |
| `read.csv(paste0(".../time_delta_45_days/", fileList[1]))` (×2) | `read.csv(file.path(CDR_K45_DIR, fileList[1]))` |
| `read.csv(paste0(".../time_delta_45_days/", fileList[i]))` (×2) | `read.csv(file.path(CDR_K45_DIR, fileList[i]))` |
| `saveRDS(outData, ".../k45_inMigration_homeDetector_2020.rds")` | `K45_INMIG_RDS` |
| `saveRDS(getImpacted, ".../impacted_homeDetector_2020_k45.rds")` | `K45_IMPACTED_RDS` |
| `readRDS(".../6-22-22bestDatesLong_M4.rds")` | `BEST_DATES_SAT` |
| `readRDS(".../k45_inMigration_homeDetector_2020.rds")` | `K45_INMIG_RDS` |
| `readRDS(".../impacted_homeDetector_2020_k45.rds")` | `K45_IMPACTED_RDS` |
| `saveRDS(ddOutcomes, ".../11-14-24ddOutcomes_2020_k45.rds")` | `DD_OUTCOMES_K45_RDS` |
| `readRDS(".../11-14-24ddOutcomes_2020_k45.rds")` | `DD_OUTCOMES_K45_RDS` |
| `saveRDS(tmpOut, ".../11-14-24results_inMigration_2020_k45.rds")` | `RESULTS_INMIG_K45_RDS` |
| `readRDS(".../11-14-24results_inMigration_2020_k45.rds")` | `RESULTS_INMIG_K45_RDS` |
| `saveRDS(newResponse, ".../11-14-24inMigRegOutcome_2020_k45.rds")` | `OUTCOME_K45_RDS` |

---

## `4c_tablesS1-3.R`

| Original hardcoded path | Config variable |
|---|---|
| `readRDS(".../6-5-23inMigRegOutcome_2020.rds")` (×3) | `INMIG_OUTCOME_RDS` |
| `readRDS(".../9-26-23inMigRegOutcome_1-45_2020.rds")` | `OUTCOME_1_45_RDS` |
| `readRDS(".../9-26-23inMigRegOutcome_1-45_14days_2020.rds")` | `OUTCOME_1_45_14D_RDS` |
| `readRDS(".../10-16-23inMigStaysRegOutcome_2020.rds")` | `OUTCOME_STAYS_RDS` |
| `readRDS(".../12-19-23inMigGoesBackRegOutcome_2020.rds")` | `OUTCOME_GOBACK_RDS` |
| `readRDS(".../1-23-24inMigGoesBackRegOutcome_90.rds")` | `OUTCOME_GOBACK_90_RDS` |
| `readRDS(".../11-14-24inMigRegOutcome_2020_k15.rds")` | `OUTCOME_K15_RDS` |
| `readRDS(".../11-14-24inMigRegOutcome_2020_k45.rds")` | `OUTCOME_K45_RDS` |
| `readRDS(".../8-9-24review1/outcome-14days.rds")` | `OUTCOME_MINUS14_RDS` |
| `readRDS(".../8-9-24review1/outcome14days.rds")` | `OUTCOME_PLUS14_RDS` |
| `readRDS(".../3-13-23covariates.rds")` (×3) | `COVARIATES_RDS` |
| `readRDS(".../6-22-22bestDatesLong_M4.rds")` | `BEST_DATES_SAT` |
| `readRDS(".../1-23-24ddOutcomes_goes_back_90.rds")` | `DD_OUTCOMES_GOBACK_RDS` |

---

## `5a_figS12.R`

| Original hardcoded path | Config variable |
|---|---|
| `readRDS(".../6-5-23inMigRegOutcome_2020.rds")` | `INMIG_OUTCOME_RDS` |
| `readRDS(".../3-13-23covariates.rds")` | `COVARIATES_RDS` |
| `readRDS(".../6-5-23violenceDest_2020.rds")` | `VIOLENCE_DEST_RDS` |
| `read.csv("/data/afg_satellite/snair/violence_roads.csv")` | `VIOLENCE_ROAD_CSV` |
| `pdf(paste0("10-24-23fig3b_alt.pdf"), ...)` *(bug: wrote to working dir)* | `pdf(file.path(OUT_GENERAL, "10-24-23fig3b_alt.pdf"), ...)` |

---

## `6a_figS13.R`

| Original hardcoded path | Config variable |
|---|---|
| `readRDS(".../6-22-22bestDatesLong_M4.rds")` | `BEST_DATES_SAT` |
| `read.csv(paste0(".../time_delta_30_days/impact_day_", impactDay, ".csv"))` | `read.csv(file.path(CDR_K30_DIR, paste0("impact_day_", impactDay, ".csv")))` |
| `saveRDS(ddOutcomes, ".../8-9-24review1/1-22-24OD_raw.rds")` | `OD_RAW_RDS` |
| `readRDS(".../8-9-24review1/1-22-24OD_raw.rds")` | `OD_RAW_RDS` |
| `readRDS(".../6-5-23ddOutcomes_violence_HNL_T_2020.rds")` | `DD_OUTCOMES_VIOLENCE_RDS` |
| `saveRDS(out, ".../8-9-24review1/1-22-24OD_out.rds")` | `OD_OUT_RDS` |
| `readRDS(".../8-9-24review1/1-22-24OD_out.rds")` | `OD_OUT_RDS` |
| `readRDS(".../3-13-23covariates.rds")` | `COVARIATES_RDS` |
| `readRDS("/data/afg_anon/displacement_analysis/district_ids_with_info.rds")` | `DISTRICT_IDS` |
| `pdf(".../8-9-24review1/ODmatrix.pdf", ...)` | `pdf(file.path(OUT_REVIEW1, "ODmatrix.pdf"), ...)` |

---

## `6b_tablesS4-6.R`

| Original hardcoded path | Config variable |
|---|---|
| `readRDS(".../6-5-23inMigRegOutcome_2020.rds")` (×3) | `INMIG_OUTCOME_RDS` |
| `readRDS(".../3-13-23covariates.rds")` (×4) | `COVARIATES_RDS` |
| `readRDS(".../6-5-23violenceDest_2020.rds")` (×2) | `VIOLENCE_DEST_RDS` |
| `readRDS(paste0(".../7-31-23H", suffix, "_2020_check.rds"))` (×2) | `readRDS(paste0(SUBGROUP_H_CHECK_BASE, suffix, "_2020_check.rds"))` |
| `readRDS(paste0(".../7-31-23L", suffix, "_2020_check.rds"))` (×2) | `readRDS(paste0(SUBGROUP_L_CHECK_BASE, suffix, "_2020_check.rds"))` |
| `readRDS(paste0(".../6-5-23H_V_T", suffix, ...))` (×2) | `readRDS(paste0(SUBGROUP_HVT_BASE, suffix, "_2020.rds"))` |
| `readRDS(paste0(".../6-5-23H_V_NonT", suffix, ...))` (×2) | `readRDS(paste0(SUBGROUP_HVNONT_BASE, suffix, "_2020.rds"))` |
| `readRDS(paste0(".../6-5-23H_NonV_T", suffix, ...))` (×2) | `readRDS(paste0(SUBGROUP_HNONVT_BASE, suffix, "_2020.rds"))` |
| `readRDS(paste0(".../6-5-23H_NonV_NonT", suffix, ...))` (×2) | `readRDS(paste0(SUBGROUP_HNONVNONT_BASE, suffix, "_2020.rds"))` |
| `read.csv(".../eradication_2014-2016.csv")` | `ERADICATION_CSV` |

---

## `randomizationInference.R`

| Original hardcoded path | Config variable |
|---|---|
| `readRDS(".../6-22-22bestDatesLong_M4.rds")` | `BEST_DATES_SAT` |
| `readRDS(".../6-5-23ddOutcomes_2020.rds")` | `DD_OUTCOMES_RDS` |
| `paste0(".../8-9-24review1/random/random_", sprintf("%03d", numericArg), ".rds")` | `file.path(RANDOM_DIR, paste0("random_", sprintf("%03d", numericArg), ".rds"))` |
