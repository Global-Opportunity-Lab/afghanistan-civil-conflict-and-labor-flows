################################## FIGURES ################################
library(dplyr); library(ggplot2)
### fig 2a and b
rm(list = ls()); gc()
source("config.R")
distYears <- readRDS(DIST_YEARS_RDS)
covariates <- readRDS(COVARIATES_RDS) %>%
  select(-geometry)

outDTF <- readRDS(RESULTS_INMIG_RDS)
# outDTF <- readRDS("/home/xtai/climate/3-8-23migrationCleanCode/output/7-31-23results_outMigration_2020.rds")

outDTF <- outDTF %>%
  left_join(covariates %>%
              select(distid, year, poppy, poppyCat),
            by = c("distid", "year"))

forPlot <- outDTF %>%
  mutate(distidYear = paste0(distid, "_", year)) %>% # new for missing data
  filter(distidYear %in% distYears) %>% # new for missing data
  group_by(poppyCat, daysFromPeak) %>%
  summarize(meanEffect = mean(estimate),
            # count = n(),
            var = sum(se^2, na.rm = TRUE)/(n()^2)) %>%
  mutate(conf.low = meanEffect - qnorm(.975)*sqrt(var),
         conf.high = meanEffect + qnorm(.975)*sqrt(var))

viridisThreeColor <- c("#fde725", "#21918c", "#440154")

pdf(file.path(OUT_GENERAL, "8-1-23fig2a.pdf"), width = 10, height = 5)
# pdf(file.path(OUT_GENERAL, "8-1-23fig2b.pdf"), width = 10, height = 5)
forPlot %>%
  ggplot(aes(daysFromPeak, meanEffect, col = poppyCat))+
  geom_point()+
  geom_pointrange(aes(ymin = (conf.low),
                      ymax = (conf.high),
                      col = poppyCat),
                  position = position_dodge(width = .5)) +
  labs(
    x = "Days since district's peak NDVI (16-day MODIS)",
    y = "Daily increase in in-migration rate from baseline",
    # y = "Daily increase in out-migration rate from baseline",
    col = "Poppy Cultivation\nIntensity") +
  geom_vline(xintercept = 0, color = "red3", linetype = 2) + 
  geom_hline(yintercept = 0, color = "red3") +
  scale_x_continuous(breaks = seq(-180, 180, 10)) +
  # scale_y_continuous(breaks = seq(-1, 1.75, .25)) +
  theme_classic(base_size = 14) +
  scale_color_manual(values = viridisThreeColor,
                     labels = c("None", "Low", "High")
  ) +
  theme(
    legend.position = c(1, 1.02),
    legend.justification = c("right", "top"),
    # legend.title = element_blank(),
    legend.text = element_text(size=14),
    axis.text=element_text(size=14),
    axis.title=element_text(size=14),
    axis.text.x = element_text(size = 14)) +
  guides(col = guide_legend(override.aes = list(shape = 15, size = 1.7)))
dev.off()

# report p-value:
tmp <- forPlot %>% filter(poppyCat == "H" & daysFromPeak == 21)
2*pnorm(tmp$meanEffect/sqrt(tmp$var), lower.tail = FALSE) # 

### fig 2c
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

# fit1coefs <- lmtest::coeftest(fit1, vcov. = sandwich::vcovCL(fit1, cluster = fit1$model$`as.factor(prov)`, type = "HC1")) 
# the ones I want are poppyCatL and poppyCatH
tmpDistID <- outDTFM4$distid[!is.na(outDTFM4$maxIn) & !is.na(outDTFM4$diversity) & !is.na(outDTFM4$trackPathFrac)]
fit1coefs <- lmtest::coeftest(fit1, vcov. = sandwich::vcovCL(fit1, cluster = as.factor(tmpDistID), type = "HC1")) # takes less than a minute!


# for plot
tmp <- fit1coefs[c("poppyCatL", "poppyCatH"), c("Estimate", "Std. Error")]
plotDTF <- data.frame(model = "Overall", label = c("Low-cultivation", "High-cultivation"), estimate = tmp[, "Estimate"], CIlow = tmp[, "Estimate"] - 1.96*tmp[, "Std. Error"], CIhigh = tmp[, "Estimate"] + 1.96*tmp[, "Std. Error"])

