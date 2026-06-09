
# 1c_makeDailyPanel.R
# Aggregates raw k=30 CDR impact-day files into daily district-level in- and
# out-migration panels. In-migration: visits arriving in a district from outside
# relative to the number of people present that day. Out-migration: people who
# left a district relative to those present 30 days earlier.
# Inputs:  CDR_K30_DIR (raw CSVs), BEST_DATES_SAT
# Outputs: K30_INMIG_RDS, K30_IMPACTED_RDS, DD_OUTCOMES_RDS,
#          K30_OUTMIG_RDS, DD_OUTCOMES_OUT_RDS

rm(list=ls()); gc()
library(dplyr); library(ggplot2)
source("config.R")

# /data/afg_anon/displacement_metrics/visits_per_district_day/using_2013-2020_data/time_delta_30_days
# files are now indexed by impact day: impact_day_971.csv etc. 

# impact_day 1 is 2013-04-01
# impact_day 1461 is 
# as.Date("2013-04-01") + lubridate::days(1460) #days(impacted_day - 1)

## group by visit_day, destination_district
# numAround = sum visits: this is the number in destination_district (denominator)
# e.g., first entry: 82142 impacted in Kabul on day 1; 76044 in Kabul on day 31 (from Kabul and other places in day 1)
# sum where origin_district != destination_district: this is the proportion of in-migration

# impacted is number available on impact_day

fileList <- list.files(CDR_K30_DIR) 

tmpFile <- read.csv(file.path(CDR_K30_DIR, fileList[1]))

outData <- tmpFile %>%
  group_by(destination_district, visit_day) %>% # now aggregate
  summarize(
    numNew = sum(visits[which(origin_district != destination_district)], na.rm = TRUE)
  )

options(dplyr.summarise.inform = FALSE)
Sys.time()
for (i in 2:length(fileList)) {
  if (i %% 200 == 0) cat(i, ", ")
  tmpFile <- read.csv(file.path(CDR_K30_DIR, fileList[i]))
  
  tmpData <- tmpFile %>%
    group_by(destination_district, visit_day) %>% # now aggregate
    summarize(
      numNew = sum(visits[which(origin_district != destination_district)], na.rm = TRUE)
    )
  outData <- outData %>%
    bind_rows(tmpData)
}
Sys.time()
# 14 minutes

# NOTE: previously it was fine to do it without na.rm = TRUE, because NA visits are when impacted is zero, which is tied to the origin_district. For an origin_district with none impacted, all visits are NA, so when grouping by origin_district, impact_day, all will be NA
# now when grouping by destination_district, visit_day, some obs in sum will be NA, and as a result all output is NA, erasing the available data 

# rm("k30data"); gc()

outData <- outData %>%
  mutate(date = as.Date("2013-04-01") + lubridate::days(visit_day - 1)) 
saveRDS(outData, file = K30_INMIG_RDS)

################## impacted: 
fileList <- list.files(CDR_K30_DIR)
tmpFile <- read.csv(file.path(CDR_K30_DIR, fileList[1]))
getImpacted <- tmpFile %>%
  distinct(origin_district, impact_day, impacted)

tmpFile <- read.csv(file.path(CDR_K30_DIR, "impact_day_2000.csv"))


Sys.time()
for (i in 2:length(fileList)) {
  if (i %% 200 == 0) cat(i, ", ")
  tmpFile <- read.csv(file.path(CDR_K30_DIR, fileList[i]))
  tmpData <- tmpFile %>%
    distinct(origin_district, impact_day, impacted)
  getImpacted <- getImpacted %>%
    bind_rows(tmpData)
}
Sys.time()

saveRDS(getImpacted, file = K30_IMPACTED_RDS)
# 10 minutes  

####################################################################################
rm(list=ls()); gc()
#### harvest dates
bestDatesLong <- readRDS(BEST_DATES_SAT) %>%
  select(distIDs, year, maxDate) %>%
  rename("distID" = "distIDs",
         "date" = "maxDate")

bestDatesWide <- bestDatesLong %>%
  tidyr::pivot_wider(names_from = "year",
                     values_from = "date",
                     names_prefix = "year_")


### for in-migration
outData <- readRDS(K30_INMIG_RDS)
# outData <- readRDS("/home/xtai/climate/data/k30_inMigration_homeDetector_dropF.rds")
# here numAround sums the non-missing entries in each district on day 30, out of those present on day 0
# numNew is the number in numAround that were in a different district on day 0
# impacted (below): the number in the district on each day

