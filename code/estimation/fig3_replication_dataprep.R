source("config.R")
library(dplyr); library(ggplot2)

outcome1    <- readRDS(INMIG_OUTCOME_RDS)
covariates  <- readRDS(COVARIATES_RDS) %>% dplyr::select(-geometry)
newViolence <- readRDS(VIOLENCE_DEST_RDS)

# Full panel used for both figures
outDTFM4_full <- covariates %>%
  left_join(outcome1, by = c("distid", "year")) %>%
  mutate(prov = floor(distid/100)) %>%
  left_join(newViolence %>%
              mutate(violence_monthBefore = ifelse(numEvents_monthBeforePeak > 0, 1, 0)),
            by = c("distid", "year")) %>%
  filter(!is.na(maxIn))

### Figure 3A: in-migration density by violence x Taliban category (high-poppy only)
# Saved as outDTFM4 for compatibility with demo_v1/fig3.R
outDTFM4 <- outDTFM4_full %>%
  filter(poppyCat == "H") %>%
  mutate(cat = case_when(
    notGovt == 1 & violence_monthBefore == 1 ~ "Taliban = Yes, Violence = Yes",
    notGovt == 1 & violence_monthBefore == 0 ~ "Taliban = Yes, Violence = No",
    notGovt == 0 & violence_monthBefore == 1 ~ "Taliban = No, Violence = Yes",
    notGovt == 0 & violence_monthBefore == 0 ~ "Taliban = No, Violence = No"
  )) %>%
  select(maxIn, cat)

### Figure 3B: violence x Taliban interaction regression (uses full panel)
new3 <- lm(maxIn ~ poppyCat*violence*taliban + log(areakm2) + log(nonPoppy2) +
             TOTAL + as.factor(year) + as.factor(prov) +
             provincialCapital + cultivatedFrac + roadDensity + builtUpFracPop +
             trackPathFrac + healthPer100000 + diversity + as.factor(majority) +
             barrenAreaFrac,
           data = outDTFM4_full %>%
             filter(!is.na(maxIn)) %>%
             rename(violence = violence_monthBefore) %>%
             mutate(taliban = ifelse(notGovt, 1, 0)))

tmpDistID <- outDTFM4_full$distid[!is.na(outDTFM4_full$maxIn) &
                                    !is.na(outDTFM4_full$diversity) &
                                    !is.na(outDTFM4_full$trackPathFrac)]
fit2coefs <- lmtest::coeftest(new3,
                              vcov. = sandwich::vcovCL(new3, cluster = as.factor(tmpDistID),
                                                       type = "HC1"))

keepNames     <- c("poppyCatH", "violence", "poppyCatH:violence", "taliban",
                   "poppyCatH:taliban", "violence:taliban", "poppyCatH:violence:taliban")
estimates     <- fit2coefs[keepNames, "Estimate"]
clusteredVcov <- sandwich::vcovCL(new3, cluster = as.factor(tmpDistID), type = "HC1")
clusteredVcov <- clusteredVcov[keepNames, keepNames]

getCI <- function(myVec, estimates, vCov) {
  estimate <- myVec %*% estimates
  variance <- myVec %*% vCov %*% myVec
  list(estimate = estimate, variance = variance,
       ciLow  = estimate - qnorm(.975)*sqrt(variance),
       ciHigh = estimate + qnorm(.975)*sqrt(variance))
}

outDTF <- data.frame(model    = rep("High-growing", 4),
                     label    = c("Violence N, Taliban N", "Violence Y, Taliban N",
                                  "Violence N, Taliban Y", "Violence Y, Taliban Y"),
                     estimate = NA, CIlow = NA, CIhigh = NA)

vecs <- list(c(1,0,0,0,0,0,0), c(1,1,1,0,0,0,0), c(1,0,0,1,1,0,0), c(1,1,1,1,1,1,1))
for (i in 1:4) {
  tmp <- getCI(vecs[[i]], estimates, clusteredVcov)
  outDTF[i, "estimate"] <- tmp$estimate
  outDTF[i, "CIlow"]    <- tmp$ciLow
  outDTF[i, "CIhigh"]   <- tmp$ciHigh
  outDTF[i, "variance"] <- tmp$variance
}
outDTF$p <- 2*pnorm(abs(outDTF$estimate)/sqrt(outDTF$variance), lower.tail = FALSE)

save(outDTFM4, outDTF, file = "./paper_figures_tables/data/fig3.Rdata")
