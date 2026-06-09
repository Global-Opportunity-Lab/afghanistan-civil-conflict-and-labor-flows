

# outcomes that need data prep: 
# C. 1-45 day window instead of 15-35 (part 3 of below code) outcomes2
# D. mean over 14-day continuous period rather than 7-day (part 3 of below code) outcomes3
# E. in-migrant stays: need to run parts 1-3 of below code outcomes4-6

# outcomes9 and 10: +/-14 days 
# ourcomes7 and 8: k = 15 and k = 45: see 4b_dataPrep2
 
####################### ROBUSTNESS CHECK E. in-migrant stays #########################
rm(list=ls()); gc()
source("config.R")
# migStats <- read.csv("/intermediate_data/mig_stats_15mar.csv") # superseded
migStats <- read.csv("/intermediate_data/mig_stats_oct15.csv")
migStats <- read.csv("/intermediate_data/mig_stats_dec15.csv") # return migration 
migStats <- read.csv(MIG_STATS_CSV) # 


################### More prep for in-migration variable ###################
#### harvest dates
bestDatesLong <- readRDS(BEST_DATES_SAT) %>%
  select(distIDs, year, maxDate) %>%
  rename("distID" = "distIDs",
         "date" = "maxDate")

bestDatesWide <- bestDatesLong %>%
  tidyr::pivot_wider(names_from = "year",
                     values_from = "date",
                     # values_from = "bestDatesM2",
                     names_prefix = "year_")

###
ddOutcomes <- migStats %>%
  rename(district_id = home_location, date = day) %>%
  # rename(district_id = home_location, date = day1) %>%
  mutate(percentage_in = goes_back_90/in_migrant) # 1/23/24
  # mutate(percentage_in = in_migrant_goes_back/in_migrant) # 12/19/23
# mutate(percentage_in = in_migrant_stays/in_migrant)

ddOutcomes <- ddOutcomes %>%
  left_join(bestDatesWide,
            by = c("district_id" = "distID")) %>%
  mutate(across(where(is.character), as.Date))

# baseline_yyyy: anything within 4 months before to 3 months after
for (i in 2014:2020) {
  ddOutcomes[, paste0("baseline_", i)] <- ifelse(ddOutcomes$date >= ddOutcomes[, paste0("year_", i)] - lubridate::days(120) & 
                                                   ddOutcomes$date <= ddOutcomes[, paste0("year_", i)] + lubridate::days(90),# change from 60 to 90
                                                 1, 0)
}

# saveRDS(ddOutcomes, file = "output/9-26-23ddOutcomes_stays_2020.rds")
# saveRDS(ddOutcomes, file = "output/12-19-23ddOutcomes_goes_back_2020.rds")
saveRDS(ddOutcomes, file = DD_OUTCOMES_GOBACK_RDS)

####### Part 2: excess daily in-migration 
# runReg() and outFun() functions in 1d_makeRegPanel.R # 7b_overallAnd...
rm(list = ls()); gc()
suffix <- "" # "_rB" # "_rA"
# suffix <- "_rA"
# ddOutcomes <- readRDS("9-26-23ddOutcomes_stays_2020.rds")
# ddOutcomes <- readRDS("12-19-23ddOutcomes_goes_back_2020.rds")
ddOutcomes <- readRDS(DD_OUTCOMES_GOBACK_RDS)
# 12/19/23: goes back 
tmpOut <- outFun(ddOutcomes, suffix)
# saveRDS(tmpOut, file = "9-26-23results_inMigrant_stays_2020.rds")
# saveRDS(tmpOut, file = "12-19-23results_inMigrant_goes_back_2020.rds")
saveRDS(tmpOut, file = RESULTS_GOBACK_90_RDS)

#### Part 3: excess harvest in-migration 
rm(list = ls()); gc()
distYears <- readRDS(DIST_YEARS_RDS)
# outDTF <- readRDS("9-26-23results_inMigrant_stays_2020.rds") %>%
# outDTF <- readRDS("12-19-23results_inMigrant_goes_back_2020.rds") %>%
outDTF <- readRDS(RESULTS_GOBACK_90_RDS) %>%
  mutate(distidYear = paste0(distid, "_", year)) %>%
  filter(distidYear %in% distYears)

distIDs <- unique(outDTF$distid)
newResponse <- data.frame(distid = distIDs, 
                          year = c(rep(2014, length(distIDs)), 
                                   rep(2015, length(distIDs)),
                                   rep(2016, length(distIDs)),
                                   rep(2018, length(distIDs)),
                                   rep(2019, length(distIDs)),
                                   rep(2020, length(distIDs))), 
                          maxIn = NA)