getImpacted <- readRDS(K30_IMPACTED_RDS) %>% # 581478 rows
  rename(district_id = origin_district) %>%
  mutate(date = as.Date("2013-04-01") + lubridate::days(impact_day - 1)) %>%
  select(-impact_day)

ddOutcomes <- getImpacted %>%
  select(district_id, date) %>%
  left_join(outData %>%
              select(destination_district, date, numNew),
            by = c("district_id" = "destination_district", "date")) %>%
  left_join(getImpacted, by = c("district_id", "date")) %>%
  mutate(percentage_in = numNew/impacted) #%>% # NaN when 0/0, i.e., no one around
# select(-numNew)

# this gives percentage of those around today who were known to be in a different district 30 days ago
# compare with out-migration previous definition: those around 30 days ago who are known to be in a different district today

ddOutcomes <- ddOutcomes %>%
  left_join(bestDatesWide,
            by = c("district_id" = "distID")) %>%
  mutate(across(where(is.character), as.Date))

# what period to use as baseline?
# want mean of the 5 largest values happening a week before to 2 months after
# how much more than the average in the three-month period 1-4 months before the peak NDVI (baseline)

ddOutcomes <- ddOutcomes %>%
  data.frame()

# coefs_yyyy: 1 month before to 2 months after
# baseline_yyyy: anything within 4 months before to 2 months after
for (i in 2014:2020) {
  ddOutcomes[, paste0("baseline_", i)] <- ifelse(ddOutcomes$date >= ddOutcomes[, paste0("year_", i)] - lubridate::days(120) & 
                                                   ddOutcomes$date <= ddOutcomes[, paste0("year_", i)] + lubridate::days(90),# change from 60 to 90
                                                 1, 0)
}

saveRDS(ddOutcomes, file = DD_OUTCOMES_RDS) 

########## now make out-migration data set for 2013-2020
# out-migration: first need to calculate percentage_migrated
rm(list=ls()); gc()
fileList <- list.files(CDR_K30_DIR)

tmpFile <- read.csv(file.path(CDR_K30_DIR, fileList[1]))

outData <- tmpFile %>%
  group_by(origin_district, impacted, visit_day) %>% # now aggregate
  summarize(
    numMoved = sum(visits[which(origin_district != destination_district)], na.rm = TRUE)
  )

options(dplyr.summarise.inform = FALSE)
Sys.time()
for (i in 2:length(fileList)) {
  if (i %% 200 == 0) cat(i, ", ")
  tmpFile <- read.csv(file.path(CDR_K30_DIR, fileList[i]))
  
  tmpData <- tmpFile %>%
    group_by(origin_district, impacted, visit_day) %>% # now aggregate
    summarize(
      numMoved = sum(visits[which(origin_district != destination_district)], na.rm = TRUE)
    )
  outData <- outData %>%
    bind_rows(tmpData)
}
Sys.time()
# 20 minutes 

outData <- outData %>%
  mutate(date = as.Date("2013-04-01") + lubridate::days(visit_day - 1), # index it to visit_day (so when they were around is 30 days ago, i.e., lagged version)
         percentage_migrated = numMoved/impacted) %>%
  arrange(origin_district, date)
saveRDS(outData, file = K30_OUTMIG_RDS)

#### out-migration ddOutcomes
rm(list = ls())
#### harvest dates
bestDatesWide <- readRDS(BEST_DATES_SAT) %>%
  select(distIDs, year, maxDate) %>%
  rename("distID" = "distIDs",
         "date" = "maxDate") %>%
  tidyr::pivot_wider(names_from = "year",
                     values_from = "date",
                     # values_from = "bestDatesM2",
                     names_prefix = "year_")

##########
ddOutcomes <- readRDS(K30_OUTMIG_RDS) %>%
  rename(district_id = origin_district) %>%
  left_join(bestDatesWide,
            by = c("district_id" = "distID")) %>%
  mutate(across(where(is.character), as.Date))

ddOutcomes <- data.frame(ddOutcomes)

# baseline_yyyy: anything within 4 months before to 3 months after
for (i in 2014:2020) {
  ddOutcomes[, paste0("baseline_", i)] <- ifelse(ddOutcomes$date >= ddOutcomes[, paste0("year_", i)] - lubridate::days(120) & 
                                                   ddOutcomes$date <= ddOutcomes[, paste0("year_", i)] + lubridate::days(90),# change from 60 to 90
                                                 1, 0)
}

saveRDS(ddOutcomes, file = DD_OUTCOMES_OUT_RDS)
# this has 398 districts 

