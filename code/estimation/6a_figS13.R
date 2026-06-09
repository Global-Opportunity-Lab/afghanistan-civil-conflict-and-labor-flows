
# this file preps source
rm(list = ls()); gc()
library(ggplot2); library(dplyr)
source("config.R")

bestDatesLong <- readRDS(BEST_DATES_SAT) %>%
  select(distIDs, year, maxDate) %>%
  rename("distID" = "distIDs",
         "date" = "maxDate")

tmp <- bestDatesLong %>% 
  filter(year == 2015)
min(tmp$date, na.rm = TRUE) # "2015-01-01"
max(tmp$date, na.rm = TRUE) # "2015-05-25"
# > as.Date("2015-01-01")- lubridate::days(120)
# [1] "2014-09-03"
# > as.Date("2015-05-25") +lubridate::days(90)
# [1] "2015-08-23"

as.Date("2013-04-01") + lubridate::days(521 - 1) # "2014-09-03"
as.Date("2013-04-01") + lubridate::days(875 - 1) # "2015-08-23"
# as.Date("2015-08-23") - as.Date("2013-04-01")

# i.e., need impact days 521:875 (355 days)

# fileList <- list.files(CDR_K30_DIR)

ODfun <- function(impactDay) {
  # first fix the data issues 
  tmpFile <- read.csv(file.path(CDR_K30_DIR, paste0("impact_day_", impactDay, ".csv")))
  if (nrow(tmpFile) != 398*398) {
    stop(paste0(impactDay, ": wrong number of rows"))
  }
  
  tmpFile <- tmpFile %>%
    filter(origin_district != destination_district & !is.na(visits) & visits != 0) 
  if (nrow(tmpFile) == 0) {
    cat(paste0(impactDay, ": no moves"))
    return(NULL)
  } else {
    k30data <- tmpFile %>%
      mutate(origin_date = as.Date("2013-04-01") + lubridate::days(impact_day - 1),
             origin_year = lubridate::year(origin_date),
             origin_month = lubridate::month(origin_date)) %>%
      mutate(origin_year = ifelse(origin_month >= 8, origin_year + 1, origin_year)) %>% # this is equivalent to september and later in destination --- this works 
      mutate(date = as.Date("2013-04-01") + lubridate::days(visit_day - 1))
    return(k30data)    
  }
}

impactDays <- 521:875
myList <- vector(mode = "list", length = length(impactDays))
options(dplyr.summarise.inform = FALSE)
# system.time(myList <- lapply(fileList, FUN = sourceFun))
# started 4:33PM

Sys.time()
for (i in 1:length(impactDays)) {
  if (i %% 50 == 0) cat(i, ", ")
  myList[[i]] <- ODfun(impactDays[i])
}
Sys.time()

# do an lapply and do.call rbind
k30data <- do.call(rbind, myList) # 3041488 entries

k30data <- k30data %>%
  rename(district_id = destination_district)

#### harvest dates
bestDatesWide <- bestDatesLong %>% 
  filter(year == 2015) %>%
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
for (i in 2015) {
  ddOutcomes[, paste0("baseline_", i)] <- ifelse(ddOutcomes$date >= ddOutcomes[, paste0("year_", i)] - lubridate::days(120) & 
                                                   ddOutcomes$date <= ddOutcomes[, paste0("year_", i)] + lubridate::days(90),# change from 60 to 90
                                                 1, 0)
}

ddOutcomes <- ddOutcomes %>%
  filter(baseline_2015 == 1)
# 1791175 rows 

saveRDS(ddOutcomes, file = OD_RAW_RDS)

########################################################################################
rm(list = ls()); gc()
ddOutcomes <- readRDS(OD_RAW_RDS)
ddOutcomes <- ddOutcomes %>%
  select(origin_district, district_id, impacted, visits, origin_date, date, year_2015) %>%
  rename(bestDate2015 = year_2015) # district_id is the destination, date is destination date (visit_date)

# we need numNew
checkFile <- readRDS(DD_OUTCOMES_VIOLENCE_RDS) %>%
  select(district_id, date, numNew) # date here is the visit_date, district_id is destination

ddOutcomes <- ddOutcomes %>%
  left_join(checkFile,
            by = c("district_id", "date"))

