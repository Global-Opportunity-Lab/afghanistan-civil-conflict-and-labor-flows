# 3g_figS8.R
# Figure S8: robustness check — pre/post-2017 split and additional specification
# checks for the Figure 3b conflict-migration relationship.
# Inputs:  INMIG_OUTCOME_RDS, COVARIATES_RDS, VIOLENCE_DEST_RDS
# Outputs: 1-10-24fig3b_post2017.pdf, 1-10-24fig3b_robust2.pdf (in OUT_GENERAL)
########################### 3b ###########################
rm(list = ls()); gc()
source("config.R")
outcome1 <- readRDS(INMIG_OUTCOME_RDS)
covariates <- readRDS(COVARIATES_RDS) %>%
  dplyr::select(-geometry) # this version should have poppyCat, talibanCurrent and inaccessibleCurrent

newViolence <- readRDS(VIOLENCE_DEST_RDS)

outDTFM4 <- covariates %>%
  left_join(outcome1, by = c("distid", "year")) %>%
  mutate(prov = floor(distid/100)) %>%
  left_join(newViolence %>%
              mutate(violence_monthBefore = ifelse(numEvents_monthBeforePeak > 0, 1, 0)) #%>%
            # dplyr::select(-starts_with("numEvents"))
            ,
            by = c("distid", "year")) %>%
  filter(!is.na(maxIn)) # %>%


### repeat this code twice, one for pre and one for post
new3 <- lm(maxIn ~ poppyCat*violence*taliban + log(areakm2) + log(nonPoppy2) + TOTAL + 
             as.factor(year) +
             as.factor(prov) +
             provincialCapital + cultivatedFrac + roadDensity + builtUpFracPop +
             trackPathFrac + healthPer100000 + diversity + as.factor(majority)+
             barrenAreaFrac
           , 
           data = outDTFM4 %>%
             filter(!is.na(maxIn) 
                    # & year < 2017 #### ADD THIS LINE: pre
                    & year > 2017 #### ADD THIS LINE: post
             )%>%
             rename(violence = violence_monthBefore) %>%
             # mutate(taliban = ifelse(scale4 == TRUE | scale5 == TRUE, 1, 0)))
             mutate(taliban = ifelse(notGovt, 1, 0)))
# mutate(taliban = ifelse(talibanConInf, 1, 0)))

# fit2coefs <- lmtest::coeftest(new3, vcov. = sandwich::vcovCL(new3, cluster = new3$model$prov, type = "HC1")) # takes less than a minute!
# tmpDistID <- outDTFM4$distid[!is.na(outDTFM4$maxIn) & !is.na(outDTFM4$diversity) & !is.na(outDTFM4$trackPathFrac) & outDTFM4$year < 2017] # PRE
tmpDistID <- outDTFM4$distid[!is.na(outDTFM4$maxIn) & !is.na(outDTFM4$diversity) & !is.na(outDTFM4$trackPathFrac) & outDTFM4$year > 2017] # POST
fit2coefs <- lmtest::coeftest(new3, vcov. = sandwich::vcovCL(new3, cluster = as.factor(tmpDistID), type = "HC1")) # takes less than a minute!


keepNames <- c("poppyCatH", "violence", "poppyCatH:violence", "taliban", "poppyCatH:taliban", "violence:taliban", "poppyCatH:violence:taliban")
estimates <- fit2coefs[keepNames, "Estimate"] # keeps the order of names too 
# clusteredVcov <- sandwich::vcovCL(new3, cluster = new3$model$prov, type = "HC1")
clusteredVcov <- sandwich::vcovCL(new3, cluster = as.factor(tmpDistID), type = "HC1")
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

outDTF <- data.frame(model = rep("High-growing", 4), 
                     label = c("Violence N, Taliban N",
                               "Violence Y, Taliban N",
                               "Violence N, Taliban Y",
                               "Violence Y, Taliban Y"),
                     estimate = NA,
                     CIlow = NA,
                     CIhigh = NA)