for (tmpYear in c(2014:2016, 2018:2020)) {
  for (i in 1:length(distIDs)) {
    tmpDTF <- outDTF %>%
      filter(year == tmpYear & distid == distIDs[i])
    
    if (nrow(tmpDTF) > 0) {
      tmpDTF <- tmpDTF %>%
        filter(daysFromPeak %in% 15:35) #%>%
      # filter(daysFromPeak %in% 1:45) #%>%
      newDTF <- data.frame(daysFromPeak = 15:35) %>%
        # newDTF <- data.frame(daysFromPeak = 1:45) %>%
        left_join(tmpDTF %>% select(daysFromPeak, estimate),
                  by = "daysFromPeak")
      newDTF$rollingMean <- NA
      daysToConsider <- 7 #14
      for (ii in 1:(nrow(newDTF) - daysToConsider + 1)) {
        newDTF$rollingMean[ii] <- mean(newDTF$estimate[ii:(ii + daysToConsider - 1)])
      }
      if (sum(!is.na(newDTF$rollingMean)) > 0) {
        newResponse[which(newResponse$distid == distIDs[i] & newResponse$year == tmpYear), "maxIn"] <- max(newDTF$rollingMean, na.rm = TRUE) 
      }
    }
  }
}
# saveRDS(newResponse, file = "10-16-23inMigStaysRegOutcome_2020.rds")
# saveRDS(newResponse, file = "12-19-23inMigGoesBackRegOutcome_2020.rds")
saveRDS(newResponse, file = OUTCOME_GOBACK_90_RDS)



####################### ROBUSTNESS CHECK C and D #########################
#################  Part 3: make excess harvest in-migration 
# C. 1-45 day window instead of 15-35 (part 3 of below code)
rm(list = ls()); gc()
outDTF <- readRDS(RESULTS_INMIG_RDS)

distIDs <- unique(outDTF$distid)
newResponse <- data.frame(distid = distIDs, 
                          year = c(rep(2014, length(distIDs)), 
                                   rep(2015, length(distIDs)),
                                   rep(2016, length(distIDs)),
                                   rep(2018, length(distIDs)),
                                   rep(2019, length(distIDs)),
                                   rep(2020, length(distIDs))), 
                          maxIn = NA)

for (tmpYear in c(2014:2016, 2018:2020)) {
  for (i in 1:length(distIDs)) {
    tmpDTF <- outDTF %>%
      filter(year == tmpYear & distid == distIDs[i])
    
    if (nrow(tmpDTF) > 0) {
      tmpDTF <- tmpDTF %>%
        # filter(daysFromPeak %in% 15:35) #%>%
      filter(daysFromPeak %in% 1:45) #%>%
      # newDTF <- data.frame(daysFromPeak = 15:35) %>%
        newDTF <- data.frame(daysFromPeak = 1:45) %>%
        left_join(tmpDTF %>% select(daysFromPeak, estimate),
                  by = "daysFromPeak")
      newDTF$rollingMean <- NA
      daysToConsider <- 7 #14
      for (ii in 1:(nrow(newDTF) - daysToConsider + 1)) {
        newDTF$rollingMean[ii] <- mean(newDTF$estimate[ii:(ii + daysToConsider - 1)])
      }
      if (sum(!is.na(newDTF$rollingMean)) > 0) {
        newResponse[which(newResponse$distid == distIDs[i] & newResponse$year == tmpYear), "maxIn"] <- max(newDTF$rollingMean, na.rm = TRUE) 
      }
    }
  }
}
saveRDS(newResponse, file = OUTCOME_1_45_RDS)

# D. mean over 14-day continuous period rather than 7-day (part 3 of below code)
rm(list = ls()); gc()
outDTF <- readRDS(RESULTS_INMIG_RDS)

distIDs <- unique(outDTF$distid)
newResponse <- data.frame(distid = distIDs, 
                          year = c(rep(2014, length(distIDs)), 
                                   rep(2015, length(distIDs)),
                                   rep(2016, length(distIDs)),
                                   rep(2018, length(distIDs)),
                                   rep(2019, length(distIDs)),
                                   rep(2020, length(distIDs))), 
                          maxIn = NA)

