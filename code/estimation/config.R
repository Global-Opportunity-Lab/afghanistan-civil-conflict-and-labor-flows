# config.R
# Central path configuration for the estimation pipeline.
#
# Before running any estimation script, set the three root variables below to
# match your local environment.  Everything else is derived automatically.
#
# Usage: add `source("config.R")` at the top of each script.

# ── Root directories ────────────────────────────────────────────────────────
# WORK_ROOT: analysis working directory on the compute server
WORK_ROOT <- "home/path_to_dir"

# CDR_ROOT: root of the CDR/displacement-metrics data tree (restricted access)
CDR_ROOT  <- "/data/cdr"

# SAT_ROOT: root of the satellite data tree
SAT_ROOT  <- "/data/afg_satellite"

# TMP_ROOT: scratch directory used for agrPixels 
TMP_ROOT  <- "/data/tmp"

# ── Derived directory paths ──────────────────────────────────────────────────
# Working-data subdirectories
RAW_DATA_DIR  <- file.path(WORK_ROOT, "data")
OUT_DIR       <- file.path(WORK_ROOT, "3-8-23migrationCleanCode/output")
OUT_GENERAL   <- file.path(OUT_DIR,   "general")
OUT_REVIEW1   <- file.path(WORK_ROOT, "3-8-23migrationCleanCode/8-9-24review1")
LEGACY_OUT_DIR <- file.path(WORK_ROOT, "output")   # older output tree (pre-refactor)

# CDR data subdirectories
CDR_DISP_DIR <- file.path(CDR_ROOT, "displacement_metrics/visits_per_district_day/using_2013-2020_data")
CDR_K30_DIR  <- file.path(CDR_DISP_DIR, "time_delta_30_days")
CDR_K15_DIR  <- file.path(CDR_DISP_DIR, "time_delta_15_days")
CDR_K45_DIR  <- file.path(CDR_DISP_DIR, "time_delta_45_days")

# Satellite data subdirectories
SAT_BESTDATES_DIR <- file.path(SAT_ROOT, "bestdates")
PIXEL_MAXDATA_DIR <- file.path(SAT_BESTDATES_DIR, "pixel_maxdata_real_June")
AGR_YN_DIR        <- file.path(SAT_BESTDATES_DIR, "agrYN")

# ── Individual input file paths ──────────────────────────────────────────────

# CDR-derived data
DISTRICT_IDS  <- file.path(CDR_ROOT, "displacement_analysis/district_ids_with_info.rds")
SIGAR_CSV     <- file.path(CDR_ROOT, "displacement_analysis/SIGARcontrol.csv")
TOWER_GROUPS  <- file.path(CDR_ROOT, "tower_datasets/tower_groups/v2020/tower_groups.csv")

# Satellite data
AFG_SHAPE_DATA        <- file.path(SAT_ROOT, "intermediate_data/afghanShapeAllInfo.Rdata")
AGR_PIXELS            <- file.path(TMP_ROOT, "agrPixels.Rds")
DISTRICT_SHP          <- file.path(SAT_ROOT, "shp/district398/district398.shp")
CONFLICT_CSV          <- file.path(SAT_ROOT, "Conflict_district.csv")
MIG_STATS_CSV         <- file.path(SAT_ROOT, "intermediate_data/mig_stats_agg.csv")
VIOLENCE_ROAD_CSV     <- file.path(SAT_ROOT, "intermediate_data/violence_roads.csv")
PEAK_DATES_CSV        <- file.path(SAT_ROOT, "intermediate_data/peakInMigDate.csv")

# Satellite best-dates files (produced by 1b, read by 1a and downstream scripts)
BEST_DATES_SAT          <- file.path(SAT_BESTDATES_DIR, "bestDatesLong_M4.rds")
BEST_DATES_SAT_CSV      <- file.path(SAT_BESTDATES_DIR, "bestDatesLong_M4.csv")
AGR_BEST_DATES_RDS      <- file.path(SAT_BESTDATES_DIR, "agrBestDates_withDistIDs.rds")
AGR_BEST_DATES_NDVI_RDS <- file.path(SAT_BESTDATES_DIR, "agrBestDates_withDistIDs_NDVI.rds")

