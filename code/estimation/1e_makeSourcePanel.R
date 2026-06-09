
# this file preps source
rm(list = ls()); gc()
library(ggplot2); library(dplyr)
source("config.R")

covariates <- readRDS(COVARIATES_RDS) %>% # has poppyCat from years 2014 to 2020 by district 
  select(-geometry)

###### 4/25/23: H, taliban and violence
sigarControl <- read.csv(SIGAR_CSV) %>%
  mutate(talibanConInf = ifelse(Oct.2017.Assessment %in% c("INS Control", "INS In!uence"), 1, 0),
         notGovt = ifelse(Oct.2017.Assessment %in% c("INS Control", "INS In!uence", "Contested"), 1, 0))

#### violence at source
# need to make conflict data in the form
# distid, date (floor month), violenceBinary
conflictData <- read.csv(CONFLICT_CSV)
conflictDataSub <- conflictData %>%
  filter(year %in% 2013:2020 & where_prec <= 3 & date_prec <= 3) %>% # change from 2020 to 2017 to limit computation
  select(DISTID, date_start) %>%
  unique()
# length(unique(paste0(conflictDataSub$DISTID, conflictDataSub$date_start))) # 7179

conflictDataSub$date_start <- as.Date(conflictDataSub$date_start)
# conflictDataSub$date <- lubridate::floor_date(as.Date(conflictDataSub$date_start), "month")

# want it such that conflict event counts for dates that are k = 1 to 30 and then move on day 31
# tmpDate <- conflictDataSub$date_start[1] 
# seq(from = tmpDate - lubridate::days(29), to = tmpDate) # this will give a sequence of 30 days that the event counts for 

# expand each date start to 30 days 
tmp <- sapply(conflictDataSub$date_start, FUN = function(x) seq(from = x, to = x + lubridate::days(29), by = 1), simplify = FALSE) # each event counts for day 1-30, i.e., origin date: Check if any event within last 30 days
out <- do.call(rbind, tmp)

out <- cbind(conflictDataSub$DISTID, out)
out <- data.frame(out)
names(out)[1] <- "distid"

outLong <- out %>%
  tidyr::pivot_longer(cols = starts_with("X"), 
                      names_to = "year", 
                      values_to = "date") %>%
  select(-year) %>%
  unique()

outLong$date <- as.Date(outLong$date, origin = "1970-01-01")
outLong$violence <- 1

fileList <- list.files(CDR_K30_DIR)

sourceFun <- function(fileName) {
  # first fix the data issues 
  tmpFile <- read.csv(file.path(CDR_K30_DIR, fileName))
  if (nrow(tmpFile) != 398*398) {
    stop(paste0(fileName, ": wrong number of rows"))
  }
  
  tmpFile <- tmpFile %>%
    filter(origin_district != destination_district & !is.na(visits) & visits != 0) 
  if (nrow(tmpFile) == 0) {
    cat(paste0(fileName, ": no moves"))
    return(NULL)
  } else {
    k30data <- tmpFile %>%
      left_join(sigarControl %>% 
                  select(distid, notGovt), 
                by = c("origin_district" = "distid")) %>%
      mutate(origin_date = as.Date("2013-04-01") + lubridate::days(impact_day - 1),
             origin_year = lubridate::year(origin_date),
             origin_month = lubridate::month(origin_date)) %>%
      mutate(origin_year = ifelse(origin_month >= 8, origin_year + 1, origin_year)) %>% # this is equivalent to september and later in destination --- this works 
      left_join(outLong,
                by = c("origin_district" = "distid",
                       "origin_date" = "date")) %>% # origin_district at destination's harvest month
      # mutate(violence = ifelse(violence == 1, 1, 0)) %>% # this does nothing --- NAs are left as NA
      left_join(covariates %>%
                  select(distid, year, poppyCat),
                by = c("origin_district" = "distid", "origin_year" = "year")) %>% 
      group_by(destination_district, visit_day) %>% # now aggregate
      summarize(
        # fromHigh = sum(visits[which(poppyCat == "H")]),
        # fromLow = sum(visits[which(poppyCat == "L")]),
        # fromHighV_Taliban = sum(visits[which(poppyCat == "H" & violence == 1 & notGovt == 1)]),
        # fromHighV_NonTaliban = sum(visits[which(poppyCat == "H" & violence == 1 & notGovt == 0)]),
        # fromHighNonV_Taliban = sum(visits[which(poppyCat == "H" & is.na(violence) & notGovt == 1)]),
        # fromHighNonV_NonTaliban = sum(visits[which(poppyCat == "H" & is.na(violence) & notGovt == 0)]),
        numNew = sum(visits) # this should be the same as before 
      ) %>%
      mutate(date = as.Date("2013-04-01") + lubridate::days(visit_day - 1))
    return(k30data)    
  }
}

myList <- vector(mode = "list", length = length(fileList))
options(dplyr.summarise.inform = FALSE)
# system.time(myList <- lapply(fileList, FUN = sourceFun))
# started 4:33PM

Sys.time()
for (i in 1:length(fileList)) {
  if (i %% 50 == 0) cat(i, ", ")
  myList[[i]] <- sourceFun(fileList[i])
}
Sys.time()
# "2023-06-05 16:58:54 PDT" (25 minutes)

# impact days 1424 to 1468: no moves (2017-02-22)
# also impact days 2741 to 2770 (end of panel)

# do an lapply and do.call rbind
k30data <- do.call(rbind, myList)

