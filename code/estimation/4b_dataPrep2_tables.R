#### data prep for outcomes7 and 8: k = 15 and k = 45
# 11/14/24: start rerunning code from 7a

rm(list=ls()); gc()
library(dplyr); library(ggplot2)
source("config.R")

# fileList <- list.files(CDR_K15_DIR) 
fileList <- list.files(CDR_K45_DIR) 

# tmpFile <- read.csv(file.path(CDR_K15_DIR, fileList[1]))
tmpFile <- read.csv(file.path(CDR_K45_DIR, fileList[1]))

outData <- tmpFile %>%
  group_by(destination_district, visit_day) %>% # now aggregate
  summarize(
    # numAround = sum(visits, na.rm = TRUE), # update 6/5/23: this is not used for anything 
    numNew = sum(visits[which(origin_district != destination_district)], na.rm = TRUE)
  )

options(dplyr.summarise.inform = FALSE)
Sys.time()
for (i in 2:length(fileList)) {
  if (i %% 200 == 0) cat(i, ", ")
  # tmpFile <- read.csv(file.path(CDR_K15_DIR, fileList[i]))
  tmpFile <- read.csv(file.path(CDR_K45_DIR, fileList[i]))
  
  tmpData <- tmpFile %>%
    group_by(destination_district, visit_day) %>% # now aggregate
    summarize(
      # numAround = sum(visits, na.rm = TRUE),
      numNew = sum(visits[which(origin_district != destination_district)], na.rm = TRUE)
    )
  outData <- outData %>%
    bind_rows(tmpData)
}
Sys.time()
# 14 minutes

outData <- outData %>%
  mutate(date = as.Date("2013-04-01") + lubridate::days(visit_day - 1)) 
# saveRDS(outData, file = K15_INMIG_RDS)
saveRDS(outData, file = K45_INMIG_RDS)

################## impacted: 
# fileList <- list.files(CDR_K15_DIR)
# tmpFile <- read.csv(file.path(CDR_K15_DIR, fileList[1]))
fileList <- list.files(CDR_K45_DIR)
tmpFile <- read.csv(file.path(CDR_K45_DIR, fileList[1]))
getImpacted <- tmpFile %>%
  distinct(origin_district, impact_day, impacted)

Sys.time()
for (i in 2:length(fileList)) {
  if (i %% 200 == 0) cat(i, ", ")
  # tmpFile <- read.csv(file.path(CDR_K15_DIR, fileList[i]))
  tmpFile <- read.csv(file.path(CDR_K45_DIR, fileList[i]))
  tmpData <- tmpFile %>%
    distinct(origin_district, impact_day, impacted)
  getImpacted <- getImpacted %>%
    bind_rows(tmpData)
}
Sys.time()

# saveRDS(getImpacted, file = K15_IMPACTED_RDS)
saveRDS(getImpacted, file = K45_IMPACTED_RDS)
# 10 minutes  

####################################################################################
rm(list=ls()); gc()
#### harvest dates
bestDatesLong <- readRDS(BEST_DATES_SAT) %>%
  select(distIDs, year, maxDate) %>%
  # select(-pctPoppy, -modeSecond) %>%
  # select(-pctPoppy) %>%
  rename("distID" = "distIDs",
         "date" = "maxDate")

bestDatesWide <- bestDatesLong %>%
  # select(-bestDatesM1) %>%
  tidyr::pivot_wider(names_from = "year",
                     values_from = "date",
                     # values_from = "bestDatesM2",
                     names_prefix = "year_")


### for in-migration
# outData <- readRDS(K15_INMIG_RDS)
outData <- readRDS(K45_INMIG_RDS)

getImpacted <- readRDS(K45_IMPACTED_RDS) %>% # 581478 rows
# getImpacted <- readRDS(K15_IMPACTED_RDS) %>% # 581478 rows
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

ddOutcomes <- ddOutcomes %>%
  left_join(bestDatesWide,
            by = c("district_id" = "distID")) %>%
  mutate(across(where(is.character), as.Date))

ddOutcomes <- ddOutcomes %>%
  data.frame()

