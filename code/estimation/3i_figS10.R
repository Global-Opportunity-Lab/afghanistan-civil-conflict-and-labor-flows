########################### 4c ###########################
###### source results 
# violence H T
rm(list = ls()); gc()
source("config.R")
suffix <- "_rA"#  ""  # "_rB"#   # ***source results use _rA version***
outcome1 <- readRDS(paste0(SUBGROUP_HVT_BASE, suffix, "_2020.rds"))
outcome2 <- readRDS(paste0(SUBGROUP_HVNONT_BASE, suffix, "_2020.rds"))
outcome3 <- readRDS(paste0(SUBGROUP_HNONVT_BASE, suffix, "_2020.rds"))
outcome4 <- readRDS(paste0(SUBGROUP_HNONVNONT_BASE, suffix, "_2020.rds"))

covariates <- readRDS(COVARIATES_RDS) %>%
  select(-geometry)# this version should have poppyCat, talibanCurrent and inaccessibleCurrent

outDTFM4 <- covariates %>%
  left_join(outcome1, by = c("distid", "year")) %>%
  mutate(prov = floor(distid/100)) 

#### REMOVE ONE YEAR AT THE TIME ---start here 
removeYearCheck <- function(tmpYear) {
  
  # categorical version
  fit1 <- lm(maxIn ~ poppyCat + log(areakm2) + 
               log(nonPoppy2) + TOTAL + 
               as.factor(year) +
               as.factor(prov) +
               provincialCapital + cultivatedFrac + roadDensity + builtUpFracPop +
               trackPathFrac + healthPer100000 + diversity + as.factor(majority)+
               barrenAreaFrac, 
             data = outDTFM4 %>%
               filter(!is.na(maxIn) 
                      & year != tmpYear
               ) )
  
  # fit1coefs <- lmtest::coeftest(fit1, vcov. = sandwich::vcovCL(fit1, cluster = fit1$model$prov, type = "HC1")) # takes less than a minute!
  tmpDistID <- outDTFM4$distid[!is.na(outDTFM4$maxIn) & !is.na(outDTFM4$diversity) & !is.na(outDTFM4$trackPathFrac) & outDTFM4$year != tmpYear]
  fit1coefs <- lmtest::coeftest(fit1, vcov. = sandwich::vcovCL(fit1, cluster = as.factor(tmpDistID), type = "HC1")) # takes less than a minute!
  
  outDTFM4 <- covariates %>%
    left_join(outcome2, by = c("distid", "year")) %>%
    mutate(prov = floor(distid/100)) 
  
  # categorical version
  fit2 <- lm(maxIn ~ poppyCat + log(areakm2) + 
               log(nonPoppy2) + TOTAL + 
               as.factor(year) +
               as.factor(prov) +
               provincialCapital + cultivatedFrac + roadDensity + builtUpFracPop +
               trackPathFrac + healthPer100000 + diversity + as.factor(majority)+
               barrenAreaFrac, 
             data = outDTFM4 %>%
               filter(!is.na(maxIn)
                      & year != tmpYear
               ))
  
  # fit2coefs <- lmtest::coeftest(fit2, vcov. = sandwich::vcovCL(fit2, cluster = fit2$model$prov, type = "HC1")) # takes less than a minute!
  tmpDistID <- outDTFM4$distid[!is.na(outDTFM4$maxIn) & !is.na(outDTFM4$diversity) & !is.na(outDTFM4$trackPathFrac) & outDTFM4$year != tmpYear]
  fit2coefs <- lmtest::coeftest(fit2, vcov. = sandwich::vcovCL(fit2, cluster = as.factor(tmpDistID), type = "HC1")) # takes less than a minute!
  
  outDTFM4 <- covariates %>%
    left_join(outcome3, by = c("distid", "year")) %>%
    mutate(prov = floor(distid/100)) 
  
  # categorical version
  fit3 <- lm(maxIn ~ poppyCat + log(areakm2) + 
               log(nonPoppy2) + TOTAL + 
               as.factor(year) +
               as.factor(prov) +
               provincialCapital + cultivatedFrac + roadDensity + builtUpFracPop +
               trackPathFrac + healthPer100000 + diversity + as.factor(majority)+
               barrenAreaFrac, 
             data = outDTFM4 %>%
               filter(!is.na(maxIn)
                      & year != tmpYear
               ))
  
  # fit3coefs <- lmtest::coeftest(fit3, vcov. = sandwich::vcovCL(fit3, cluster = fit3$model$prov, type = "HC1")) # takes less than a minute!
  tmpDistID <- outDTFM4$distid[!is.na(outDTFM4$maxIn) & !is.na(outDTFM4$diversity) & !is.na(outDTFM4$trackPathFrac) & outDTFM4$year != tmpYear]
  fit3coefs <- lmtest::coeftest(fit3, vcov. = sandwich::vcovCL(fit3, cluster = as.factor(tmpDistID), type = "HC1")) # takes less than a minute!
  
  outDTFM4 <- covariates %>%
    left_join(outcome4, by = c("distid", "year")) %>%
    mutate(prov = floor(distid/100)) 
  
  # categorical version
  fit4 <- lm(maxIn ~ poppyCat + log(areakm2) + 
               log(nonPoppy2) + TOTAL + 
               as.factor(year) +
               as.factor(prov) +
               provincialCapital + cultivatedFrac + roadDensity + builtUpFracPop +
               trackPathFrac + healthPer100000 + diversity + as.factor(majority)+
               barrenAreaFrac, 
             data = outDTFM4 %>%
               filter(!is.na(maxIn)
                      & year != tmpYear
               ))
  
  # fit4coefs <- lmtest::coeftest(fit4, vcov. = sandwich::vcovCL(fit4, cluster = fit4$model$prov, type = "HC1")) # takes less than a minute!
  tmpDistID <- outDTFM4$distid[!is.na(outDTFM4$maxIn) & !is.na(outDTFM4$diversity) & !is.na(outDTFM4$trackPathFrac) & outDTFM4$year != tmpYear]
  fit4coefs <- lmtest::coeftest(fit4, vcov. = sandwich::vcovCL(fit4, cluster = as.factor(tmpDistID), type = "HC1")) # takes less than a minute!
  
  outDTF <- data.frame(model = rep("High-growing", 4), 
                       label = c("Violence Y, Taliban Y", ### NOTE CHANGED ORDER
                                 "Violence Y, Taliban N",
                                 "Violence N, Taliban Y",
                                 "Violence N, Taliban N"
                       ),
                       estimate = NA,
                       CIlow = NA,
                       CIhigh = NA)
  
  for (i in 1:4) {
    tmp <- get(paste0("fit", i, "coefs"))
    outDTF[i, "estimate"] <- tmp["poppyCatH", "Estimate"]
    outDTF[i, "CIlow"] <- tmp["poppyCatH", "Estimate"] - qnorm(.975)*tmp["poppyCatH", "Std. Error"]
    outDTF[i, "CIhigh"] <- tmp["poppyCatH", "Estimate"] + qnorm(.975)*tmp["poppyCatH", "Std. Error"]
    outDTF[i, "variance"] <- (tmp["poppyCatH", "Std. Error"])^2
    outDTF[i, "n"] <- nobs(tmp)
  }
  outDTF$p <- 2*pnorm(abs(outDTF$estimate)/sqrt(outDTF$variance), lower.tail = FALSE)
  
  plot1 <- outDTF %>%
    mutate(label = paste0(c(1, 3, 2, 4), label)) %>%
    ggplot(aes(label, estimate))+
    geom_pointrange(aes(ymin = CIlow, ymax = CIhigh), 
                    color = c("#55c667", "#fde725", "#1f968b", "orange") # 5/14/23: add this to match barchart
    ) + # fatten changes the circles only; size changes bars and legend circles
    theme_classic() + 
    geom_hline(yintercept = 0, colour = "grey60", linetype = 2) + 
    guides(color = guide_legend(override.aes = list(linetype = "blank")), 
           linetype = FALSE # suppress line for first plot; only do color
    ) +  # shape for the type of dot
    theme(plot.title = element_text(size = 15, face = "bold"),
          axis.text = element_text(size=14),
          axis.title = element_text(size=14),
    ) +
    labs(
      title = paste0("Removing year ", tmpYear),
      # title = "Post-2017",
      # title = "Pre-2017",
      # y = "Increase in-migrant proportion from source districts\nwith specified characteristics (harvest compared to baseline)",
      y = "Increase in in-migration, by type of source district",
      x = ""
    ) +
    labs(tag = "Taliban = No \n\n\n\n\n\n\n\n\n Taliban = Yes") +
    # labs(tag = "Violence = Yes \n\n\n\n\n\n\n\n\n Violence = No") +
    theme(plot.tag.position = c(-.03, .53),
          text = element_text(size = 12),
          plot.margin = theme_get()$plot.margin + unit(c(0, 0, 0, 3), "cm")
    ) +
    coord_flip(clip = "off", 
               # ylim = c(min(0, min(outDTF$CIlow)), max(outDTF$CIhigh))
               , ylim = c(-.012, 0.042)
    ) +
    annotate(x = 2.5, xend = 2.5, 
             # y = -.023, yend = .032,
             y = -.038, yend = .042,
             # y = -.023, yend = max(outDTF$CIhigh),
             geom = "segment",
             colour = "#a8a5a5", size = 1.4, alpha = .4) +
    # geom_vline(xintercept = 2.5, colour = "grey60", linetype = 2) +
    # scale_x_discrete(labels = c("Taliban = No", "Taliban = Yes", "Taliban = No", "Taliban = Yes")) # bottom to top 
    scale_x_discrete(labels = c("Violence = Yes", "Violence = No", "Violence = Yes", "Violence = No")) # bottom to top 
  
  gridExtra::grid.arrange(plot1, nrow = 1)
  
}
pdf(file.path(OUT_GENERAL, "1-10-24fig4c_robust.pdf"), width = 8, height = 5)
for (i in c(2014:2016, 2018:2020)) {
  removeYearCheck(i) 
}
dev.off()
