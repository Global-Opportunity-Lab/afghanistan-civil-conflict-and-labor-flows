rm(list=ls()); gc()
library(sf)
library(dplyr)
library(ggplot2)

## for file ./demo/data/figS1.Rdata
# load(AFG_SHAPE_DATA)
#
# covariates <- readRDS(COVARIATES_RDS) %>%
#   select(-geometry)
# 
# afghanShape <- afghanShape %>%
#   left_join(covariates %>% 
#               filter(year == 2018) %>%
#               select(distid, poppyCat, notGovt),
#             by = c("DISTID" = "distid"))
# 
# afghanShape <- afghanShape %>%
#   select(poppyCat, notGovt)
# save(afghanShape, file = "./paper_figures_tables/data/figS1.Rdata")

load("./paper_figures_tables/data/figS1.Rdata")

pdf("./paper_figures_tables/output/figS1.pdf", width = 8, height = 6)

viridisThreeColor <- c("#fde72566", "#21918c66", "#44015466") # 66 for 40% transparency

print(
  ggplot() +
    geom_sf(data = afghanShape, aes(fill = poppyCat)) +
    scale_fill_manual(values = viridisThreeColor,
                      labels = c("None", "Low", "High"),
                      name = "Poppy Cultivation\nIntensity")
  # geom_sf(data = sites, size = .6) #+ NOTE: commented out for privacy
)

print(
  ggplot() +
    geom_sf(data = afghanShape, aes(fill = as.factor(notGovt))) +
    scale_fill_viridis_d(alpha = .5,
                         name = "Taliban\npresence")
  # geom_sf(data = sites, size = .6) #+ NOTE: commented out for privacy
)

dev.off()
