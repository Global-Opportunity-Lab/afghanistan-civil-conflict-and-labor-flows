# eradication

rm(list = ls()); gc()
library(ggplot2); library(dplyr)
source("config.R")
# first check if eradication happens in districts with Taliban control or not 

newViolence <- readRDS(VIOLENCE_DEST_OLD_RDS)
outcome1 <- readRDS(INMIG_OUTCOME_RDS)

covariates <- readRDS(COVARIATES_RDS) %>%
  select(-geometry)# this version should have poppyCat, talibanCurrent and inaccessibleCurrent

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

## numbers reported in text for districts with eradication
sum(checkEradication$eradicationYN[checkEradication$tmpPoppy > 0 | checkEradication$eradicationYN == 1] == 1) # second condition: some districts after eradication had no remaining cultivation reported
# [1] 94
sum(checkEradication$tmpPoppy > 0 | checkEradication$eradicationYN == 1)
# [1] 435
94/435
# [1] 0.216092

tmp <- checkEradication %>% 
  filter(poppyCat == "H")
sum(tmp$eradicationYN[tmp$tmpPoppy > 0 | tmp$eradicationYN == 1] == 1) / sum(tmp$tmpPoppy > 0 | tmp$eradicationYN == 1) # 32.5%

tmp <- checkEradication %>% 
  filter(poppyCat == "H" & notGovt == 1) # high-growing, Taliban
sum(tmp$eradicationYN[tmp$tmpPoppy > 0 | tmp$eradicationYN == 1] == 1) / sum(tmp$tmpPoppy > 0 | tmp$eradicationYN == 1) # 27.4%

tmp <- checkEradication %>% 
  filter(poppyCat == "H" & notGovt == 0) # high-growing, Taliban
sum(tmp$eradicationYN[tmp$tmpPoppy > 0 | tmp$eradicationYN == 1] == 1) / sum(tmp$tmpPoppy > 0 | tmp$eradicationYN == 1) # 44.4%



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

# outDTFM4$eradPercent[outDTFM4$poppyCat == "H" & outDTFM4$notGovt == 0 & outDTFM4$eradPercent > .06]
# outDTFM4$eradPercent[outDTFM4$poppyCat == "H" & outDTFM4$notGovt == 1 & outDTFM4$eradPercent > .06]
# 
# head(as.factor(outDTFM4$notGovt))
# sum(outDTFM4$poppyCat == "H" & outDTFM4$notGovt == 0) # 30
# sum(outDTFM4$poppyCat == "H" & outDTFM4$notGovt == 1) # 40

########################## fig 5A ############################
pdf(file.path(OUT_GENERAL, "1-10-24fig5a.pdf"), width = 8, height = 4.5)
# pdf(file.path(OUT_GENERAL, "9-26-23fig5a.pdf"), width = 8, height = 5)
outDTFM4 %>%
  filter(poppyCat == "H") %>%
  filter(eradicationYN == 1) %>%
  ggplot(aes(x = eradPercent, 
             fill = as.factor(notGovt))
  ) +
  geom_histogram(alpha = .8, 
                 position = "identity",
                 bins = 50
  ) +
  theme_classic(base_size = 14) +
  scale_fill_manual(
    # values = rev(c("#440154", "#21908C", "#FDE725")),
    values = c("#FFBF00", "#40B5AD")##,
    # labels = c("None", "Low", "High")
  ) +
  theme(
    legend.position = c(1, 1.02),
    legend.justification = c("right", "top"),
    plot.title = element_text(size = 15, face = "bold"),
    axis.text = element_text(size=14),
    axis.title = element_text(size=14),
  ) +
  labs(
    fill = "Taliban",
    x = "Eradication Percentage",
    y = "Count",
    title = "High-cultivation districts with eradication"
  )
dev.off()


################################# REGS START HERE ##################################
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


plot1 <- outDTF %>%
  mutate(label = paste0(3:1, ": ", label)) %>%
  ggplot(aes(x = label, y = estimate))+
  geom_pointrange(aes(ymin = CIlow, ymax = CIhigh)
  ) + # fatten changes the circles only; size changes bars and legend circles
  theme_classic() + 
  geom_hline(yintercept = 0, colour = "grey60", linetype = 2) + 
  guides(color = guide_legend(override.aes = list(linetype = "blank")), 
         linetype = "none" # suppress line for first plot; only do color
  ) +  # shape for the type of dot
  theme(plot.title = element_text(size = 15, face = "bold"),
        axis.text = element_text(size=14),
        axis.title = element_text(size=14),
  ) +
  labs(#title = paste0("Effect of violence on destination of movers: non-capitals"),
    y = "Increase in in-migration from baseline during harvest",
    x = ""
  ) +
  # labs(tag = "Model 1: yes/no\neradication 
  #      \n\n\n Model 2: \neradication > 3% 
  #      \n\n\n Model 3: \neradication > 4%") +
  # theme(plot.tag.position = c(-.1, .57),
  #       text = element_text(size = 12),
  #       plot.margin = theme_get()$plot.margin + unit(c(0, 0, 0, 4), "cm")
  # ) +
  coord_flip(clip = "off", ylim = c(-.13, 0.05)) +
  # annotate(x = 2.5, xend = 2.5, y = -.123, yend = .052,
  #          geom = "segment",
  #          colour = "#a8a5a5", size = 1.4) +
  # annotate(x = 4.5, xend = 4.5, y = -.123, yend = .052,
  #          geom = "segment",
  #          colour = "#a8a5a5", size = 1.4) +
  # geom_vline(xintercept = 2.5, colour = "grey60", linetype = 2) +
  scale_x_discrete(labels = c("High*Eradication Percent", "Eradication Percent", "High-cultivation")) # bottom to top 


2*pnorm(outDTF$estimate[3]/sqrt(outDTF$variance[3]), lower.tail = TRUE) # 0.0477396
# just reading off summary results: 0.048182

pdf(file.path(OUT_GENERAL, "1-10-24fig6b_2020.pdf"), width = 8, height = 2.8)
# pdf(file.path(OUT_GENERAL, "10-24-23fig6b_2020.pdf"), width = 8, height = 3)
gridExtra::grid.arrange(plot1, nrow = 1)
dev.off()
