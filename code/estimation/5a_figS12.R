# 5a_figS12.R
# Figure S12: robustness check using an alternative violence measure based on
# road-network conflict events rather than the main ACLED-based measure.
# Inputs:  INMIG_OUTCOME_RDS, COVARIATES_RDS, VIOLENCE_DEST_RDS, VIOLENCE_ROAD_CSV
# Outputs: 10-24-23fig3b_alt.pdf (in OUT_GENERAL)

rm(list = ls()); gc()
library(dplyr); library(ggplot2)
library(tidyr)
source("config.R")

outcome1 <- readRDS(INMIG_OUTCOME_RDS)
covariates <- readRDS(COVARIATES_RDS) %>%
  dplyr::select(-geometry) # this version should have poppyCat, notGovt

newViolence <- readRDS(VIOLENCE_DEST_RDS)

outDTFM4 <- covariates %>%
  left_join(outcome1, by = c("distid", "year")) %>%
  mutate(prov = floor(distid/100)) %>%
  left_join(newViolence %>%
              mutate(violence_monthBefore = ifelse(numEvents_monthBeforePeak > 0, 1, 0)) #%>% # ORIGINAL
            # mutate(violence_monthBefore = ifelse(numEvents_monthBeforePeak > 2, 1, 0)) #%>% # more events
            # mutate(violence_monthBefore = ifelse(numCas_monthBeforePeak > 9, 1, 0)) #%>% # more cas
            # mutate(violence_monthBefore = ifelse(numEvents_monthBeforePeak > 2 & numCas_monthBeforePeak > 9, 1, 0)) #%>% # more cas
            # dplyr::select(-starts_with("numEvents"))
            ,
            by = c("distid", "year")) %>%
  filter(!is.na(maxIn)) # %>%

d1 <- read.csv(VIOLENCE_ROAD_CSV)
d1 <- rename(d1, distid = DISTID)


outDTFM4 <- outDTFM4 %>% left_join(d1, by = c('distid', 'year'))

outDTFM4 <- outDTFM4 %>%
  mutate(any_violence_road = tidyr::replace_na(any_violence_road, 0)) # 


new3a <- lm(maxIn ~ poppyCat*violence*taliban + poppyCat*any_violence_road*taliban + log(areakm2) + log(nonPoppy2) + TOTAL + as.factor(year) + as.factor(prov) +
              provincialCapital + cultivatedFrac + roadDensity + builtUpFracPop +
              trackPathFrac + healthPer100000 + diversity + as.factor(majority)+
              barrenAreaFrac
            , 
            data = outDTFM4 %>%
              filter(!is.na(maxIn) 
                     # & tmpPoppy < 12000
              )%>%
              rename(violence = violence_monthBefore) %>%
              mutate(taliban = ifelse(notGovt, 1, 0)))


tmpDistID <- outDTFM4$distid[!is.na(outDTFM4$maxIn) & !is.na(outDTFM4$diversity) & !is.na(outDTFM4$trackPathFrac)]
fit2coefs <- lmtest::coeftest(new3a, vcov. = sandwich::vcovCL(new3a, cluster = as.factor(tmpDistID), type = "HC1")) # takes less than a minute!


keepNames <- c("poppyCatH",
               "violence", 
               "poppyCatH:violence", 
               "taliban", 
               "poppyCatH:taliban", 
               "poppyCatH:violence:taliban", 
               "violence:taliban", 
               "any_violence_road", 
               "poppyCatH:any_violence_road", 
               "poppyCatH:taliban:any_violence_road", 
               "taliban:any_violence_road")
estimates <- fit2coefs[keepNames, "Estimate"] # keeps the order of names too 
clusteredVcov <- sandwich::vcovCL(new3a, cluster = as.factor(tmpDistID), type = "HC1")
clusteredVcov <- clusteredVcov[keepNames, keepNames]


getCI <- function(myVec, estimates, vCov){
  # estimate is vec*estimates;  variance is vec*clusteredVcov*vec
  estimate <- myVec %*% estimates
  variance <- myVec %*% vCov %*% myVec
  ciLow <- estimate - qnorm(.975)*sqrt(variance)
  ciHigh <- estimate + qnorm(.975)*sqrt(variance)
  ret <- list(estimate = estimate, variance = variance, ciLow = ciLow, ciHigh = ciHigh)
  return(ret)
}