for (tmpYear in c(2014:2016, 2018:2020)) {
  for (i in 1:length(distIDs)) {
    tmpDTF <- outDTF %>%
      filter(year == tmpYear & distid == distIDs[i])
    
    if (nrow(tmpDTF) > 0) {
      tmpDTF <- tmpDTF %>%
        # filter(daysFromPeak %in% 15:35) #%>%
        filter(daysFromPeak %in% 1:45) #%>%
      # newDTF <- data.frame(daysFromPeak = 15:35) %>%
      newDTF <- data.frame(daysFromPeak = 1:45) %>%
        left_join(tmpDTF %>% select(daysFromPeak, estimate),
                  by = "daysFromPeak")
      newDTF$rollingMean <- NA
      daysToConsider <- 14
      for (ii in 1:(nrow(newDTF) - daysToConsider + 1)) {
        newDTF$rollingMean[ii] <- mean(newDTF$estimate[ii:(ii + daysToConsider - 1)])
      }
      if (sum(!is.na(newDTF$rollingMean)) > 0) {
        newResponse[which(newResponse$distid == distIDs[i] & newResponse$year == tmpYear), "maxIn"] <- max(newDTF$rollingMean, na.rm = TRUE) 
      }
    }
  }
}
saveRDS(newResponse, file = OUTCOME_1_45_14D_RDS)

############################# THIS SECTION: outcomes9 and 10: +/-14 days ############################# 
library(dplyr)
rm(list = ls()); gc()

ddOutcomes <- readRDS(DD_OUTCOMES_RDS) %>% # says 6/5/23 but updated 7/24 after Shikhar fix 
  select(-starts_with("baseline"))

### use this file above but change this code
# coefs_yyyy: 1 month before to 2 months after
# baseline_yyyy: anything within 4 months before to 2 months after
for (i in 2014:2020) {
  # ddOutcomes[, paste0("year_", i)] <- ddOutcomes[, paste0("year_", i)] - lubridate::days(14)
  ddOutcomes[, paste0("year_", i)] <- ddOutcomes[, paste0("year_", i)] + lubridate::days(14)
  ddOutcomes[, paste0("baseline_", i)] <- ifelse(ddOutcomes$date >= ddOutcomes[, paste0("year_", i)] - lubridate::days(120) & 
                                                   ddOutcomes$date <= ddOutcomes[, paste0("year_", i)] + lubridate::days(90),# change from 60 to 90
                                                 1, 0)
}

source("./makeDataHelper.R") # outFun is in here

#########
suffix <- "" # "_rB" # "_rA"
outDTF <- outFun(ddOutcomes, suffix)

# 2:13 PM - 2:20

#################  Part 3: make excess harvest in-migration 
distIDs <- unique(outDTF$distid)
newResponse <- data.frame(distid = distIDs, 
                          year = c(rep(2014, length(distIDs)), 
                                   rep(2015, length(distIDs)),
                                   rep(2016, length(distIDs)),
                                   rep(2018, length(distIDs)),
                                   rep(2019, length(distIDs)),
                                   rep(2020, length(distIDs))), 
                          maxIn = NA)

for (tmpYear in c(2014:2016, 2018:2020)) {
  for (i in 1:length(distIDs)) {
    tmpDTF <- outDTF %>%
      filter(year == tmpYear & distid == distIDs[i])
    
    if (nrow(tmpDTF) > 0) {
      tmpDTF <- tmpDTF %>%
        filter(daysFromPeak %in% 15:35) #%>%
      # filter(daysFromPeak %in% 1:45) #%>%
      newDTF <- data.frame(daysFromPeak = 15:35) %>%
        # newDTF <- data.frame(daysFromPeak = 1:45) %>%
        left_join(tmpDTF %>% select(daysFromPeak, estimate),
                  by = "daysFromPeak")
      newDTF$rollingMean <- NA
      daysToConsider <- 7 #14
      for (ii in 1:(nrow(newDTF) - daysToConsider + 1)) {
        newDTF$rollingMean[ii] <- mean(newDTF$estimate[ii:(ii + daysToConsider - 1)])
      }
      if (sum(!is.na(newDTF$rollingMean)) > 0) {
        newResponse[which(newResponse$distid == distIDs[i] & newResponse$year == tmpYear), "maxIn"] <- max(newDTF$rollingMean, na.rm = TRUE) 
      }
    }
  }
}



# saveRDS(newResponse, file = "/home/xtai/climate/3-8-23migrationCleanCode/8-9-24review1/outcome-14days.rds")

saveRDS(newResponse, file = OUTCOME_PLUS14_RDS)