vecs <- list(c(1, 0, 0, 0, 0, 0, 0),
             c(1, 1, 1, 0, 0, 0, 0),
             c(1, 0, 0, 1, 1, 0, 0),
             c(1, 1, 1, 1, 1, 1, 1))
for (i in 1:4) {
  tmp <- getCI(myVec = vecs[[i]], estimates = estimates, vCov = clusteredVcov)
  outDTF[i, "estimate"] <- tmp$estimate
  outDTF[i, "CIlow"] <- tmp$ciLow
  outDTF[i, "CIhigh"] <- tmp$ciHigh
  outDTF[i, "variance"] <- tmp$variance
}
outDTF$p <- 2*pnorm(abs(outDTF$estimate)/sqrt(outDTF$variance), lower.tail = FALSE)
outDTF$n <- nobs(new3) # 728 for post


plot1 <- outDTF %>%
  mutate(label = paste0(4:1, label)) %>%
  ggplot(aes(label, estimate))+
  geom_pointrange(aes(ymin = CIlow, ymax = CIhigh),
                  color = c("orange", "#fde725", "#1f968b", "#55c667")
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
    # title = "Pre-2017", # pre
    title = "Post-2017", # post
    y = "Increase in in-migration from baseline during harvest",
    x = ""
  ) +
  labs(tag = "Taliban = No \n\n\n\n\n\n\n\n\n Taliban = Yes") +
  # labs(tag = "Violence = Yes \n\n\n\n\n\n\n\n\n Violence = No") +
  theme(plot.tag.position = c(-.025, .53),
        text = element_text(size = 12),
        plot.margin = theme_get()$plot.margin + unit(c(0, 0, 0, 3), "cm")
  ) +
  coord_flip(clip = "off"
             # , ylim = c(-.015, 0.06) # for pre
             , ylim = c(-.015, 0.16) # post
  ) +
  annotate(x = 2.5, xend = 2.5, 
           # y = -.05, yend = .06, # pre
           y = -.1, yend = .16, # post
           geom = "segment",
           colour = "#a8a5a5", size = 1.4, alpha = .4) +
  # geom_vline(xintercept = 2.5, colour = "grey60", linetype = 2) +
  # scale_x_discrete(labels = c("Taliban = No", "Taliban = Yes", "Taliban = No", "Taliban = Yes")) # bottom to top 
  scale_x_discrete(labels = c("Violence = Yes", "Violence = No", "Violence = Yes", "Violence = No")) # bottom to top 

# pdf(file.path(OUT_GENERAL, "1-10-24fig3b_pre2017.pdf"), width = 8, height = 5)
pdf(file.path(OUT_GENERAL, "1-10-24fig3b_post2017.pdf"), width = 8, height = 5) # post needs change to legend too
gridExtra::grid.arrange(plot1, nrow = 1)
dev.off()

#### remove individual years 

