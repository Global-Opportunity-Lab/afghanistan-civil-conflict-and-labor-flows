# 2d_fig4.R
# Figure 4: source-district subgroup analysis. Compares excess harvest
# in-migration across source districts classified by poppy cultivation level,
# conflict exposure, and Taliban presence (H×V×T breakdown).
# Inputs:  BEST_DATES_SAT, DD_OUTCOMES_VIOLENCE_RDS, DD_OUTCOMES_CHECK_RDS,
#          SUBGROUP_HVT_BASE/HVNONT/HNONVT/HNONVNONT (+ suffix), COVARIATES_RDS,
#          FIG4A_DATA_RDS, SOURCE_HL_RDS, SOURCE_H_RDS
# Outputs: 1-12-24fig4a.pdf, 1-9-24fig4b.pdf, 1-9-24fig4c.pdf (in OUT_GENERAL)

rm(list = ls()); gc()
source("config.R")

################## fig 4a
suffix <- "_rA"# "" # "_rB" # 

bestDatesLongTmp <- readRDS(BEST_DATES_SAT) %>%
  rename("distID" = "distIDs") %>%
  select(distID, year, maxDate) %>%
  mutate(currentMonth = lubridate::floor_date(as.Date(maxDate), "month")) %>%
  mutate(maxDate = as.Date(maxDate))

ddOutcomes <- readRDS(DD_OUTCOMES_VIOLENCE_RDS)

ddOutcomes2 <- readRDS(DD_OUTCOMES_CHECK_RDS) # add propLow column from here 
ddOutcomes$propLow <- ddOutcomes2$propLow

myFun <- function(varName) {
  tmpddOutcomes <- ddOutcomes 
  names(tmpddOutcomes)[names(tmpddOutcomes) == varName] <- "percentage_in"
  
  baseline <- tmpddOutcomes %>%
    mutate(year = lubridate::year(date),
           month = lubridate::month(date)) %>%
    mutate(year = ifelse(month >= 9, year + 1, year)) %>%
    left_join(bestDatesLongTmp %>%
                select(distID, year, maxDate) %>%
                filter(year != 2017),
              by = c("district_id" = "distID", "year")) %>%
    mutate(daysFromPeak = as.numeric(date - maxDate)) %>%
    select(district_id, year, percentage_in, daysFromPeak) %>%
    filter(daysFromPeak %in% -120:-31) %>%
    filter(!is.na(percentage_in) 
           # & percentage_in != 0 
           & percentage_in != 1) %>%
    group_by(district_id, year) %>%
    summarize(numObs = n(),
              baseline = mean(percentage_in)) 
  
  return(baseline)
}

tmpbaseline1 <- myFun("propHighV_Taliban") # i = 1
tmpbaseline2 <- myFun("propHighV_NonTaliban") # i = 2
tmpbaseline3 <- myFun("propHighNonV_Taliban") # i = 3
tmpbaseline4 <- myFun("propHighNonV_NonTaliban") # i = 4
tmpbaseline5 <- myFun("propLow") # i = 5 --- this is new 

######
outcome1 <- readRDS(paste0(SUBGROUP_HVT_BASE, suffix, "_2020.rds")) # use this to filter obs (baseline period needs 90 days, etc.)
outcome2 <- readRDS(paste0(SUBGROUP_HVNONT_BASE, suffix, "_2020.rds")) # use this to filter obs (baseline period needs 90 days, etc.)
outcome3 <- readRDS(paste0(SUBGROUP_HNONVT_BASE, suffix, "_2020.rds")) # use this to filter obs (baseline period needs 90 days, etc.)
outcome4 <- readRDS(paste0(SUBGROUP_HNONVNONT_BASE, suffix, "_2020.rds")) # use this to filter obs (baseline period needs 90 days, etc.)
outcome5 <- readRDS(paste0(SUBGROUP_L_CHECK_BASE, suffix, "_2020_check.rds")) # use this to filter obs (baseline period needs 90 days, etc.)
covariates <- readRDS(COVARIATES_RDS) # this version should have poppyCat, talibanCurrent and inaccessibleCurrent

