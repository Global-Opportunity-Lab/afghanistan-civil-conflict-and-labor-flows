####################### randomization inference #######################
rm(list=ls()); gc()

# run randomizationInference.R for 0 to 249

############ fig 
rm(list = ls()); gc()
source("config.R")
fileList <- list.files(RANDOM_DIR, full.names = TRUE)

collectCoefs <- rep(NA, length(fileList))
for (i in 1:length(collectCoefs)) {
  if (i %% 5 == 0) cat(i, ", ")
  outcome1 <- readRDS(fileList[i])
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
  
  collectCoefs[i] <- fit1$coefficients[["poppyCatH"]]
}

# original:
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

originalCoef <- fit1$coefficients[["poppyCatH"]]

plot1 <- data.frame(randomCoefs = collectCoefs) %>%
  ggplot(aes(x = randomCoefs)) +
  geom_histogram() +
  geom_vline(xintercept = originalCoef) +
  labs(x = "Estimated coefficient for high-cultivation districts",
       y = "Count") +
  scale_x_continuous(#labels = ,
    breaks = seq(from = -.01, to = .03, by = .005)) +
  annotate("text", x = .0248, y = 15.3, label = "Observed",
           size = 3) 

pdf(file.path(OUT_REVIEW1, "randomNDVI.pdf"), width = 5.5, height = 4)
gridExtra::grid.arrange(plot1, nrow = 1)
dev.off()