removeYearsDest <- function(tmpYear) {
  new3 <- lm(maxIn ~ poppyCat*violence*taliban + log(areakm2) + log(nonPoppy2) + TOTAL + 
               as.factor(year) +
               as.factor(prov) +
               provincialCapital + cultivatedFrac + roadDensity + builtUpFracPop +
               trackPathFrac + healthPer100000 + diversity + as.factor(majority)+
               barrenAreaFrac
             , 
             data = outDTFM4 %>%
               filter(!is.na(maxIn) 
                      & year != tmpYear 
               )%>%
               rename(violence = violence_monthBefore) %>%
               # mutate(taliban = ifelse(scale4 == TRUE | scale5 == TRUE, 1, 0)))
               mutate(taliban = ifelse(notGovt, 1, 0)))
  # mutate(taliban = ifelse(talibanConInf, 1, 0)))
  
  # fit2coefs <- lmtest::coeftest(new3, vcov. = sandwich::vcovCL(new3, cluster = new3$model$prov, type = "HC1")) # takes less than a minute!
  tmpDistID <- outDTFM4$distid[!is.na(outDTFM4$maxIn) & !is.na(outDTFM4$diversity) & !is.na(outDTFM4$trackPathFrac) & outDTFM4$year != tmpYear]
  fit2coefs <- lmtest::coeftest(new3, vcov. = sandwich::vcovCL(new3, cluster = as.factor(tmpDistID), type = "HC1")) # takes less than a minute!
  
  
  keepNames <- c("poppyCatH", "violence", "poppyCatH:violence", "taliban", "poppyCatH:taliban", "violence:taliban", "poppyCatH:violence:taliban")
  estimates <- fit2coefs[keepNames, "Estimate"] # keeps the order of names too 
  clusteredVcov <- sandwich::vcovCL(new3, cluster = as.factor(tmpDistID), type = "HC1")
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
  
  outDTF <- data.frame(model = rep("High-growing", 4), 
                       label = c("Violence N, Taliban N",
                                 "Violence Y, Taliban N",
                                 "Violence N, Taliban Y",
                                 "Violence Y, Taliban Y"),
                       estimate = NA,
                       CIlow = NA,
                       CIhigh = NA)
  
  vecs <- list(c(1, 0, 0, 0, 0, 0, 0),
               c(1, 1, 1, 0, 0, 0, 0),
               c(1, 0, 0, 1, 1, 0, 0),
               c(1, 1, 1, 1, 1, 1, 1))
  for (i in 1:4) {
    tmp <- getCI(myVec = vecs[[i]], estimates = estimates, vCov = clusteredVcov)
    outDTF[i, "estimate"] <- tmp$estimate
    outDTF[i, "CIlow"] <- tmp$ciLow
    outDTF[i, "CIhigh"] <- tmp$ciHigh
    outDTF[i, "variance"] <- tmp$variance
  }
  outDTF$p <- 2*pnorm(abs(outDTF$estimate)/sqrt(outDTF$variance), lower.tail = FALSE)
  outDTF$n <- nobs(new3)
  
  
  plot1 <- outDTF %>%
    mutate(label = paste0(4:1, label)) %>%
    ggplot(aes(label, estimate))+
    geom_pointrange(aes(ymin = CIlow, ymax = CIhigh),
                    color = c("orange", "#fde725", "#1f968b", "#55c667")
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
      y = "Increase in in-migration from baseline during harvest",
      x = ""
    ) +
    labs(tag = "Taliban = No \n\n\n\n\n\n\n\n\n Taliban = Yes") +
    # labs(tag = "Violence = Yes \n\n\n\n\n\n\n\n\n Violence = No") +
    theme(plot.tag.position = c(-.03, .53),
          text = element_text(size = 12),
          plot.margin = theme_get()$plot.margin + unit(c(0, 0, 0, 3), "cm")
    ) +
    coord_flip(clip = "off"
               , ylim = c(-.015, 0.08) ### ADJUST THIS: this for yearly
    ) +
    annotate(x = 2.5, xend = 2.5, 
             y = -.06, yend = .08, ### ADJUST THIS: this line for yearly
             geom = "segment",
             colour = "#a8a5a5", size = 1.4, alpha = .4) +
    # geom_vline(xintercept = 2.5, colour = "grey60", linetype = 2) +
    # scale_x_discrete(labels = c("Taliban = No", "Taliban = Yes", "Taliban = No", "Taliban = Yes")) # bottom to top 
    scale_x_discrete(labels = c("Violence = Yes", "Violence = No", "Violence = Yes", "Violence = No")) # bottom to top 
  
  gridExtra::grid.arrange(plot1, nrow = 1)
}

pdf(file.path(OUT_GENERAL, "1-10-24fig3b_robust2.pdf"), width = 8, height = 5)
for (i in c(2014:2016, 2018:2020)) {
  removeYearsDest(i) 
}
dev.off()