# set up 
plotDTF <- data.frame(model = c(rep("High-growing", 4), "Low-growing"), 
                      label = c("1_Violence Y, Taliban Y", 
                                "3_Violence Y, Taliban N",
                                "2_Violence N, Taliban Y",
                                "4_Violence N, Taliban N",
                                "Low"
                      ),
                      baselineMean = NA,
                      baselineMedian = NA)

for (i in 1:5) {
  baseline <- get(paste0("tmpbaseline", i))
  outcome <- get(paste0("outcome", i))
  outDTFM4 <- covariates %>%
    left_join(outcome, by = c("distid", "year")) %>%
    mutate(prov = floor(distid/100)) %>%
    filter(!is.na(maxIn)) %>%
    left_join(baseline, by = c("distid" = "district_id", "year"))
  
  outDTFM4 <- outDTFM4 %>%
    mutate(harvest = maxIn + baseline)
  
  plotDTF[i, "baselineMedian"] <- median(outDTFM4$baseline[outDTFM4$poppyCat == "H"])
  plotDTF[i, "harvestMedian"] <- median(outDTFM4$harvest[outDTFM4$poppyCat == "H"])
}

saveRDS(plotDTF, file = FIG4A_DATA_RDS)

##########################################################
rm(list = ls()); gc()
plotDTF <- readRDS(FIG4A_DATA_RDS)

plotDTF$label <- c("2_Violence Y, Taliban Y", 
                   "4_Violence Y, Taliban N",
                   "3_Violence N, Taliban Y",
                   "5_Violence N, Taliban N",
                   "1_Low")

myColors <- c("lightgray", "azure4",
              "#55c667", "#1f968b",
              "#fde725", "orange" 
              
)

# median version
plot1 <- rbind(plotDTF, data.frame(model = "High-growing", 
                                   label = "0_No growing", 
                                   baselineMedian = 1 - sum(plotDTF$baselineMedian),
                                   harvestMedian = 1 - sum(plotDTF$harvestMedian)
)) %>%
  tidyr::pivot_longer(cols = c("baselineMedian", "harvestMedian")) %>%
  mutate(name = ifelse(name == "baselineMedian", "baseline", ".harvest")) %>%
  ggplot(aes(x = as.factor(name), y = value, fill = label)) + 
  geom_bar(stat = "identity") +
  scale_fill_manual(
    # breaks = c("2_Violence Y, Taliban Y", 
    #                            "4_Violence Y, Taliban N",
    #                            "3_Violence N, Taliban Y",
    #                            "5_Violence N, Taliban N"),
    values = myColors,
      # c(myColors[3:6], myColors[1:2]),
                    labels = c(#"", "",
                      "No poppy", "Low-growing",
                               "Taliban = Yes\nViolence = Yes",
                               "Taliban = Yes\nViolence = No",
                               "Taliban = No\nViolence = Yes",
                               "Taliban = No\nViolence = No"
                               ),
                    guide = guide_legend(reverse = TRUE)
  ) +
  coord_flip() +
  theme_void() +
  labs(fill = "Source of in-migrants\n(district type)",
       y = "",
       x = "",
       # title = "Composition of in-migrants to high-growing districts"
  ) +
  theme(plot.title = element_text(size = 15, face = "bold"),
        axis.text = element_text(size=14),
        axis.title = element_text(size=14),
        legend.position = "bottom",
        legend.text = element_text(size=10),
        legend.title = element_text(size=10, face = "bold")
  ) +
  scale_x_discrete(labels = c("Harvest", "Baseline")) +
  scale_y_continuous(labels = scales::label_percent()) #+
# guides(fill = guide_legend(override.aes = list(values = c("white",
#                                                  "#fde725", "orange", 
#                                                  "#55c667", "#1f968b"
# )))) # this last row makes the transparency 100

