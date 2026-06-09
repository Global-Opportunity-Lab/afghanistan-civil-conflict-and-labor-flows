source("config.R")
library(dplyr); library(ggplot2)

### Figure 2A: daily in-migration event study
rm(list = setdiff(ls(), c("OUT_DIR", "RAW_DATA_DIR", "SAT_ROOT", "CDR_ROOT",
                           "DIST_YEARS_RDS", "COVARIATES_RDS", "RESULTS_INMIG_RDS",
                           "RESULTS_OUTMIG_RDS", "INMIG_OUTCOME_RDS", "DD_OUTCOMES_RDS",
                           "BEST_DATES_SAT"))); gc()

distYears  <- readRDS(DIST_YEARS_RDS)
covariates <- readRDS(COVARIATES_RDS) %>% select(-geometry)
outDTF     <- readRDS(RESULTS_INMIG_RDS)

outDTF <- outDTF %>%
  left_join(covariates %>% select(distid, year, poppy, poppyCat),
            by = c("distid", "year"))

forPlot <- outDTF %>%
  mutate(distidYear = paste0(distid, "_", year)) %>%
  filter(distidYear %in% distYears) %>%
  group_by(poppyCat, daysFromPeak) %>%
  summarize(meanEffect = mean(estimate),
            var = sum(se^2, na.rm = TRUE)/(n()^2)) %>%
  mutate(conf.low  = meanEffect - qnorm(.975)*sqrt(var),
         conf.high = meanEffect + qnorm(.975)*sqrt(var))

forPlot2a <- forPlot %>% select(-var)

### Figure 2B: daily out-migration event study
distYears  <- readRDS(DIST_YEARS_RDS)
covariates <- readRDS(COVARIATES_RDS) %>% select(-geometry)
outDTF     <- readRDS(RESULTS_OUTMIG_RDS)

outDTF <- outDTF %>%
  left_join(covariates %>% select(distid, year, poppy, poppyCat),
            by = c("distid", "year"))

forPlot <- outDTF %>%
  mutate(distidYear = paste0(distid, "_", year)) %>%
  filter(distidYear %in% distYears) %>%
  group_by(poppyCat, daysFromPeak) %>%
  summarize(meanEffect = mean(estimate),
            var = sum(se^2, na.rm = TRUE)/(n()^2)) %>%
  mutate(conf.low  = meanEffect - qnorm(.975)*sqrt(var),
         conf.high = meanEffect + qnorm(.975)*sqrt(var))

forPlot2b <- forPlot %>% select(-var)

### Figure 2C: baseline vs harvest in-migration rate distributions
outcome1   <- readRDS(INMIG_OUTCOME_RDS)
covariates <- readRDS(COVARIATES_RDS) %>% dplyr::select(-geometry)

outDTFM4 <- covariates %>%
  left_join(outcome1, by = c("distid", "year")) %>%
  mutate(prov = floor(distid/100)) %>%
  filter(!is.na(maxIn))

ddOutcomes <- readRDS(DD_OUTCOMES_RDS)

bestDatesLongTmp <- readRDS(BEST_DATES_SAT) %>%
  rename("distID" = "distIDs") %>%
  dplyr::select(distID, year, maxDate) %>%
  mutate(currentMonth = lubridate::floor_date(as.Date(maxDate), "month"),
         maxDate = as.Date(maxDate))

baseline <- ddOutcomes %>%
  mutate(year  = lubridate::year(date),
         month = lubridate::month(date)) %>%
  mutate(year = ifelse(month >= 9, year + 1, year)) %>%
  left_join(bestDatesLongTmp %>%
              dplyr::select(distID, year, maxDate) %>%
              filter(year != 2017),
            by = c("district_id" = "distID", "year")) %>%
  mutate(daysFromPeak = as.numeric(date - maxDate)) %>%
  dplyr::select(district_id, year, percentage_in, daysFromPeak) %>%
  filter(daysFromPeak %in% -120:-31) %>%
  filter(!is.na(percentage_in) & percentage_in != 0 & percentage_in != 1) %>%
  group_by(district_id, year) %>%
  summarize(numObs = n(), baseline = mean(percentage_in))

outDTFM4 <- outDTFM4 %>%
  left_join(baseline, by = c("distid" = "district_id", "year")) %>%
  mutate(harvest = maxIn + baseline) %>%
  select(baseline, poppyCat, harvest)

forPlot2c <- outDTFM4

### Figure 2D: district-year regression point estimates
outcome1   <- readRDS(INMIG_OUTCOME_RDS)
covariates <- readRDS(COVARIATES_RDS) %>% dplyr::select(-geometry)

outDTFM4 <- covariates %>%
  left_join(outcome1, by = c("distid", "year")) %>%
  mutate(prov = floor(distid/100)) %>%
  filter(!is.na(maxIn))

fit1 <- lm(maxIn ~ poppyCat + log(areakm2) +
             log(nonPoppy2) + TOTAL + as.factor(year) + as.factor(prov) +
             provincialCapital + cultivatedFrac + roadDensity + builtUpFracPop +
             trackPathFrac + healthPer100000 + diversity + as.factor(majority) +
             barrenAreaFrac,
           data = outDTFM4 %>% filter(!is.na(maxIn)))

tmpDistID <- outDTFM4$distid[!is.na(outDTFM4$maxIn) & !is.na(outDTFM4$diversity) &
                               !is.na(outDTFM4$trackPathFrac)]
fit1coefs <- lmtest::coeftest(fit1,
                              vcov. = sandwich::vcovCL(fit1, cluster = as.factor(tmpDistID),
                                                       type = "HC1"))

tmp     <- fit1coefs[c("poppyCatL", "poppyCatH"), c("Estimate", "Std. Error")]
plotDTF <- data.frame(model    = "Overall",
                      label    = c("Low-cultivation", "High-cultivation"),
                      estimate = tmp[, "Estimate"],
                      CIlow    = tmp[, "Estimate"] - 1.96*tmp[, "Std. Error"],
                      CIhigh   = tmp[, "Estimate"] + 1.96*tmp[, "Std. Error"])

save(forPlot2a, forPlot2b, forPlot2c, plotDTF, file = "./paper_figures_tables/data/fig2.Rdata")