plot1 <- plotDTF %>%
  ggplot(aes(label, estimate)) +
  theme_classic()+
  geom_pointrange(aes(ymin = CIlow, ymax = CIhigh),
                  # position = position_dodge(width = .4),
                  # size = .4, fatten = 2) +
                  # size = 1.4, fatten = 2
  ) + # fatten changes the circles only; size changes bars and legend circles
  coord_flip() + 
  geom_hline(yintercept = 0, colour = "grey60", linetype = 2) + 
  guides(color = guide_legend(override.aes = list(linetype = "blank")), 
         # linetype = guide_legend(override.aes = list(shape = NA))
         linetype = FALSE # suppress line for first plot; only do color
  ) +  # shape for the type of dot
  # scale_y_continuous(limits = c(-.002, .032)) +
  theme(axis.text = element_text(size = 14),
        axis.title=element_text(size=14)
  ) +
  labs(#title = paste0("Effect of violence on destination of movers: non-capitals"),
    y = "Increase in in-migration from baseline during harvest",
    x = "",
  ) 

pdf(file.path(OUT_GENERAL, "1-9-24fig2c.pdf"), width = 6.5, height = 1.5)
# pdf(file.path(OUT_GENERAL, "8-1-23fig2c.pdf"), width = 6.5, height = 1.5)
gridExtra::grid.arrange(plot1, nrow = 1)
dev.off()

2*pnorm(tmp[2, 1]/tmp[2, 2], lower.tail = FALSE) # 0.001256662


covariates %>% 
  select(distid, TOTAL, poppyCat, year) %>%
  filter(poppyCat == "H" & year == 2016) %>%
  arrange(desc(TOTAL))
#    distid  TOTAL poppyCat year
# 1    1804 145446        H 2016
# 42   2415  13680        H 2016

sum(covariates$TOTAL[covariates$year == 2014 & covariates$poppyCat == "H"])*.0271 # 72775.59
sum(covariates$TOTAL[covariates$year == 2015 & covariates$poppyCat == "H"])*.0271 # 68742.27
sum(covariates$TOTAL[covariates$year == 2018 & covariates$poppyCat == "H"])*.0271 # 85056.79
sum(covariates$TOTAL[covariates$year == 2019 & covariates$poppyCat == "H"])*.0271 # 54047.51
sum(covariates$TOTAL[covariates$year == 2020 & covariates$poppyCat == "H"])*.0271 # 73647.66

############# fig 2d
# don't clear data from fig 2c
ddOutcomes <- readRDS(DD_OUTCOMES_RDS)

bestDatesLongTmp <- readRDS(BEST_DATES_SAT) %>%
  rename("distID" = "distIDs") %>%
  dplyr::select(distID, year, maxDate) %>%
  mutate(currentMonth = lubridate::floor_date(as.Date(maxDate), "month")) %>%
  mutate(maxDate = as.Date(maxDate))

baseline <- ddOutcomes %>%
  mutate(year = lubridate::year(date),
         month = lubridate::month(date)) %>%
  mutate(year = ifelse(month >= 9, year + 1, year)) %>%
  left_join(bestDatesLongTmp %>%
              dplyr::select(distID, year, maxDate) %>%
              filter(year != 2017)
              ,
            by = c("district_id" = "distID", "year")) %>%
  mutate(daysFromPeak = as.numeric(date - maxDate)) %>%
  dplyr::select(district_id, year, percentage_in, daysFromPeak) %>%
  filter(daysFromPeak %in% -120:-31) %>%
  filter(!is.na(percentage_in) & percentage_in != 0 & percentage_in != 1) %>%
  group_by(district_id, year) %>%
  summarize(numObs = n(),
            baseline = mean(percentage_in)) 

viridisThreeColor <- c("#440154E6", "#21908C80", "#FDE72580") # first is purple
# transparency is 90 (E6), 50, 50%

outDTFM4 <- outDTFM4 %>%
  left_join(baseline, by = c("distid" = "district_id", "year"))

