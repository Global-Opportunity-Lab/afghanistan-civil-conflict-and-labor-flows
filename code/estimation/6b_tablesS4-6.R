
##### reviewer request: descriptive statistics 
rm(list = ls()); gc()
source("config.R")
outcome1 <- readRDS(INMIG_OUTCOME_RDS)
covariates <- readRDS(COVARIATES_RDS) %>%
  dplyr::select(-geometry) # this version should have poppyCat, talibanCurrent and inaccessibleCurrent

outDTFM4 <- covariates %>%
  left_join(outcome1, by = c("distid", "year")) %>%
  mutate(prov = floor(distid/100)) %>%
  filter(!is.na(maxIn)) 

tmp <- outDTFM4 %>%
  filter(!is.na(maxIn)) %>%
  select(poppyCat, areakm2, 
         nonPoppy2, TOTAL,# year, prov,
         provincialCapital, cultivatedFrac, roadDensity, builtUpFracPop,
         trackPathFrac, healthPer100000, diversity, majority,
         barrenAreaFrac
  )

stargazer::stargazer(tmp, 
                     title = "Descriptive statistics for covariates",
                     digits = 2,
                     covariate.labels = c(#"Increase in in-migration",
                       "Area (squared km)",
                       "Non-poppy cultivation (ha)",
                       "Population",
                       "Provincial capital",
                       "Fraction living in cultivated areas",
                       "Road density",
                       "Fraction living in built-up areas",
                       "Fraction of roads that are tracks and paths",
                       "Health facilities per 100,000",
                       "Ethnic diversity",
                       "Proportion of barren land")
)

#### for outcomes and variables of interest 

rm(list = ls()); gc()
outcome1 <- readRDS(INMIG_OUTCOME_RDS)
covariates <- readRDS(COVARIATES_RDS) %>%
  dplyr::select(-geometry) # this version should have poppyCat, talibanCurrent and inaccessibleCurrent

newViolence <- readRDS(VIOLENCE_DEST_RDS)

outDTFM4 <- covariates %>%
  left_join(outcome1, by = c("distid", "year")) %>%
  mutate(prov = floor(distid/100)) %>%
  left_join(newViolence %>%
              mutate(violence_monthBefore = ifelse(numEvents_monthBeforePeak > 0, 1, 0)) #%>% # ORIGINAL
            ,
            by = c("distid", "year")) %>%
  filter(!is.na(maxIn)) %>%
  rename(violence = violence_monthBefore) %>%
  # mutate(taliban = ifelse(scale4 == TRUE | scale5 == TRUE, 1, 0)))
  mutate(taliban = ifelse(notGovt, 1, 0))

outDTFM4 <- outDTFM4 %>%
  select(distid, year, tmpPoppy, poppyCat, maxIn, violence, taliban) %>%
  mutate(poppyH = ifelse(poppyCat == "H", 1, 0),
         poppyL = ifelse(poppyCat == "L", 1, 0))

suffix <- "_rA"#  ""  # "_rB"#  
outcome1 <- readRDS(paste0(SUBGROUP_H_CHECK_BASE, suffix, "_2020_check.rds")) %>%
  rename(outcomeHigh = maxIn)
outcome2 <- readRDS(paste0(SUBGROUP_L_CHECK_BASE, suffix, "_2020_check.rds")) %>%
  rename(outcomeLow = maxIn)

outcome3 <- readRDS(paste0(SUBGROUP_HVT_BASE, suffix, "_2020.rds")) %>%
  rename(outcomeHVT = maxIn)
outcome4 <- readRDS(paste0(SUBGROUP_HVNONT_BASE, suffix, "_2020.rds")) %>%
  rename(outcomeHVnonT = maxIn)
outcome5 <- readRDS(paste0(SUBGROUP_HNONVT_BASE, suffix, "_2020.rds")) %>%
  rename(outcomeHnonVT = maxIn)
outcome6 <- readRDS(paste0(SUBGROUP_HNONVNONT_BASE, suffix, "_2020.rds")) %>%
  rename(outcomeHnonVnonT = maxIn)


outDTFM4 <- outDTFM4 %>%
  left_join(outcome1, by = c("distid", "year")) %>%
  left_join(outcome2, by = c("distid", "year")) %>%
  left_join(outcome3, by = c("distid", "year")) %>%
  left_join(outcome4, by = c("distid", "year")) %>%
  left_join(outcome5, by = c("distid", "year")) %>%
  left_join(outcome6, by = c("distid", "year")) 

tmp <- outDTFM4 %>%
  select(tmpPoppy,
         poppyH, poppyL,# year, prov,
         violence, taliban,
         maxIn, starts_with("outcome")
  )