outDTF_joint <- data.frame(model = rep("High-growing", 8), 
                           label = c("Local Violence N, Road Violence N, Taliban N",
                                     "Local Violence N, Road Violence Y, Taliban N",
                                     "Local Violence Y, Road Violence N, Taliban N",
                                     "Local Violence Y, Road Violence Y, Taliban N",
                                     "Local Violence N, Road Violence N, Taliban Y",
                                     "Local Violence N, Road Violence Y, Taliban Y",
                                     "Local Violence Y, Road Violence N, Taliban Y",
                                     "Local Violence Y, Road Violence Y, Taliban Y"),
                           estimate = NA,
                           CIlow = NA,
                           CIhigh = NA)
#local, road, taliban
vecs <- list(c(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0), #N, N, N
             c(1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0), #N, Y, N
             c(1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0), #Y, N, N
             c(1, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0), # Y, Y, N
             c(1, 0, 0, 1, 1 ,0, 0, 0, 0, 0, 0), #N, N, Y
             c(1, 0, 0, 1, 1, 0, 0, 1, 1, 1, 1), #N, Y, Y
             c(1, 1, 1, 1, 1, 1 ,1, 0, 0, 0, 0), # Y, N, Y
             c(1, 1, 1, 1, 1, 1 ,1, 1, 1, 1, 1)) # Y, Y, Y
for (i in 1:8) {
  tmp <- getCI(myVec = vecs[[i]], estimates = estimates, vCov = clusteredVcov)
  outDTF_joint[i, "estimate"] <- tmp$estimate
  outDTF_joint[i, "CIlow"] <- tmp$ciLow
  outDTF_joint[i, "CIhigh"] <- tmp$ciHigh
  outDTF_joint[i, "variance"] <- tmp$variance
}
outDTF_joint$p <- 2*pnorm(abs(outDTF_joint$estimate)/sqrt(outDTF_joint$variance), lower.tail = FALSE)
outDTF_joint$n <- nobs(new3a)

tmpTest <- getCI(myVec = c(0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1), estimates = estimates, vCov = clusteredVcov)
# $estimate -0.03459132
# $variance 0.0001296481
# $ciLow -0.05690808
# $ciHigh -0.01227456
# p-value: 
2*pnorm(tmpTest$estimate/sqrt(tmpTest$variance)) # 0.002381744

plot5 <- outDTF_joint %>%
  mutate(label = paste0(8:1, label)) %>%
  ggplot(aes(label, estimate))+
  geom_pointrange(aes(ymin = CIlow, ymax = CIhigh),
                  color = c("orange", "#fde725", "#1f968b", "#55c667", "orange", "#fde725", "#1f968b", "#55c667")
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
  labs(#title = paste0("Effect of violence on destination of movers: non-capitals"),
    # title = "Violence definition: any violent event", 
    y = "Increase in in-migration\nfrom baseline during harvest",
    x = ""
  ) +
  labs(tag = "Taliban = No \n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n Taliban = Yes") +
  # labs(tag = "Violence = Yes \n\n\n\n\n Violence = No") +
  theme(plot.tag.position = c(-.07, .57),
        text = element_text(size = 12),
        plot.margin = theme_get()$plot.margin + unit(c(0, 0, 0, 3), "cm")
  ) +
  coord_flip(clip = "off"
             , ylim = c(-.05, 0.1)
             # , ylim = c(-.03, 0.09) # for low-growing
  ) +
  annotate(x = 4.5, xend = 4.5, y = -.063, yend = .1,
           geom = "segment",
           colour = "#a8a5a5", size = 1.4, alpha = .4) +
  # geom_vline(xintercept = 2.5, colour = "grey60", linetype = 2) +
  scale_x_discrete(labels = c("V = Yes, RV = Yes", "V = Yes, RV = No","V = No, RV = Yes", "V = No, RV = No",
                              "V = Yes, RV = Yes", "V = Yes, RV = No","V = No, RV = Yes", "V = No, RV = No")) # bottom to top 
pdf(file.path(OUT_GENERAL, "10-24-23fig3b_alt.pdf"), width = 8, height = 8)
gridExtra::grid.arrange(plot5, nrow = 1)
dev.off()

plot5