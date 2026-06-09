########################## start here ##########################
##### Part 2 of data prep: excess daily in-migration 
rm(list=ls()); gc()
source("config.R")
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
ddOutcomes <- readRDS(DD_OUTCOMES_RDS)
# ddOutcomes <- readRDS("/home/xtai/climate/3-8-23migrationCleanCode/output/7-31-23ddOutcomes_out_2020.rds")
tmpOut <- outFun(ddOutcomes, suffix)
# tmpOut %>% filter(year == 2015 & distid == 2304) ### NOTE 9/26/23: this district has one day in the baseline period with 0 in-migration, so fewer than 90 days total in baseline and was dropped. Not sure why in previous version it was not dropped. 
saveRDS(tmpOut, file = RESULTS_INMIG_RDS)
# saveRDS(tmpOut, file = "/home/xtai/climate/3-8-23migrationCleanCode/output/7-31-23results_outMigration_2020.rds")
### NOTE: out-migration gets some warning messages:
# 1: In summary.lm(fit0) :
#   essentially perfect fit: summary may be unreliable

# this for in-migration (out-migration just uses in-migration's distYears)
tmpOut <- tmpOut %>%
  mutate(distidYear = paste0(distid, "_", year)) #%>% # new for missing data
distYears <- unique(tmpOut$distidYear) # 1420 total

saveRDS(distYears, file = DIST_YEARS_RDS) 
# distYears is used for regs for fig 2


########################
rm(list=ls()); gc()
library(ggplot2); library(dplyr)

#####################################
# distYears <- readRDS("/home/xtai/climate/3-8-23migrationCleanCode/output/3-29-23distYearsIncluded.rds")

outDTF <- readRDS(RESULTS_INMIG_RDS)

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
saveRDS(newResponse, file = INMIG_OUTCOME_RDS)



################################### VIOLENCE DATA ########################################
rm(list=ls()); gc()
library(ggplot2); library(dplyr)

results2014 <- readRDS(LEGACY_RESULTS2014) # just for the names 
newViolence <- data.frame(distid = as.numeric(sub("dist_", "", names(results2014))), 
                          year = c(rep(2014, length(names(results2014))), 
                                   rep(2015, length(names(results2014))), 
                                   rep(2016, length(names(results2014))), 
                                   rep(2018, length(names(results2014))), 
                                   rep(2019, length(names(results2014))), 
                                   rep(2020, length(names(results2014)))))

bestDatesLong <- readRDS(BEST_DATES_SAT) %>%
  select(distIDs, year, maxDate) %>%
  rename("distID" = "distIDs",
         "peakNDVIdate" = "maxDate")

newViolence <- newViolence %>%
  left_join(bestDatesLong,
            by = c("distid" = "distID",
                   "year")) 
#####################################

conflictData <- read.csv(CONFLICT_CSV)
conflictDataSub <- conflictData %>%
  filter(year %in% 2013:2020 & where_prec <= 3 & date_prec <= 3) %>%
  select(DISTID, year, date_start, where_prec, date_prec, best)

countFun2 <- function(inputDistID, inputDate, dayStart = 7, dayEnd = 60) {
  dateLow <- as.Date(inputDate) + lubridate::days(dayStart) # CHANGE THIS 
  dateHigh <- as.Date(inputDate) + lubridate::days(dayEnd)
  tmpEvents <- conflictDataSub %>%
    filter(date_start >= dateLow & date_start <= dateHigh & DISTID == inputDistID)
  if (nrow(tmpEvents) > 0) {
    ret <- list(tmpEvents = nrow(tmpEvents)
                , numCasualties = sum(tmpEvents$best)
    )
    return(ret)
  } else
    return(NA)
}

newViolence$numEvents_monthBeforePeak <- 0
newViolence$numCas_monthBeforePeak <- 0

for (i in 1:nrow(newViolence)) {
  if (i %% 100 == 0) cat(i, ", ")
  tmp <- countFun2(newViolence$distid[i], as.Date(newViolence$peakNDVIdate[i]), -31, -1)
  if (!is.na(tmp[1])) {
    newViolence$numEvents_monthBeforePeak[i] <- tmp$tmpEvents
    newViolence$numCas_monthBeforePeak[i] <- tmp$numCasualties
  }
}
saveRDS(newViolence, file = VIOLENCE_DEST_RDS)

