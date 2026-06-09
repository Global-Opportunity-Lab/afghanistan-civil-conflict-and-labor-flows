# 2a_fig1.R
# Figure 1: district-level daily migration time series for an example high-poppy
# district (Maywand, distID 2407) illustrating the harvest-season in-migration spike.
rm(list = ls()); gc()
source("config.R")

#### harvest dates
bestDatesLong <- readRDS(BEST_DATES_SAT) %>%
  select(distIDs, year, maxDate) %>%
  rename("distID" = "distIDs",
         "date" = "maxDate")

##########
### for in-migration
outData <- readRDS(K30_INMIG_RDS)

getImpacted <- readRDS(K30_IMPACTED_RDS) %>% # this is for drop T
  rename(district_id = origin_district) %>%
  mutate(date = as.Date("2013-04-01") + lubridate::days(impact_day - 1)) %>%
  select(-impact_day)

ddOutcomes <- getImpacted %>%
  select(district_id, date) %>%
  left_join(outData %>%
              select(destination_district, date, numNew),
            by = c("district_id" = "destination_district", "date")) %>%
  left_join(getImpacted, by = c("district_id", "date")) %>%
  mutate(percentage_in = numNew/impacted) #%>% # NaN when 0/0, i.e., no one around
# select(-numNew)

# out-migration
ddOutcomesOut <- readRDS(K30_OUTMIG_RDS) %>% 
  ungroup()

ddOutcomes <- ddOutcomes %>% 
  left_join(ddOutcomesOut %>%
              select(origin_district, date, percentage_migrated),
            by = c("district_id" = "origin_district", "date"))

### other setup: district names
districtInfo <- readRDS(DISTRICT_IDS)
districtInfo$provDistName <- paste0(districtInfo$prov_name, "-", districtInfo$dist_name)

distIDs <- unique(ddOutcomes$district_id)

#### other setup: print poppy cultivation amounts 
unodcData <- read.csv(POPPY_CSV)
# wide to long
poppyLong <- unodcData %>%
  tidyr::pivot_longer(cols = starts_with("X"), 
                      names_to = "year", 
                      names_prefix = "X", 
                      names_transform = list(year = as.numeric),
                      values_to = "poppy") %>%
  filter(year %in% 2012:2020)

conflictData <- read.csv(CONFLICT_CSV)

#### just migration lines for presentation 
inputDist <- 2407
i <- which(distIDs == inputDist)
tmp <- ddOutcomes %>%
  filter(district_id == distIDs[i]) %>%
  select(district_id, date, percentage_migrated, percentage_in) %>%
  filter(date >= as.Date("2014-01-01") & date <= as.Date("2016-01-01"))

# for peak NDVI
relevantRows <- bestDatesLong %>%
  filter(distID == distIDs[i])  %>%
  filter(year %in% 2014:2016)

plot1 <- tmp %>%
  ggplot2::ggplot() +
  geom_line(aes(x = date, y = percentage_migrated, col = "Percentage out")) +
  geom_line(aes(x = date, y = percentage_in, col = "Percentage in")) + 
  # geom_line() #+ 
  labs(title = paste0("Proportion migrating in and out: distID ", distIDs[i], ", ", districtInfo$provDistName[districtInfo$distid == distIDs[i]], 
                      "\nPoppy (ha): ", 
                      paste(2012:2020, poppyLong$poppy[poppyLong$distid == distIDs[i]], sep = ": ", collapse = ", "),
                      "\nVertical lines are peak MODIS NDVI (M4)"),
       x = "Date",
       y = "Percentage",
       col = "") +
  scale_x_date(labels=scales::date_format(format = "%Y-%m-%d"), 
               breaks = scales::date_breaks(width = "1 month"), 
               expand = c(.02, .02),
               # limits = c(as.Date("2014-01-01"), as.Date("2017-01-01"))) +
               limits = c(as.Date("2014-01-01"), as.Date("2016-01-01"))) +
  ylim(-.03, .25) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "right") +
  geom_vline(xintercept = as.Date(relevantRows$date), color = "black", lwd = .1) 


# violence
conflictDist <- conflictData %>%
  filter(year %in% 2014:2015 & where_prec <= 3 & date_prec <= 3 & DISTID == inputDist) %>%
  select(DISTID, year, date_start, where_prec, date_prec, best) 

plot1 <- plot1 +
  geom_point(data = conflictDist %>%
               rename(Casualties = best), 
             aes(x = as.Date(date_start), y = -.01, size = Casualties)) 


pdf(file.path(OUT_GENERAL, "8-1-23outcomek30ByDistrict_2407_noViolence.pdf"), width = 14, height = 5.5)
# pdf(file.path(OUT_GENERAL, "8-1-23outcomek30ByDistrict_2407.pdf"), width = 14, height = 5.5)
gridExtra::grid.arrange(plot1, nrow = 1)
dev.off()