stargazer::stargazer(tmp, 
                     title = "Descriptive statistics for variables of interest",
                     digits = 2,
                     covariate.labels = c(
                       "Poppy cultivation (ha)",
                       "High poppy cultivation",
                       "Low poppy cultivation",
                       "Violence",
                       "Taliban presence",
                       "Increase in in-migration",
                       "Increase in proportion from high cultivation districts",
                       "Increase in proportion from low cultivation districts",
                       "Increase in proportion from high, violent, Taliban districts",
                       "Increase in proportion from high, violent, non-Taliban districts",
                       "Increase in proportion from high, non-violent, Taliban districts",
                       "Increase in proportion from high, non-violent, non-Taliban districts"
                     )
)


################################# fig 2c (reg results) #################################
rm(list = ls()); gc()
outcome1 <- readRDS(INMIG_OUTCOME_RDS)
covariates <- readRDS(COVARIATES_RDS) %>%
  dplyr::select(-geometry) # this version should have poppyCat, talibanCurrent and inaccessibleCurrent

outDTFM4 <- covariates %>%
  left_join(outcome1, by = c("distid", "year")) %>%
  mutate(prov = floor(distid/100)) %>%
  filter(!is.na(maxIn)) 

# categorical version
fit1 <- lm(maxIn ~ poppyCat + log(areakm2) + 
             log(nonPoppy2) + TOTAL + as.factor(year) + as.factor(prov) +
             provincialCapital + cultivatedFrac + roadDensity + builtUpFracPop +
             trackPathFrac + healthPer100000 + diversity + as.factor(majority)+
             barrenAreaFrac, 
           data = outDTFM4 %>%
             filter(!is.na(maxIn)) )

fit1$tmpDistID <- outDTFM4$distid[!is.na(outDTFM4$maxIn) & !is.na(outDTFM4$diversity) & !is.na(outDTFM4$trackPathFrac)]



################ fig 3b
outcome1 <- readRDS(INMIG_OUTCOME_RDS)
covariates <- readRDS(COVARIATES_RDS) %>%
  dplyr::select(-geometry) # this version should have poppyCat, talibanCurrent and inaccessibleCurrent

newViolence <- readRDS(VIOLENCE_DEST_RDS)

outDTFM4 <- covariates %>%
  left_join(outcome1, by = c("distid", "year")) %>%
  mutate(prov = floor(distid/100)) %>%
  left_join(newViolence %>%
              mutate(violence_monthBefore = ifelse(numEvents_monthBeforePeak > 0, 1, 0)) 
            ,
            by = c("distid", "year")) %>%
  filter(!is.na(maxIn)) # %>%

new3 <- lm(maxIn ~ poppyCat*violence*taliban + log(areakm2) + log(nonPoppy2) + TOTAL + as.factor(year) + as.factor(prov) +
             provincialCapital + cultivatedFrac + roadDensity + builtUpFracPop +
             trackPathFrac + healthPer100000 + diversity + as.factor(majority)+
             barrenAreaFrac
           , 
           data = outDTFM4 %>%
             filter(!is.na(maxIn) 
             )%>%
             rename(violence = violence_monthBefore) %>%
             mutate(taliban = ifelse(notGovt, 1, 0)))

new3$tmpDistID <- outDTFM4$distid[!is.na(outDTFM4$maxIn) & !is.na(outDTFM4$diversity) & !is.na(outDTFM4$trackPathFrac)]

##### HIGH/LOW results
# rm(list = ls()); gc()
suffix <- "_rA"#  ""  # "_rB"#  
outcome1 <- readRDS(paste0(SUBGROUP_H_CHECK_BASE, suffix, "_2020_check.rds"))
outcome2 <- readRDS(paste0(SUBGROUP_L_CHECK_BASE, suffix, "_2020_check.rds"))

covariates <- readRDS(COVARIATES_RDS) %>%
  select(-geometry)# this version should have poppyCat, talibanCurrent and inaccessibleCurrent

outDTFM4 <- covariates %>%
  left_join(outcome1, by = c("distid", "year")) %>%
  mutate(prov = floor(distid/100)) 

# categorical version
fit3 <- lm(maxIn ~ poppyCat + log(areakm2) + 
             log(nonPoppy2) + TOTAL + as.factor(year) + as.factor(prov) +
             provincialCapital + cultivatedFrac + roadDensity + builtUpFracPop +
             trackPathFrac + healthPer100000 + diversity + as.factor(majority)+
             barrenAreaFrac, 
           data = outDTFM4 %>%
             filter(!is.na(maxIn) 
                    # & year < 2017
                    # & year > 2017
                    # & tmpPoppy < 5000
             ) )