ddOutcomes <- ddOutcomes %>%
  mutate(propVisits = visits/numNew) %>%
  mutate(daysFromPeak = as.numeric(date - bestDate2015))

# summary(ddOutcomes$propVisits)
# sum(ddOutcomes$propVisits == 1) # 127

# some numNew are in the single digits
# summary(ddOutcomes$numNew)

#### make baseline 
myFun <- function(varName) {
  tmpddOutcomes <- ddOutcomes 
  names(tmpddOutcomes)[names(tmpddOutcomes) == varName] <- "percentage_in"
  
  baseline <- tmpddOutcomes %>%
    select(origin_district, district_id, percentage_in, daysFromPeak) %>%
    filter(daysFromPeak %in% -120:-31) %>%
    filter(!is.na(percentage_in)  # no NA anyway 
           & percentage_in != 1) %>%
    group_by(origin_district, district_id) %>%
    summarize(numObs = n(),
              baseline = mean(percentage_in)) 
  
  names(baseline)[names(baseline) == "percentage_in"] <- varName
  return(baseline)
}
out <- myFun("propVisits")

length(unique(out$origin_district)) # 238
length(unique(out$district_id)) # 237


# outcome1 <- readRDS(paste0(SUBGROUP_HVT_BASE, "_rA", "_2020.rds")) %>%
#   filter(year == 2015) %>%# 280 obs
#   filter(!is.na(maxIn))
# sum(!is.na(outcome1$maxIn))
# # [1] 231

##### this for harvest
# give it ddOutcomes
out$harvest <- NA

for (i in 1:nrow(out)) {
  if (i %% 500 == 0) cat(i, ", ")
  tmpDTF <- ddOutcomes %>%
    filter(propVisits != 1) %>% # was missing this the first time 
    filter(origin_district == out$origin_district[i] & 
             district_id == out$district_id[i] & 
             daysFromPeak %in% 15:35)
  
  if (nrow(tmpDTF) > 0) {
    newDTF <- data.frame(daysFromPeak = 15:35) %>%
      left_join(tmpDTF %>% 
                  select(daysFromPeak, propVisits),
                by = "daysFromPeak")
    newDTF$rollingMean <- NA
    daysToConsider <- 7 #14
    for (ii in 1:(nrow(newDTF) - daysToConsider + 1)) {
      newDTF$rollingMean[ii] <- mean(newDTF$propVisits[ii:(ii + daysToConsider - 1)])
    }
    if (sum(!is.na(newDTF$rollingMean)) > 0) {
      out$harvest[i] <- max(newDTF$rollingMean, na.rm = TRUE)
    }
  }
}
# 3:48 pm
# 4:09 pm

out$diff <- out$harvest - out$baseline

saveRDS(out, file = OD_OUT_RDS)

########################################################################################
rm(list = ls()); gc()
out <- readRDS(OD_OUT_RDS)
out <- out %>%
  ungroup()

covariates <- readRDS(COVARIATES_RDS) %>% # has poppyCat from years 2014 to 2020 by district 
  select(-geometry) %>%
  filter(year == 2015) %>%
  select(distid, poppyCat)

districtInfo <- readRDS(DISTRICT_IDS)
covariates <- covariates %>%
  left_join(districtInfo %>%
              select(prov_name, dist_name, distid, provid),
            by = "distid")

covariates$label <- NA
covariates$label[covariates$poppyCat == "H"] <- "0_High"
covariates$label[covariates$poppyCat != "H"] <- covariates$prov_name[covariates$poppyCat != "H"]

out <- out %>%
  left_join(covariates %>%
              select(distid, label),
            by = c("district_id" = "distid")) %>%
  rename(destination_label = label) %>%
  left_join(covariates %>%
              select(distid, label),
            by = c("origin_district" = "distid")) %>%
  rename(origin_label = label) 

out$district_id <- as.factor(out$district_id)
out$district_id <- with(out, reorder(district_id, as.numeric(as.factor(out$destination_label))))

out$origin_district <- as.factor(out$origin_district)
out$origin_district <- with(out, reorder(origin_district, as.numeric(as.factor(out$origin_label))))

# levels(out$origin_district)