# Public data in working-data directory
POPPY_CSV       <- file.path(RAW_DATA_DIR, "poppy_1994-2020.csv")
ERADICATION_CSV <- file.path(RAW_DATA_DIR, "eradication_2014-2016.csv")

# CDR-derived intermediate files stored in working-data directory
AG_HECTARES_RDS  <- file.path(RAW_DATA_DIR, "agHectares.rds")
K30_INMIG_RDS    <- file.path(RAW_DATA_DIR, "k30_inMigration_homeDetector_2020.rds")
K30_IMPACTED_RDS <- file.path(RAW_DATA_DIR, "impacted_homeDetector_2020.rds")
K30_OUTMIG_RDS   <- file.path(RAW_DATA_DIR, "k30_outMigration_homeDetector_2020.rds")
K15_INMIG_RDS    <- file.path(RAW_DATA_DIR, "k15_inMigration_homeDetector_2020.rds")
K45_INMIG_RDS    <- file.path(RAW_DATA_DIR, "k45_inMigration_homeDetector_2020.rds")
K15_IMPACTED_RDS <- file.path(RAW_DATA_DIR, "impacted_homeDetector_2020_k15.rds")
K45_IMPACTED_RDS <- file.path(RAW_DATA_DIR, "impacted_homeDetector_2020_k45.rds")

# Legacy output used only for district-name lookup in 1d_makeRegPanel.R
LEGACY_RESULTS2014 <- file.path(LEGACY_OUT_DIR, "results2014_in_LPM_bestDatesM4_homeDetctor.rds")

# ── Analysis output files (produced and consumed by pipeline scripts) ─────────

# Covariates panel (1a → many downstream scripts)
COVARIATES_RDS <- file.path(OUT_DIR, "covariates.rds")

# Daily CDR panels (1c → 1d, 4a, 4b, randomizationInference)
DD_OUTCOMES_RDS          <- file.path(OUT_DIR, "ddOutcomes_2020.rds")
DD_OUTCOMES_VIOLENCE_RDS <- file.path(OUT_DIR, "ddOutcomes_violence_HNL_T_2020.rds")
DD_OUTCOMES_CHECK_RDS    <- file.path(OUT_DIR, "ddOutcomes_2020_check.rds")
DD_OUTCOMES_GOBACK_RDS   <- file.path(OUT_DIR, "ddOutcomes_goes_back_90.rds")
DD_OUTCOMES_K15_RDS      <- file.path(OUT_DIR, "ddOutcomes_2020_k15.rds")
DD_OUTCOMES_K45_RDS      <- file.path(OUT_DIR, "ddOutcomes_2020_k45.rds")
DD_OUTCOMES_OUT_RDS      <- file.path(OUT_DIR, "ddOutcomes_out_2020.rds")

# Daily regression results (1d, 4b → 1d, 4a, 4c)
RESULTS_INMIG_RDS     <- file.path(OUT_DIR, "results_inMigration_2020.rds")
RESULTS_OUTMIG_RDS    <- file.path(OUT_DIR, "results_outMigration_2020.rds")
RESULTS_INMIG_K15_RDS <- file.path(OUT_DIR, "results_inMigration_2020_k15.rds")
RESULTS_INMIG_K45_RDS <- file.path(OUT_DIR, "results_inMigration_2020_k45.rds")

# District-year identifiers with sufficient observations (1d → 2b, 4a)
DIST_YEARS_RDS <- file.path(OUT_DIR, "distYearsIncluded_2020.rds")

# Main regression outcome: excess harvest in-migration (1d → 2b–6b)
INMIG_OUTCOME_RDS <- file.path(OUT_DIR, "inMigRegOutcome_2020.rds")

# Violence at destination districts around harvest (1d → 2c–6b)
VIOLENCE_DEST_RDS     <- file.path(OUT_DIR, "violenceDest_2020.rds")
VIOLENCE_DEST_OLD_RDS <- file.path(OUT_DIR, "violenceDest.rds")  # older version used only in 2e