fit3$tmpDistID <- outDTFM4$distid[!is.na(outDTFM4$maxIn) & !is.na(outDTFM4$diversity) & !is.na(outDTFM4$trackPathFrac)]

###
outDTFM4 <- covariates %>%
  left_join(outcome2, by = c("distid", "year")) %>%
  mutate(prov = floor(distid/100)) 

# categorical version
fit4 <- lm(maxIn ~ poppyCat + log(areakm2) + 
             log(nonPoppy2) + TOTAL + as.factor(year) + as.factor(prov) +
             provincialCapital + cultivatedFrac + roadDensity + builtUpFracPop +
             trackPathFrac + healthPer100000 + diversity + as.factor(majority)+
             barrenAreaFrac, 
           data = outDTFM4 %>%
             filter(!is.na(maxIn)
             ))

fit4$tmpDistID <- outDTFM4$distid[!is.na(outDTFM4$maxIn) & !is.na(outDTFM4$diversity) & !is.na(outDTFM4$trackPathFrac)]

###### source results 
suffix <- "_rA"#  ""  # "_rB"#  
outcome1 <- readRDS(paste0(SUBGROUP_HVT_BASE, suffix, "_2020.rds"))
outcome2 <- readRDS(paste0(SUBGROUP_HVNONT_BASE, suffix, "_2020.rds"))
outcome3 <- readRDS(paste0(SUBGROUP_HNONVT_BASE, suffix, "_2020.rds"))
outcome4 <- readRDS(paste0(SUBGROUP_HNONVNONT_BASE, suffix, "_2020.rds"))

covariates <- readRDS(COVARIATES_RDS) %>%
  select(-geometry)# this version should have poppyCat, talibanCurrent and inaccessibleCurrent

outDTFM4 <- covariates %>%
  left_join(outcome1, by = c("distid", "year")) %>%
  mutate(prov = floor(distid/100)) 

# categorical version
fit5 <- lm(maxIn ~ poppyCat + log(areakm2) + 
             log(nonPoppy2) + TOTAL + as.factor(year) + as.factor(prov) +
             provincialCapital + cultivatedFrac + roadDensity + builtUpFracPop +
             trackPathFrac + healthPer100000 + diversity + as.factor(majority)+
             barrenAreaFrac, 
           data = outDTFM4 %>%
             filter(!is.na(maxIn) 
             ) )

fit5$tmpDistID <- outDTFM4$distid[!is.na(outDTFM4$maxIn) & !is.na(outDTFM4$diversity) & !is.na(outDTFM4$trackPathFrac)]

outDTFM4 <- covariates %>%
  left_join(outcome2, by = c("distid", "year")) %>%
  mutate(prov = floor(distid/100)) 

# categorical version
fit6 <- lm(maxIn ~ poppyCat + log(areakm2) + 
             log(nonPoppy2) + TOTAL + as.factor(year) + as.factor(prov) +
             provincialCapital + cultivatedFrac + roadDensity + builtUpFracPop +
             trackPathFrac + healthPer100000 + diversity + as.factor(majority)+
             barrenAreaFrac, 
           data = outDTFM4 %>%
             filter(!is.na(maxIn)
             ))

fit6$tmpDistID <- outDTFM4$distid[!is.na(outDTFM4$maxIn) & !is.na(outDTFM4$diversity) & !is.na(outDTFM4$trackPathFrac)]

outDTFM4 <- covariates %>%
  left_join(outcome3, by = c("distid", "year")) %>%
  mutate(prov = floor(distid/100)) 

# categorical version
fit7 <- lm(maxIn ~ poppyCat + log(areakm2) + 
             log(nonPoppy2) + TOTAL + as.factor(year) + as.factor(prov) +
             provincialCapital + cultivatedFrac + roadDensity + builtUpFracPop +
             trackPathFrac + healthPer100000 + diversity + as.factor(majority)+
             barrenAreaFrac, 
           data = outDTFM4 %>%
             filter(!is.na(maxIn)
                    # & year != 2016
                    # & year > 2014
                    # & tmpPoppy < 5000
             ))

fit7$tmpDistID <- outDTFM4$distid[!is.na(outDTFM4$maxIn) & !is.na(outDTFM4$diversity) & !is.na(outDTFM4$trackPathFrac)]

outDTFM4 <- covariates %>%
  left_join(outcome4, by = c("distid", "year")) %>%
  mutate(prov = floor(distid/100)) 

# categorical version
fit8 <- lm(maxIn ~ poppyCat + log(areakm2) + 
             log(nonPoppy2) + TOTAL + as.factor(year) + as.factor(prov) +
             provincialCapital + cultivatedFrac + roadDensity + builtUpFracPop +
             trackPathFrac + healthPer100000 + diversity + as.factor(majority)+
             barrenAreaFrac, 
           data = outDTFM4 %>%
             filter(!is.na(maxIn)
             ))