outDTFM4 <- outDTFM4 %>%
  mutate(harvest = maxIn + baseline)

# position = "identity" overlaps the bars (default is to stack, which we don't want)
plot1 <- outDTFM4 %>%
  ggplot(aes(x = baseline, fill = poppyCat)) +
  geom_histogram(
    position = "identity"#,
    # binwidth = 5000,
    # alpha = .6
  ) + 
  # theme_classic() +
  # scale_y_continuous(labels = scales::percent) +
  scale_fill_manual(
    # values = rev(c("#440154", "#21908C", "#FDE725")),
    values = rev(viridisThreeColor),
    labels = c("None", "Low", "High")
  ) +
  xlim(c(0, .23)) +
  geom_vline(xintercept = c(median(outDTFM4$baseline[outDTFM4$poppyCat == "N"]), # 0.04390979
                            median(outDTFM4$baseline[outDTFM4$poppyCat == "L"]), # 0.04326012
                            median(outDTFM4$baseline[outDTFM4$poppyCat == "H"])), # 0.0361361
             color = rev(scales::viridis_pal()(3)),
             lwd = 1.3) +
  geom_vline(xintercept = c(median(outDTFM4$baseline[outDTFM4$poppyCat == "N"]),
                            median(outDTFM4$baseline[outDTFM4$poppyCat == "L"]),
                            median(outDTFM4$baseline[outDTFM4$poppyCat == "H"])),
             color = "black",
             lty = 3) +
  theme_classic(base_size = 14) +
  labs(x = "Baseline in-migration rate",
       fill = "Poppy Cultivation\nIntensity",
       # y = "Percentage"
       y = "Count"
  ) +
  theme(legend.position = c(1, 1.02),
        legend.justification = c("right", "top"),
        legend.title = element_text(size=14),
        legend.text = element_text(size=14),
        axis.text=element_text(size=14),
        axis.title=element_text(size=14),
        axis.text.y = element_text(
          # angle = 90, 
          # vjust = 0,
          vjust = .5,
          hjust = 1)
  ) +
  guides(fill = guide_legend(override.aes = list(alpha = 1))) # this last row makes the transparency 100


plot2 <- outDTFM4 %>%
  ggplot(aes(x = harvest, fill = poppyCat)) +
  geom_histogram(
    position = "identity"#,
    # binwidth = 5000,
    # alpha = 0.5
  ) +
  scale_fill_manual(
    # values = rev(c("#440154", "#21908C", "#FDE725")),
    values = rev(viridisThreeColor),
    labels = c("None", "Low", "High")
  )+ 
  labs(x = "In-migration rate during harvest",
       fill = "Poppy Cultivation\nIntensity",
       y = "Count"
  )+
  xlim(c(0, .23)) +
  geom_vline(xintercept = c(median(outDTFM4$harvest[outDTFM4$poppyCat == "N"]),
                            median(outDTFM4$harvest[outDTFM4$poppyCat == "L"]),
                            median(outDTFM4$harvest[outDTFM4$poppyCat == "H"])),
             color = rev(scales::viridis_pal()(3)),
             lwd = 1.3)+
  geom_vline(xintercept = c(median(outDTFM4$harvest[outDTFM4$poppyCat == "N"]),
                            median(outDTFM4$harvest[outDTFM4$poppyCat == "L"]),
                            median(outDTFM4$harvest[outDTFM4$poppyCat == "H"])),
             color = "black",
             lty = 3) +
  theme_classic(base_size = 14) +
  theme(
    legend.position = c(1, 1.02),
    legend.justification = c("right", "top"),
    legend.title = element_text(size=14),
    legend.text = element_text(size=14),
    # legend.position = "none",
    axis.text=element_text(size=14),
    axis.title=element_text(size=14),
    axis.text.y = element_text(
      # angle = 90, 
      # vjust = 0,
      vjust = .5,
      hjust = 1)
  ) +
  guides(fill = guide_legend(override.aes = list(alpha = 1))) 

pdf(file.path(OUT_GENERAL, "1-12-24fig2d.pdf"), width = 8, height = 7)
gridExtra::grid.arrange(plot1, plot2, nrow = 2)
dev.off()



