source("config.R")
library(ggplot2)
library(dplyr)

######### Figure 1A: pixel-level MODIS peak dates for district 2407 (Maywand)

bestDatesFile <- readRDS(AGR_BEST_DATES_RDS)
outFile       <- readRDS(AGR_BEST_DATES_NDVI_RDS)
for (tmpCol in 3:9) {
  tmpNAs <- which(outFile[, tmpCol] <= .3)  # NDVI filter
  bestDatesFile[tmpNAs, tmpCol] <- NA
}

maywandOnly <- bestDatesFile %>%
  filter(distIDs == 2407)

sites <- sf::st_as_sf(maywandOnly,
                      coords = c("Longitude", "Latitude"),
                      crs = 4326) %>%
  sf::st_transform(crs = 32642)

saveRDS(sites, file = "./paper_figures_tables/data/fig1a.rds")


# Figure 1C data is produced by 2a_fig1.R:
#   save(tmp, relevantRows, conflictDist, file = "./paper_figures_tables/data/fig1c.RData")