fit8$tmpDistID <- outDTFM4$distid[!is.na(outDTFM4$maxIn) & !is.na(outDTFM4$diversity) & !is.na(outDTFM4$trackPathFrac)]

## eradication 

outcome1 <- readRDS(INMIG_OUTCOME_RDS)

covariates <- readRDS(COVARIATES_RDS) %>%
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
  dplyr::select(distid, year, provincialCapital, region, tmpPoppy, poppyCat, eradication) %>%
  mutate(eradicationYN = ifelse(eradication > 0, 1, 0))

checkEradication <- checkEradication %>%
  mutate(totalPoppy = tmpPoppy + eradication,
         eradPercent = eradication/totalPoppy) %>%
  mutate(eradPercent = ifelse(is.na(eradPercent), 0, eradPercent))

outDTFM4 <- covariates %>%
  left_join(outcome1, by = c("distid", "year")) %>%
  mutate(prov = floor(distid/100)) %>%
  filter(!is.na(maxIn)) %>%
  left_join(checkEradication %>%
              dplyr::select(distid, year, eradication, eradicationYN, eradPercent),
            by = c("distid", "year")) 

outDTFM4 <- outDTFM4 %>%
  filter(year %in% 2014:2016)

eradication1 <- lm(maxIn ~ poppyCat*eradPercent + log(areakm2) + log(nonPoppy2) + TOTAL + as.factor(year) + as.factor(prov) +
                     provincialCapital + cultivatedFrac + roadDensity + builtUpFracPop +
                     trackPathFrac + healthPer100000 + diversity + as.factor(majority)+
                     barrenAreaFrac
                   , 
                   data = outDTFM4 %>%
                     filter(!is.na(maxIn) 
                            # & tmpPoppy < 12000
                     ))

eradication1$tmpDistID <- outDTFM4$distid[!is.na(outDTFM4$maxIn) & !is.na(outDTFM4$diversity) & !is.na(outDTFM4$trackPathFrac)]





mdls <- list(fit1, new3, fit3, fit4, fit5, fit7, fit6, fit8, eradication1) # switch 6 and 7
# Calculate robust confidence intervals
se_robust <- function(x) {
  lmtest::coeftest(x, vcov. = sandwich::vcovCL(x, cluster = as.factor(x$tmpDistID), type = "HC1"))[, "Std. Error"]
}
stargazer::stargazer(fit1, new3, fit3, fit4, fit5, fit7, fit6, fit8, eradication1,
                     se = lapply(mdls, se_robust),
                     omit.stat=c("ser","f"), 
                     digits = 4, 
                     font.size = "scriptsize",
                     keep = c("poppyCatH", "poppyCatL", "*tmpPoppy", "*areakm2", "*nonPoppy2", "TOTAL", "provincialCapital", "cultivatedFrac", "roadDensity", "builtUpFracPop", "trackPathFrac", "healthPer100000", "diversity", "barrenAreaFrac", "*poppy", "*violence", "*taliban", "erad*"), 
                     column.sep.width = "0pt",
                     no.space = TRUE,
                     covariate.labels = c("Poppy Low (1-999)",
                                          "Poppy High ($>$1000ha)",
                                          "Violent events",
                                          "Taliban presence",
                                          "eradPercent",
                                          "Land area (km$^2$, log)",
                                          "Other cultivation (ha, log)",
                                          "Population",
                                          "Provincial Capital",
                                          "Fraction of population\\\\ in cultivated areas",
                                          "Road density",
                                          "Fraction of population\\\\ in built-up areas",
                                          "Fraction of roads that\\\\ are tracks and paths",
                                          "Health facilities\\\\ per 100,000",
                                          "Ethnic diversity",
                                          "Fraction of barren land area",
                                          "Poppy Low:Violence",
                                          "Poppy High:Violence",
                                          "Poppy Low:Taliban",
                                          "Poppy High:Taliban",
                                          "Violence:Taliban",
                                          "Low:Violence:Taliban",
                                          "High:Violence:Taliban",
                                          "poppyCatL:eradPercent",
                                          "poppyCatH:eradPercent"

                     ),
                     # dep.var.labels = "",
                     # column.labels = c(
                     #   # "Violence",
                     #   # "Intense violence",
                     #   # "Taliban",
                     #   "Violence*Taliban",
                     #   # "Intense violence*Taliban",
                     #   "Removing outliers" # "(4) removing outliers"
                     # ),
                     # dep.var.caption = "Dependent variable: excess in-migration during harvest",
                     omit = "as.factor")