# Intermediate results by source-district type (1e — daily regression step)
# These use a suffix convention: suffix <- "_rA" is the variant used in the paper.
# Replace the hardcoded directory prefix; keep `paste0(..., suffix, ...)` calls intact.
RESULTS_HVT_BASE       <- file.path(OUT_DIR, "results_H_V_T")       # + suffix + "_2020.rds"
RESULTS_HVNONT_BASE    <- file.path(OUT_DIR, "results_H_V_NonT")    # + suffix + "_2020.rds"
RESULTS_HNONVT_BASE    <- file.path(OUT_DIR, "results_H_NonV_T")    # + suffix + "_2020.rds"
RESULTS_HNONVNONT_BASE <- file.path(OUT_DIR, "results_H_NonV_NonT") # + suffix + "_2020.rds"
RESULTS_H_CHECK_BASE   <- file.path(OUT_DIR, "results_H")           # + suffix + "_2020_check.rds"
RESULTS_L_CHECK_BASE   <- file.path(OUT_DIR, "results_L")           # + suffix + "_2020_check.rds"

# Final district-year outcomes by source-district type (1e → 2d–6b)
SUBGROUP_HVT_BASE       <- file.path(OUT_DIR, "H_V_T")        # + suffix + "_2020.rds"
SUBGROUP_HVNONT_BASE    <- file.path(OUT_DIR, "H_V_NonT")     # + suffix + "_2020.rds"
SUBGROUP_HNONVT_BASE    <- file.path(OUT_DIR, "H_NonV_T")     # + suffix + "_2020.rds"
SUBGROUP_HNONVNONT_BASE <- file.path(OUT_DIR, "H_NonV_NonT")  # + suffix + "_2020.rds"
SUBGROUP_H_CHECK_BASE   <- file.path(OUT_DIR, "H")            # + suffix + "_2020_check.rds"
SUBGROUP_L_CHECK_BASE   <- file.path(OUT_DIR, "L")            # + suffix + "_2020_check.rds"

# Robustness-check outcomes for tables S1–S3 (4a → 4c)
OUTCOME_1_45_RDS      <- file.path(OUT_DIR, "inMigRegOutcome_1-45_2020.rds")
OUTCOME_1_45_14D_RDS  <- file.path(OUT_DIR, "inMigRegOutcome_1-45_14days_2020.rds")
OUTCOME_STAYS_RDS     <- file.path(OUT_DIR, "inMigStaysRegOutcome_2020.rds")
OUTCOME_GOBACK_RDS    <- file.path(OUT_DIR, "inMigGoesBackRegOutcome_2020.rds")
OUTCOME_GOBACK_90_RDS <- file.path(OUT_DIR, "inMigGoesBackRegOutcome_90.rds")
RESULTS_GOBACK_90_RDS <- file.path(OUT_DIR, "results_inMigrant_goes_back_90.rds")
OUTCOME_K15_RDS       <- file.path(OUT_DIR, "inMigRegOutcome_2020_k15.rds")
OUTCOME_K45_RDS       <- file.path(OUT_DIR, "inMigRegOutcome_2020_k45.rds")

# ── Figure-data outputs (pre-computed point-range results) ────────────────────
FIG4A_DATA_RDS <- file.path(OUT_GENERAL, "fig4a.rds")
SOURCE_HL_RDS  <- file.path(OUT_GENERAL, "sourceHL.rds")
SOURCE_H_RDS   <- file.path(OUT_GENERAL, "sourceH.rds")

# ── Reviewer-round-1 outputs ──────────────────────────────────────────────────
RANDOM_DIR          <- file.path(OUT_REVIEW1, "random")
OD_RAW_RDS          <- file.path(OUT_REVIEW1, "OD_raw.rds")
OD_OUT_RDS          <- file.path(OUT_REVIEW1, "OD_out.rds")
OUTCOME_MINUS14_RDS <- file.path(OUT_REVIEW1, "outcome-14days.rds")
OUTCOME_PLUS14_RDS  <- file.path(OUT_REVIEW1, "outcome14days.rds")