pdf(file.path(OUT_GENERAL, "1-12-24fig4a.pdf"), width = 8, height = 4)
gridExtra::grid.arrange(plot1, nrow = 1)
dev.off()

############################ FIGURES ################################
##### HIGH/LOW results (fig 4b)
rm(list = ls()); gc()
suffix <- "_rA"#  ""  # "_rB"#  
outcome1 <- readRDS(paste0(SUBGROUP_H_CHECK_BASE, suffix, "_2020_check.rds"))
outcome2 <- readRDS(paste0(SUBGROUP_L_CHECK_BASE, suffix, "_2020_check.rds"))

covariates <- readRDS(COVARIATES_RDS) %>%
  select(-geometry)# this version should have poppyCat, talibanCurrent and inaccessibleCurrent

outDTFM4 <- covariates %>%
  left_join(outcome1, by = c("distid", "year")) %>%
  mutate(prov = floor(distid/100)) 

# categorical version
fit1 <- lm(maxIn ~ poppyCat + log(areakm2) + 
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

# fit1coefs <- lmtest::coeftest(fit1, vcov. = sandwich::vcovCL(fit1, cluster = fit1$model$prov, type = "HC1")) # takes less than a minute!
tmpDistID <- outDTFM4$distid[!is.na(outDTFM4$maxIn) & !is.na(outDTFM4$diversity) & !is.na(outDTFM4$trackPathFrac)]
fit1coefs <- lmtest::coeftest(fit1, vcov. = sandwich::vcovCL(fit1, cluster = as.factor(tmpDistID), type = "HC1")) # takes less than a minute!

outDTFM4 <- covariates %>%
  left_join(outcome2, by = c("distid", "year")) %>%
  mutate(prov = floor(distid/100)) 

# categorical version
fit2 <- lm(maxIn ~ poppyCat + log(areakm2) + 
             log(nonPoppy2) + TOTAL + as.factor(year) + as.factor(prov) +
             provincialCapital + cultivatedFrac + roadDensity + builtUpFracPop +
             trackPathFrac + healthPer100000 + diversity + as.factor(majority)+
             barrenAreaFrac, 
           data = outDTFM4 %>%
             filter(!is.na(maxIn)
                    # & year < 2017
                    # & year > 2017
                    # & tmpPoppy < 5000
             ))

# fit2coefs <- lmtest::coeftest(fit2, vcov. = sandwich::vcovCL(fit2, cluster = fit2$model$prov, type = "HC1")) # takes less than a minute!
tmpDistID <- outDTFM4$distid[!is.na(outDTFM4$maxIn) & !is.na(outDTFM4$diversity) & !is.na(outDTFM4$trackPathFrac)]
fit2coefs <- lmtest::coeftest(fit2, vcov. = sandwich::vcovCL(fit2, cluster = as.factor(tmpDistID), type = "HC1")) # takes less than a minute!

outDTF <- data.frame(label = c("High-growing",
                               "Low-growing"
),
estimate = NA,
CIlow = NA,
CIhigh = NA)


for (i in 1:2) {
  tmp <- get(paste0("fit", i, "coefs"))
  outDTF[i, "estimate"] <- tmp["poppyCatH", "Estimate"]
  outDTF[i, "CIlow"] <- tmp["poppyCatH", "Estimate"] - qnorm(.975)*tmp["poppyCatH", "Std. Error"]
  outDTF[i, "CIhigh"] <- tmp["poppyCatH", "Estimate"] + qnorm(.975)*tmp["poppyCatH", "Std. Error"]
}

saveRDS(outDTF, file = SOURCE_HL_RDS)
#          label    estimate       CIlow     CIhigh
# 1 High-growing 0.047316630  0.01721958 0.07741368
# 2  Low-growing 0.006960807 -0.01459271 0.02851432

rm(list = ls()); gc()
outDTF <- readRDS(SOURCE_HL_RDS)
outDTF$variance <- ((outDTF$CIhigh - outDTF$estimate)/qnorm(.975))^2
outDTF$p <- 2*pnorm(abs(outDTF$estimate)/sqrt(outDTF$variance), lower.tail = FALSE)
#          label    estimate       CIlow     CIhigh     variance           p
# 1 High-growing 0.047316630  0.01721958 0.07741368 0.0002358043 0.002060793
# 2  Low-growing 0.006960807 -0.01459271 0.02851432 0.0001209317 0.526747058


plot1 <- outDTF %>%
  ggplot(aes(label, estimate))+
  geom_pointrange(aes(ymin = CIlow, ymax = CIhigh) 
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
    # title = "Post-2017",
    # title = "Pre-2017",
    y = "Increase in in-migration, by type of source district",
    # y = "Increase in-migrant proportion from source districts\nwith specified characteristics (harvest compared to baseline)",
    x = ""
  ) +
  # labs(tag = "Violence = Yes \n\n\n\n\n Violence = No") +
  # theme(plot.tag.position = c(-.07, .57),
  #       text = element_text(size = 12),
  #       plot.margin = theme_get()$plot.margin + unit(c(0, 0, 0, 3), "cm")
  # ) +
  coord_flip(
    # clip = "off"
    # , ylim = c(0, 0.04)
  ) + 
scale_x_discrete(labels = c("High-cultivation\nsources", "Low-cultivation\nsources")) + # bottom to top
  theme(axis.text.y  = element_text(hjust=0.5))

# pdf(file.path(OUT_GENERAL, "8-1-23fig4b.pdf"), width = 7, height = 2)
pdf(file.path(OUT_GENERAL, "1-9-24fig4b.pdf"), width = 7, height = 2)
gridExtra::grid.arrange(plot1, nrow = 1)
dev.off()

###### source results (fig 4c)
# violence H T
rm(list = ls()); gc()
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
fit1 <- lm(maxIn ~ poppyCat + log(areakm2) + 
             log(nonPoppy2) + TOTAL + as.factor(year) + as.factor(prov) +
             provincialCapital + cultivatedFrac + roadDensity + builtUpFracPop +
             trackPathFrac + healthPer100000 + diversity + as.factor(majority)+
             barrenAreaFrac, 
           data = outDTFM4 %>%
             filter(!is.na(maxIn) 
                    # & year != 2016
                    # & year > 2014
                    # & tmpPoppy < 5000
             ) )

# fit1coefs <- lmtest::coeftest(fit1, vcov. = sandwich::vcovCL(fit1, cluster = fit1$model$prov, type = "HC1")) # takes less than a minute!
tmpDistID <- outDTFM4$distid[!is.na(outDTFM4$maxIn) & !is.na(outDTFM4$diversity) & !is.na(outDTFM4$trackPathFrac)]
fit1coefs <- lmtest::coeftest(fit1, vcov. = sandwich::vcovCL(fit1, cluster = as.factor(tmpDistID), type = "HC1")) # takes less than a minute!

outDTFM4 <- covariates %>%
  left_join(outcome2, by = c("distid", "year")) %>%
  mutate(prov = floor(distid/100)) 

# categorical version
fit2 <- lm(maxIn ~ poppyCat + log(areakm2) + 
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

# fit2coefs <- lmtest::coeftest(fit2, vcov. = sandwich::vcovCL(fit2, cluster = fit2$model$prov, type = "HC1")) # takes less than a minute!
tmpDistID <- outDTFM4$distid[!is.na(outDTFM4$maxIn) & !is.na(outDTFM4$diversity) & !is.na(outDTFM4$trackPathFrac)]
fit2coefs <- lmtest::coeftest(fit2, vcov. = sandwich::vcovCL(fit2, cluster = as.factor(tmpDistID), type = "HC1")) # takes less than a minute!

outDTFM4 <- covariates %>%
  left_join(outcome3, by = c("distid", "year")) %>%
  mutate(prov = floor(distid/100)) 

# categorical version
fit3 <- lm(maxIn ~ poppyCat + log(areakm2) + 
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

# fit3coefs <- lmtest::coeftest(fit3, vcov. = sandwich::vcovCL(fit3, cluster = fit3$model$prov, type = "HC1")) # takes less than a minute!
tmpDistID <- outDTFM4$distid[!is.na(outDTFM4$maxIn) & !is.na(outDTFM4$diversity) & !is.na(outDTFM4$trackPathFrac)]
fit3coefs <- lmtest::coeftest(fit3, vcov. = sandwich::vcovCL(fit3, cluster = as.factor(tmpDistID), type = "HC1")) # takes less than a minute!

outDTFM4 <- covariates %>%
  left_join(outcome4, by = c("distid", "year")) %>%
  mutate(prov = floor(distid/100)) 

# categorical version
fit4 <- lm(maxIn ~ poppyCat + log(areakm2) + 
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

# fit4coefs <- lmtest::coeftest(fit4, vcov. = sandwich::vcovCL(fit4, cluster = fit4$model$prov, type = "HC1")) # takes less than a minute!
tmpDistID <- outDTFM4$distid[!is.na(outDTFM4$maxIn) & !is.na(outDTFM4$diversity) & !is.na(outDTFM4$trackPathFrac)]
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
}


saveRDS(outDTF, file = SOURCE_H_RDS)

###########################################
rm(list = ls()); gc()
outDTF <- readRDS(SOURCE_H_RDS)
outDTF$variance <- ((outDTF$CIhigh - outDTF$estimate)/qnorm(.975))^2
outDTF$p <- 2*pnorm(abs(outDTF$estimate)/sqrt(outDTF$variance), lower.tail = FALSE)
#          model                 label   estimate         CIlow     CIhigh     variance          p
# 1 High-growing Violence Y, Taliban Y 0.02060953  0.0009557871 0.04026328 1.005529e-04 0.03985201
# 2 High-growing Violence Y, Taliban N 0.01561743  0.0010861429 0.03014872 5.496826e-05 0.03516426
# 3 High-growing Violence N, Taliban Y 0.01531587 -0.0021557793 0.03278751 7.946419e-05 0.08577303
# 4 High-growing Violence N, Taliban N 0.01110007 -0.0004129535 0.02261310 3.450506e-05 0.05880301

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
  labs(#title = paste0("Effect of violence on destination of movers: non-capitals"),
    # title = "Post-2017",
    # title = "Pre-2017",
    # y = "Increase in-migrant proportion from source districts\nwith specified characteristics (harvest compared to baseline)",
    y = "Increase in in-migration, by type of source district",
    x = ""
  ) +
  labs(tag = "Taliban = No \n\n\n\n\n\n Taliban = Yes") +
  # labs(tag = "Violence = Yes \n\n\n\n\n Violence = No") +
  theme(plot.tag.position = c(-.07, .58),
        text = element_text(size = 12),
        plot.margin = theme_get()$plot.margin + unit(c(0, 0, 0, 3), "cm")
  ) +
  coord_flip(clip = "off"
             , ylim = c(-.005, 0.042)
             ) +
  annotate(x = 2.5, xend = 2.5, 
           y = -.025, yend = .042,
           geom = "segment",
           colour = "#a8a5a5", size = 1.4, alpha = .4) +
  # geom_vline(xintercept = 2.5, colour = "grey60", linetype = 2) +
  # scale_x_discrete(labels = c("Taliban = No", "Taliban = Yes", "Taliban = No", "Taliban = Yes")) # bottom to top 
  scale_x_discrete(labels = c("Violence = Yes", "Violence = No", "Violence = Yes", "Violence = No")) # bottom to top 


# pdf(file.path(OUT_GENERAL, "10-24-23fig4c.pdf"), width = 8, height = 3)
pdf(file.path(OUT_GENERAL, "1-9-24fig4c.pdf"), width = 7, height = 3.5)
gridExtra::grid.arrange(plot1, nrow = 1)
dev.off()






