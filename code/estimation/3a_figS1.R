rm(list=ls()); gc()
library(sf)
library(dplyr)
library(ggplot2)

source("config.R")
load(AFG_SHAPE_DATA)

covariates <- readRDS(COVARIATES_RDS) %>%
  select(-geometry)

afghanShape <- afghanShape %>%
  left_join(covariates %>% 
              filter(year == 2018) %>%
              select(distid, poppyCat),
            by = c("DISTID" = "distid"))
################### tower groups 
# /data/afg_anon/tower_datasets/tower_groups/v2020/towers_with_group_id.csv
towerGroups <- read.csv(TOWER_GROUPS)
towerGroups <- towerGroups %>%
  filter(tower_group_latitude < 40 & tower_group_longitude > 60.12) 

sites <- sf::st_as_sf(towerGroups, coords = c("tower_group_longitude", "tower_group_latitude"), 
                      crs = 4326) %>% 
  sf::st_transform(crs = 32642)

viridisThreeColor <- c("#fde72566", "#21918c66", "#44015466") # 66 for 40% transparency

pdf(file.path(OUT_GENERAL, "10-13-23map.pdf"), width = 8, height = 5)
ggplot() + 
  # theme_void() +
  geom_sf(data = afghanShape, aes(fill = poppyCat)) + # 1/28: remove Kabul
  scale_fill_manual(values = viridisThreeColor,
                     labels = c("None", "Low", "High"),
                    name = "Poppy Cultivation\nIntensity"
  ) +
  # viridis::scale_fill_viridis(alpha = .4, name = "Poppy category", discrete = TRUE) +
  # labs(title = paste0("Afghanistan Districts: ", nrow(eventsCoords), " violent events in red, \n1439 cell tower groups in black")) + 
  geom_sf(data = sites, size = .6) #+ 
  # geom_sf(data = eventsCoords, size = .3, shape = 21, fill = "darkred", col = "darkred", alpha = .7)
# gridExtra::grid.arrange(plot1, nrow = 1)
dev.off()



districts <- sf::st_intersects(afghanShape, sites, sparse = FALSE) # this is 398 by 2716 --- each event is on a column
whichDistricts <- apply(districts, MARGIN = 2, FUN = function(x) which(x == TRUE)) # this will only work with points
distIDs <- afghanShape$DISTID[unlist(whichDistricts)]
length(unique(distIDs)) # 292
afghanShape$phoneData <- ifelse(afghanShape$DISTID %in% distIDs, 1, 0)
xtabs(~ phoneData + poppyCat, data = afghanShape)
#          poppyCat
# phoneData   N   L   H
#         0  56  40  10
#         1 165  93  34

