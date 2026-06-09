# 1a_covariates.R
# Builds the district-year covariates panel used throughout the analysis.
# Inputs:  DISTRICT_IDS, POPPY_CSV, AG_HECTARES_RDS, AFG_SHAPE_DATA, AGR_PIXELS, SIGAR_CSV
# Outputs: COVARIATES_RDS

rm(list = ls()); gc()
library(ggplot2); library(dplyr)
source("config.R")

### covariates of interest: areakm2, nonPoppy (agHectares - poppy), TOTAL
# new variables to add:
# 2. area
# 3. agricultural area
# 4. derived vars: population density, cultivation density, fraction of poppy/agricultural areas

#### input data sets
districtInfo <- readRDS(DISTRICT_IDS)
unodcData <- read.csv(POPPY_CSV)
agHectaresLong <- readRDS(AG_HECTARES_RDS)
load(AFG_SHAPE_DATA)
agrPixels <- readRDS(AGR_PIXELS) %>% # this has areakm2 that is calculated using sf (see screenshot) 
  select(DISTID, areakm2)


################ wide to long
# poppy data
poppyLong <- unodcData %>%
  tidyr::pivot_longer(cols = starts_with("X"), 
                      names_to = "year", 
                      names_prefix = "X", 
                      names_transform = list(year = as.numeric),
                      values_to = "poppy") %>%
  filter(year %in% 2014:2020) 
# 398*7 years = 2786 rows --- correct

### check: 1000 is roughly top decile 
tmp <- poppyLong$poppy
tmp[is.na(tmp)] <- 0
quantile(tmp, .9)
#    90% 
# 1065.5 

##########################################
covariates <- data.frame(distid = districtInfo$distid, 
                         year = c(rep(2014, 398), rep(2015, 398), rep(2016, 398),
                                  rep(2017, 398), rep(2018, 398), rep(2019, 398),
                                  rep(2020, 398)))
# 2786 obs

########## join everything 
covariates <- covariates %>%
  left_join(districtInfo %>%
              select(distid, provincialCapital, TOTAL, region), by = c("distid")) %>%
  left_join(poppyLong, 
            by = c("distid", "year")) %>%
  mutate(tmpPoppy = ifelse(!is.na(poppy), poppy, 0)) %>%
  left_join(agHectaresLong,
            by = c("distid" = "distIDs",
                   "year")) %>%
  mutate(nonPoppy2 = agHectares - tmpPoppy) %>%
  mutate(nonPoppy2 = ifelse(nonPoppy2 <= 0, 1, nonPoppy2)) %>%
  left_join(afghanShape %>% 
              select(DISTID, diversity, cultivatedFrac, roadDensity, builtUpFracPop, trackPathFrac, healthPer100000, majority, barrenAreaFrac),
            by = c("distid" = "DISTID")) %>%
  mutate(poppyCat = ifelse(tmpPoppy >= 1000, "H", ifelse(tmpPoppy > 0, "L", "N"))) %>%
  left_join(agrPixels, 
            by = c("distid" = "DISTID"))

covariates$poppyCat <- factor(covariates$poppyCat, levels = c("N", "L", "H"))

sigarControl <- read.csv(SIGAR_CSV) %>%
  mutate(talibanConInf = ifelse(Oct.2017.Assessment %in% c("INS Control", "INS In!uence"), 1, 0),
         notGovt = ifelse(Oct.2017.Assessment %in% c("INS Control", "INS In!uence", "Contested"), 1, 0))

covariates <- covariates %>%
  left_join(sigarControl %>%
              select(distid, notGovt, talibanConInf))
saveRDS(covariates, file = COVARIATES_RDS)