# coefs_yyyy: 1 month before to 2 months after
# baseline_yyyy: anything within 4 months before to 2 months after
for (i in 2014:2020) {
  ddOutcomes[, paste0("baseline_", i)] <- ifelse(ddOutcomes$date >= ddOutcomes[, paste0("year_", i)] - lubridate::days(120) & 
                                                   ddOutcomes$date <= ddOutcomes[, paste0("year_", i)] + lubridate::days(90),# change from 60 to 90
                                                 1, 0)
}

# saveRDS(ddOutcomes, file = DD_OUTCOMES_K15_RDS) 
saveRDS(ddOutcomes, file = DD_OUTCOMES_K45_RDS) 

###### now code from 7b
########################## start here ##########################
##### Part 2 of data prep: excess daily in-migration 
rm(list=ls()); gc()
# this function has a line that manually needs to be replaced for out-migration 
runReg <- function(inputDistid, ddOutcomes, suffix) {
  
  tryThis <- ddOutcomes %>%
    filter(district_id == inputDistid & baseline == 1) %>%
    select(date, percentage, harvestDate) %>%
    mutate(daysFromPeak = as.numeric(date - harvestDate))
  
  tryThis$daysFromPeak[tryThis$daysFromPeak < -30 ] <- -31
  
  # 12/20/23: note that the robustness check letters A and B are superseded and no longer correspond to any robustness checks in the paper. The code is retained since different versions are used for different outcome variables. 
  if (suffix == "_rA") {
    regData <- tryThis[which(!is.na(tryThis$percentage) 
                             # & tryThis$percentage != 0 # robustness check A + source: remove this line
                             & tryThis$percentage != 1), ]
    
  } else {
    regData <- tryThis[which(!is.na(tryThis$percentage) 
                             & tryThis$percentage != 0 # robustness check A + source: remove this line
                             & tryThis$percentage != 1), ]
  }
  
  if (suffix == "_rB") {
    if (nrow(regData) > 0 & length(unique(regData$daysFromPeak)) > 1 
        & sum(regData$daysFromPeak == -31) >= 45 # robustness check B: add this line
        # & sum(regData$daysFromPeak == -31) >= 90 # robustness check B: remove this line
        & sum(regData$daysFromPeak %in% 15:35) >= 7 # remove this line as necessary:
        # remove for out-migration
        # keep for in-migrant stays, source conflict
    ) {
      # fit0 <- lm(log(percentage/(1 - percentage)) ~ as.factor(daysFromPeak), 
      # data = regData)
      fit0 <- lm(percentage ~ as.factor(daysFromPeak), 
                 data = regData)
      
      tmpOut <- summary(fit0)$coefficients[-1, ] # -1 to get rid of the intercept 
      
      forPlot <- data.frame(daysFromPeak = as.numeric(sub(pattern = "as.factor(daysFromPeak)", "", rownames(tmpOut), fixed = TRUE)), 
                            estimate = as.vector(tmpOut[, "Estimate"]), 
                            se = as.vector(tmpOut[, "Std. Error"]),
                            stringsAsFactors = FALSE) %>%
        mutate(conf.low = estimate - qnorm(.975)*se,
               conf.high = estimate + qnorm(.975)*se)
      
      return(forPlot)
    } else {
      return(NULL)
    }
  } else {
    if (nrow(regData) > 0 & length(unique(regData$daysFromPeak)) > 1 
        # & sum(regData$daysFromPeak == -31) >= 45 # robustness check B: add this line
        & sum(regData$daysFromPeak == -31) >= 90 # robustness check B: remove this line
        & sum(regData$daysFromPeak %in% 15:35) >= 7 # remove this line as necessary:
        # remove for out-migration
        # keep for in-migrant stays, source conflict
    ) {
      # fit0 <- lm(log(percentage/(1 - percentage)) ~ as.factor(daysFromPeak), 
      # data = regData)
      fit0 <- lm(percentage ~ as.factor(daysFromPeak), 
                 data = regData)
      
      tmpOut <- summary(fit0)$coefficients[-1, ] # -1 to get rid of the intercept 
      
      forPlot <- data.frame(daysFromPeak = as.numeric(sub(pattern = "as.factor(daysFromPeak)", "", rownames(tmpOut), fixed = TRUE)), 
                            estimate = as.vector(tmpOut[, "Estimate"]), 
                            se = as.vector(tmpOut[, "Std. Error"]),
                            stringsAsFactors = FALSE) %>%
        mutate(conf.low = estimate - qnorm(.975)*se,
               conf.high = estimate + qnorm(.975)*se)
      
      return(forPlot)
    } else {
      return(NULL)
    }
    
  }
}

