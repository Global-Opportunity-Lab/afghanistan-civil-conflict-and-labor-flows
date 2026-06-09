source("config.R")
library(ggplot2); library(dplyr)
# first check if eradication happens in districts with Taliban control or not

newViolence <- readRDS(VIOLENCE_DEST_RDS)
outcome1    <- readRDS(INMIG_OUTCOME_RDS)
covariates  <- readRDS(COVARIATES_RDS) %>%
  select(-geometry, -talibanCurrent, -inaccessibleCurrent, -insecurity, -scale3, -scale4, -scale5, -talibanConInf)# this version should have poppyCat, talibanCurrent and inaccessibleCurrent

eradicationData <- read.csv(ERADICATION_CSV)
eradicationLong <- eradicationData %>%
  tidyr::pivot_longer(cols = starts_with("X"), 
                      names_to = "year", 
                      names_pattern = "X(.*)_eradication",
                      names_transform = list(year = as.numeric),
                      values_to = "eradication") 

checkEradication <- covariates %>%
  left_join(eradicationLong, 
            by = c("distid", "year")) %>%
  mutate(eradication = ifelse(!is.na(eradication), eradication, 0)) %>%
  filter(year %in% 2014:2016) %>%
  # mutate(taliban = ifelse(scale4 == TRUE | scale5 == TRUE, 1, 0)) %>%
  mutate(taliban = notGovt) %>%
  dplyr::select(distid, year, provincialCapital, region, tmpPoppy, poppyCat, taliban, notGovt, eradication) %>%
  mutate(eradicationYN = ifelse(eradication > 0, 1, 0))

checkEradication <- checkEradication %>%
  mutate(totalPoppy = tmpPoppy + eradication,
         eradPercent = eradication/totalPoppy) %>%
  mutate(eradPercent = ifelse(is.na(eradPercent), 0, eradPercent))

outDTFM4 <- covariates %>%
  left_join(outcome1, by = c("distid", "year")) %>%
  mutate(prov = floor(distid/100)) %>%
  left_join(newViolence %>%
              mutate(violence_monthBefore = ifelse(numEvents_monthBeforePeak > 0, 1, 0)) #%>%
            # select(-starts_with("numEvents"))
            ,
            by = c("distid", "year")) 

outDTFM4 <- outDTFM4 %>%
  filter(!is.na(maxIn)) %>%
  left_join(checkEradication %>%
              dplyr::select(distid, year, eradication, eradicationYN, eradPercent),
            by = c("distid", "year")) 


outDTFM4 <- outDTFM4 %>%
  filter(year %in% 2014:2016)


fig5bdata <- outDTFM4 %>%
  filter(poppyCat == "H") %>%
  filter(eradicationYN == 1) %>%
  select(eradPercent, notGovt)

### fig5a data
eradication1 <- lm(maxIn ~ poppyCat*eradPercent + log(areakm2) + log(nonPoppy2) + TOTAL + as.factor(year) + as.factor(prov) +
                     provincialCapital + cultivatedFrac + roadDensity + builtUpFracPop +
                     trackPathFrac + healthPer100000 + diversity + as.factor(majority)+
                     barrenAreaFrac
                   , 
                   data = outDTFM4 %>%
                     filter(!is.na(maxIn) 
                            # & tmpPoppy < 12000
                     ))

# summary(eradication1)


# erad1coefs <- lmtest::coeftest(eradication1, vcov. = sandwich::vcovCL(eradication1, cluster = eradication1$model$prov, type = "HC1")) # takes less than a minute!
tmpDistID <- outDTFM4$distid[!is.na(outDTFM4$maxIn) & !is.na(outDTFM4$diversity) & !is.na(outDTFM4$trackPathFrac)]
erad1coefs <- lmtest::coeftest(eradication1, vcov. = sandwich::vcovCL(eradication1, cluster = as.factor(tmpDistID), type = "HC1")) # takes less than a minute!

# figure: want H, high with eradicationYN, high with highEradication 
keepNames <- c("poppyCatH", "eradPercent", "poppyCatH:eradPercent")
estimates <- erad1coefs[keepNames, "Estimate"] # keeps the order of names too 


tmpDistID <- outDTFM4$distid[!is.na(outDTFM4$maxIn) & !is.na(outDTFM4$diversity) & !is.na(outDTFM4$trackPathFrac)]
clusteredVcov <- sandwich::vcovCL(eradication1, cluster = as.factor(tmpDistID), type = "HC1")
clusteredVcov <- clusteredVcov[keepNames, keepNames]

# vecs of interest:
getCI <- function(myVec, estimates, vCov){
  # estimate is vec*estimates;  variance is vec*clusteredVcov*vec
  estimate <- myVec %*% estimates
  variance <- myVec %*% vCov %*% myVec
  ciLow <- estimate - qnorm(.975)*sqrt(variance)
  ciHigh <- estimate + qnorm(.975)*sqrt(variance)
  ret <- list(estimate = estimate, variance = variance, ciLow = ciLow, ciHigh = ciHigh)
  return(ret)
}

outDTF <- data.frame(label = c("High-cultivation",
                               "Eradication Percent",
                               "High*EradPercent"),
                     estimate = NA,
                     CIlow = NA,
                     CIhigh = NA,
                     variance = NA)

vecs <- list(c(1, 0, 0),
             c(0, 1, 0),
             c(0, 0, 1))

for (i in 1:3) {
  tmp <- getCI(myVec = vecs[[i]], estimates = estimates, vCov = clusteredVcov)
  outDTF[i, "estimate"] <- tmp$estimate
  outDTF[i, "CIlow"] <- tmp$ciLow
  outDTF[i, "CIhigh"] <- tmp$ciHigh
  outDTF[i, "variance"] <- tmp$variance
}
#                 label     estimate        CIlow        CIhigh     variance
# 1        High-growing  0.026138824  0.008524278  0.0437533702 8.076938e-05
# 2 Eradication Percent  0.005628358 -0.004576519  0.0158332345 2.710936e-05
# 3    High*EradPercent -0.063221335 -0.125813064 -0.0006296053 1.019853e-03


save(outDTF, fig5bdata, file = "./paper_figures_tables/data/fig5.Rdata")