sourceLabels <- data.frame(breaks = levels(out$origin_district)) %>%
  mutate(distid = as.numeric(breaks)) %>%
  left_join(covariates %>%
              select(distid, label),
            by = c("distid")) 
sourceLabels <- sourceLabels %>%
  mutate(previousLabel = c(NA, sourceLabels$label[-length(sourceLabels$label)])) %>%
  mutate(finalLabel = ifelse(label != previousLabel, label, NA))
sourceLabels$finalLabel[1] <- "High-cultivation" 
sourceLabels$finalLabel[sourceLabels$finalLabel == "Baghlan"] <- "\nBaghlan"
sourceLabels$finalLabel[sourceLabels$finalLabel == "Farah"] <- "\nFarah" 
sourceLabels$finalLabel[sourceLabels$finalLabel == "Faryab"] <- "\n\nFaryab" 

sourceLabels$finalLabel[sourceLabels$finalLabel == "Paktika"] <- "\nPaktika" 

destinationLabels <- data.frame(breaks = levels(out$district_id)) %>%
  mutate(distid = as.numeric(breaks)) %>%
  left_join(covariates %>%
              select(distid, label),
            by = c("distid")) 
destinationLabels <- destinationLabels %>%
  mutate(previousLabel = c(NA, destinationLabels$label[-length(destinationLabels$label)])) %>%
  mutate(finalLabel = ifelse(label != previousLabel, label, NA))
destinationLabels$finalLabel[1] <- "High-cultivation" 

destinationLabels$finalLabel[destinationLabels$finalLabel == "Baghlan"] <- "\nBaghlan" 
destinationLabels$finalLabel[destinationLabels$finalLabel == "Farah"] <- "\nFarah" 
destinationLabels$finalLabel[destinationLabels$finalLabel == "Faryab"] <- "\n\nFaryab" 
destinationLabels$finalLabel[destinationLabels$finalLabel == "Paktika"] <- "\nPaktika" 


pdf(file.path(OUT_REVIEW1, "ODmatrix.pdf"), width = 12, height = 10)
out %>%
  # filter(numObs >= 40) %>% # change this 
  mutate(diff = ifelse(diff > .025, .025, diff)) %>%
  mutate(diff = ifelse(diff < -.025, -.025, diff)) %>%
  # slice(1:2000) %>%
  # mutate(distid = ifelse(distid == 1115, 0, distid)) %>% # hack so that 1115 appears below
  # mutate(val = ifelse(is.na(year), 0, 1),
         # distid = as.factor(distid)) %>%
  ggplot(aes(x = district_id, y = origin_district, fill = diff)) + 
  geom_tile() +
  # scale_x_date(labels=scales::date_format(format = "%m/%Y"), breaks = scales::date_breaks(width = "2 months"), expand = c(.02, .02)) +
  # theme_light() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        panel.background = element_blank(), axis.line = element_line(colour = "black")) +
  theme(axis.text.x = element_text(angle = 90, size = 8)) + #,
        # legend.position = "none") +
  colorspace::scale_fill_continuous_diverging(palette = "Blue-Red",
                                              alpha = 1,
                                              name = "Harvest-baseline",
                                              # limits = c(-.05, .05),
                                              mid = 0,
                                              rev = TRUE,
                                              na.value = "transparent") +
  # scale_fill_manual(values = c("white", "black")) +
  # geom_vline(xintercept = seq(as.Date("2015-01-01"), as.Date("2020-01-01"), "1 year")) +
  labs(x = "Destination", y = "Source") +
  scale_y_discrete(breaks = sourceLabels$breaks[!is.na(sourceLabels$finalLabel)], 
                   labels = sourceLabels$finalLabel[!is.na(sourceLabels$finalLabel)]) +
  scale_x_discrete(breaks = destinationLabels$breaks[!is.na(destinationLabels$finalLabel)], 
                   labels = destinationLabels$finalLabel[!is.na(destinationLabels$finalLabel)]) +
  theme(axis.text.x = element_text(hjust = 1,
                                   lineheight = 0.5,
                                   vjust = .5)) +
  theme(axis.text.y = element_text(size = 8,
                                   lineheight = 4,
                                   vjust = -.05))
dev.off()