# need to change a line for out-migration 
outFun <- function(ddOutcomes, suffix) {
  distIDs <- unique(ddOutcomes$district_id)
  for (tmpYear in c(2014:2016, 2018:2020)) {
    cat("Year =", tmpYear, " ")
    myResults <- vector(mode = "list", length = length(distIDs))
    names(myResults) <- paste0("dist_", distIDs)
    
    ddOutcomes$harvestDate <- ddOutcomes[, paste0("year_", tmpYear)]
    ddOutcomes$baseline <- ddOutcomes[, paste0("baseline_", tmpYear)]
    ddOutcomes$percentage <- ddOutcomes$percentage_in # replace this for out-migration
    # ddOutcomes$percentage <- ddOutcomes$percentage_migrated # replace this for out-migration
    
    for (i in 1:length(distIDs)) {
      if (i %% 100 == 0) cat(i, ", ")
      out <- runReg(distIDs[i], ddOutcomes, suffix)
      if (!is.null(out)) {
        myResults[[i]] <- out
      }
    }
    assign(paste0("results", tmpYear), myResults) # new line 
    
  }
  
  ###### here basically cbind all district years
  tmpDistIDs <- as.numeric(sub("dist_", "", names(results2014))) # this will be the same for all years because of how names were constructed (see loop above)
  
  for (i in 1:length(tmpDistIDs)) {
    if (!is.null(results2014[[i]])) {
      results2014[[i]]$distid <- tmpDistIDs[i]
      results2014[[i]]$year <- 2014
    }
    if (!is.null(results2015[[i]])) {
      results2015[[i]]$distid <- tmpDistIDs[i]
      results2015[[i]]$year <- 2015
    }
    if (!is.null(results2016[[i]])) {
      results2016[[i]]$distid <- tmpDistIDs[i]
      results2016[[i]]$year <- 2016
    }
    if (!is.null(results2018[[i]])) {
      results2018[[i]]$distid <- tmpDistIDs[i]
      results2018[[i]]$year <- 2018
    }
    if (!is.null(results2019[[i]])) {
      results2019[[i]]$distid <- tmpDistIDs[i]
      results2019[[i]]$year <- 2019
    }
    if (!is.null(results2020[[i]])) {
      results2020[[i]]$distid <- tmpDistIDs[i]
      results2020[[i]]$year <- 2020
    }
  }
  
  outDTF <- do.call("rbind", results2014)
  outDTF <- rbind(outDTF, do.call("rbind", results2015))
  outDTF <- rbind(outDTF, do.call("rbind", results2016))
  outDTF <- rbind(outDTF, do.call("rbind", results2018))
  outDTF <- rbind(outDTF, do.call("rbind", results2019))
  outDTF <- rbind(outDTF, do.call("rbind", results2020))
  
  return(outDTF)
}

#########
### NOTE WHEN DOING FOR OUT-MIGRATION: need to manually change two lines in outFun() and runReg()
suffix <- "" # "_rB" # "_rA"
# ddOutcomes <- readRDS(DD_OUTCOMES_K15_RDS)
ddOutcomes <- readRDS(DD_OUTCOMES_K45_RDS)
tmpOut <- outFun(ddOutcomes, suffix)
# saveRDS(tmpOut, file = RESULTS_INMIG_K15_RDS)
saveRDS(tmpOut, file = RESULTS_INMIG_K45_RDS)

########################
rm(list=ls()); gc()
library(ggplot2); library(dplyr)

#####################################

# outDTF <- readRDS(RESULTS_INMIG_K15_RDS)
outDTF <- readRDS(RESULTS_INMIG_K45_RDS)

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
# saveRDS(newResponse, file = OUTCOME_K15_RDS)
saveRDS(newResponse, file = OUTCOME_K45_RDS)