k30data <- k30data %>%
  mutate(#propHigh = fromHigh / numNew,
    #propLow = fromLow / numNew,
         # propHighV_Taliban = fromHighV_Taliban / numNew,
         # propHighV_NonTaliban = fromHighV_NonTaliban / numNew,
         # propHighNonV_Taliban = fromHighNonV_Taliban / numNew,
         # propHighNonV_NonTaliban = fromHighNonV_NonTaliban / numNew,

  ) %>% 
  rename(district_id = destination_district) %>%
  ungroup()


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

ddOutcomes <- k30data %>%
  left_join(bestDatesWide,
            by = c("district_id" = "distID")) %>%
  mutate(across(where(is.character), as.Date)) %>%
  as.data.frame()

# baseline_yyyy: anything within 4 months before to 3 months after
for (i in 2014:2020) {
  ddOutcomes[, paste0("baseline_", i)] <- ifelse(ddOutcomes$date >= ddOutcomes[, paste0("year_", i)] - lubridate::days(120) & 
                                                   ddOutcomes$date <= ddOutcomes[, paste0("year_", i)] + lubridate::days(90),# change from 60 to 90
                                                 1, 0)
}

saveRDS(ddOutcomes, file = DD_OUTCOMES_VIOLENCE_RDS)

# saveRDS(ddOutcomes, file = "/home/xtai/climate/3-8-23migrationCleanCode/output/1-8-24ddOutcomes_violence_L_T_2020.rds")


########### 4/25/23: violence H_Taliban
# outFun is defined in 1d_makeRegPanel.R #7b_overallAndViolenceResults.R
# ***source results use _rA version***

### NOTE: these produce warnings(): In summary.lm(fit0) : essentially perfect fit: summary may be unreliable

suffix <- "_rA"# "" # "_rB" # 
ddOutcomes <- readRDS(DD_OUTCOMES_VIOLENCE_RDS) %>%
  rename(percentage_in = propHighV_Taliban)
tmpOut <- outFun(ddOutcomes, suffix)
saveRDS(tmpOut, file = paste0(RESULTS_HVT_BASE, suffix, "_2020.rds"))

ddOutcomes <- readRDS(DD_OUTCOMES_VIOLENCE_RDS) %>%
  rename(percentage_in = propHighV_NonTaliban)
tmpOut <- outFun(ddOutcomes, suffix)
saveRDS(tmpOut, file = paste0(RESULTS_HVNONT_BASE, suffix, "_2020.rds"))

ddOutcomes <- readRDS(DD_OUTCOMES_VIOLENCE_RDS) %>%
  rename(percentage_in = propHighNonV_Taliban)
tmpOut <- outFun(ddOutcomes, suffix)
saveRDS(tmpOut, file = paste0(RESULTS_HNONVT_BASE, suffix, "_2020.rds"))

ddOutcomes <- readRDS(DD_OUTCOMES_VIOLENCE_RDS) %>%
  rename(percentage_in = propHighNonV_NonTaliban)
tmpOut <- outFun(ddOutcomes, suffix)
saveRDS(tmpOut, file = paste0(RESULTS_HNONVNONT_BASE, suffix, "_2020.rds"))
# then go to 4a_sourceFigsRegs.R


#### HIGH/LOW
suffix <- "_rA"# "" # "_rB" # 
ddOutcomes <- readRDS(DD_OUTCOMES_CHECK_RDS) %>%
  rename(percentage_in = propHigh)
tmpOut <- outFun(ddOutcomes, suffix)
saveRDS(tmpOut, file = paste0(RESULTS_H_CHECK_BASE, suffix, "_2020_check.rds")) 

suffix <- "_rA"# "" # "_rB" # 
ddOutcomes <- readRDS(DD_OUTCOMES_CHECK_RDS) %>%
  rename(percentage_in = propLow)
tmpOut <- outFun(ddOutcomes, suffix)
saveRDS(tmpOut, file = paste0(RESULTS_L_CHECK_BASE, suffix, "_2020_check.rds"))


################# violence H T # this code from 4a
rm(list = ls()); gc()
tmpFun <- function(outDTF) {
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
  return(newResponse)
}
suffix <- "_rA"#  ""  # "_rB"#  
out1 <- readRDS(paste0(RESULTS_HVT_BASE, suffix, "_2020.rds"))
out2 <- readRDS(paste0(RESULTS_HVNONT_BASE, suffix, "_2020.rds"))
out3 <- readRDS(paste0(RESULTS_HNONVT_BASE, suffix, "_2020.rds"))
out4 <- readRDS(paste0(RESULTS_HNONVNONT_BASE, suffix, "_2020.rds"))
outFiles <- c(paste0(SUBGROUP_HVT_BASE, suffix, "_2020.rds"),
              paste0(SUBGROUP_HVNONT_BASE, suffix, "_2020.rds"),
              paste0(SUBGROUP_HNONVT_BASE, suffix, "_2020.rds"),
              paste0(SUBGROUP_HNONVNONT_BASE, suffix, "_2020.rds"))
for (i in 1:4) {
  cat(i, ", ")
  newResponse <- tmpFun(get(paste0("out", i)))
  saveRDS(newResponse, file = outFiles[i])
}


# high/low
suffix <- "_rA"#  ""  # "_rB"#  
out1 <- readRDS(paste0(RESULTS_H_CHECK_BASE, suffix, "_2020_check.rds"))
out2 <- readRDS(paste0(RESULTS_L_CHECK_BASE, suffix, "_2020_check.rds"))
outFiles <- c(paste0(SUBGROUP_H_CHECK_BASE, suffix, "_2020_check.rds"),
              paste0(SUBGROUP_L_CHECK_BASE, suffix, "_2020_check.rds"))
for (i in 1:2) {
  cat(i, ", ")
  newResponse <- tmpFun(get(paste0("out", i)))
  saveRDS(newResponse, file = outFiles[i])
}

