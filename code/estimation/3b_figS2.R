# NDVI dates over time showing harvest season for high-growing districts 


rm(list = ls()); gc()
source("config.R")
bestDatesLong <- readRDS(BEST_DATES_SAT) #%>%
# select(distIDs, year, maxDate) %>%
# rename("distID" = "distIDs",
#        "date" = "maxDate") %>%
# tidyr::pivot_wider(names_from = "year",
#                    values_from = "date",
#                    # values_from = "bestDatesM2",
#                    names_prefix = "year_")

outcome1 <- readRDS(INMIG_OUTCOME_RDS)
covariates <- readRDS(COVARIATES_RDS) %>%
  dplyr::select(-geometry) # this version should have poppyCat, talibanCurrent and inaccessibleCurrent

outDTFM4 <- covariates %>%
  left_join(outcome1, by = c("distid", "year")) %>%
  mutate(prov = floor(distid/100)) %>%
  filter(!is.na(maxIn)) 

highGrowing <- outDTFM4 %>%
  filter(poppyCat == "H")


### make a data frame that is district x 16-day period 
# then a heatmap 


tmpDates <- sort(unique(bestDatesLong$maxDate[!is.na(bestDatesLong$maxDate)]))
allDates <- c(
  seq(as.Date("2014-01-01"), as.Date("2015-01-01"), "16 days"),
  seq(as.Date("2015-01-01"), as.Date("2016-01-01"), "16 days"),
  seq(as.Date("2016-01-01"), as.Date("2017-01-01"), "16 days"),
  seq(as.Date("2017-01-01"), as.Date("2018-01-01"), "16 days"),
  seq(as.Date("2018-01-01"), as.Date("2019-01-01"), "16 days"),
  seq(as.Date("2019-01-01"), as.Date("2020-01-01"), "16 days"),
  seq(as.Date("2020-01-01"), as.Date("2021-01-01"), "16 days")
)
sum(tmpDates %in% allDates)


# districts to use: those that were high-growing in the most years 

unique(highGrowing$distid)

tmp <- highGrowing %>%
  group_by(distid) %>%
  summarize(numYears = n()) %>%
  arrange(-numYears)

#    distid numYears
#     <dbl>    <int>
#  1   1115        6
#  2   2301        6
#  3   2302        6
#  4   2307        6
#  5   2407        6
#  6   2416        6
#  7    805        5
#  8   1906        5
#  9   2205        5
# 10    807        4

topDistIDs <- tmp$distid[1:10]
plotDTF <- expand.grid(distid = topDistIDs, date = allDates)
plotDTF <- plotDTF %>%
  left_join(bestDatesLong %>%
              select(distIDs, maxDate, year) %>%
              mutate(maxDate = as.Date(maxDate)),
            by = c("distid" = "distIDs",
                   "date" = "maxDate"))

pdf(file.path(OUT_REVIEW1, "agrTimelineDates.pdf"), width = 8, height = 4)
plotDTF %>%
  mutate(distid = ifelse(distid == 1115, 0, distid)) %>% # hack so that 1115 appears below
  mutate(val = ifelse(is.na(year), 0, 1),
         distid = as.factor(distid)) %>%
  ggplot(aes(date, distid, fill = as.factor(val))) + 
  geom_tile() +
  scale_x_date(labels=scales::date_format(format = "%m/%Y"), breaks = scales::date_breaks(width = "2 months"), expand = c(.02, .02)) +
  # theme_light() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        panel.background = element_blank(), axis.line = element_line(colour = "black")) +
  theme(axis.text.x = element_text(angle = 90, size = 8),
        legend.position = "none") +
  scale_fill_manual(values = c("white", "black")) +
  geom_vline(xintercept = seq(as.Date("2015-01-01"), as.Date("2020-01-01"), "1 year")) +
  labs(x = "", y = "") +
scale_y_discrete(labels = c("2416" = "Zhari",
                            "2407" = "Maywand",
                            "2307" = "Washer",
                            "2302" = "Nahri Sarraj",
                            "2301" = "Lashkar Gah",
                            "2205" = "Khash Rod",
                            "1906" = "Bala Murghab",
                            "807" = "Pachier Agam",
                            "805" = "Khogayani",
                            "0" = "Argo" # hack: this is 1115
))
dev.off()

# figure of Afghanistan 
afghanShape <- sf::st_read(DISTRICT_SHP, quiet = TRUE) %>%
  sf::st_transform(crs = 32642)

pdf(file.path(OUT_REVIEW1, "agrTimelineViz_blank.pdf"), width = 6, height = 5)
afghanShape %>%
  # bind_cols(tmp) %>%
  # mutate(X = ifelse(DISTID %in% topDistIDs, X, NA)) %>%
  ggplot() + 
  # theme_void() +
  geom_sf() #+
  # geom_text(aes(label = DISTID, x = X, y = Y),
  #           size = 2,
  #           fontface = "bold") +
  # labs(x = "", y = "")
dev.off()

