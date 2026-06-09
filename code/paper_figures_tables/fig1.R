library(ggplot2); library(dplyr); library(gridExtra)
rm(list = ls()); gc()

### Figure 1A: MODIS peak-NDVI dates for district 2407
sites <- readRDS("./paper_figures_tables/data/fig1a.rds")
afghanShape <- sf::st_read("./paper_figures_tables/data/district398.geojson", quiet = TRUE) %>%
  sf::st_transform(crs = 32642)

i <- 2019
plot1 <- ggplot() +
  geom_sf(data = afghanShape %>%
            filter(DISTID == 2407)) +
  geom_sf(data = sites %>%
            rename(tmpVar = paste0("Best.Start.Date.", i)) %>%
            filter(!is.na(tmpVar)) %>%
            mutate(tmpVar = as.Date(tmpVar)),
          size = .3,
          aes(color = tmpVar)) +
  viridis::scale_color_viridis(
    alpha = .4,
    name = "Mode",
    breaks = seq(as.Date(paste0(i, "-01-01")), as.Date(paste0(i, "-06-30")), by = 16)
  ) +
  theme(legend.text = element_text(size=6)) +
  labs(title = "MODIS dates in first half of year")

pdf("./paper_figures_tables/output/fig1a.pdf", width = 8, height = 5)
gridExtra::grid.arrange(plot1, nrow = 1)
dev.off()


### Figure 1C: In/out-migration time series for district 2407
load("./paper_figures_tables/data/fig1c.RData")  # loads: tmp, relevantRows, conflictDist

plot1 <- tmp %>%
  ggplot2::ggplot() +
  geom_line(aes(x = date, y = percentage_migrated, col = "Percentage out")) +
  geom_line(aes(x = date, y = percentage_in, col = "Percentage in")) +
  labs(x = "", y = "", col = "") +
  scale_x_date(labels=scales::date_format(format = "%Y-%m-%d"),
               breaks = scales::date_breaks(width = "1 month"),
               expand = c(.02, .02),
               limits = c(as.Date("2014-01-01"), as.Date("2016-01-01"))) +
  ylim(-.03, .25) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "right") +
  geom_vline(xintercept = as.Date(relevantRows$date), color = "black", lwd = .1) +
  geom_point(data = conflictDist %>%
               rename(Casualties = best),
             aes(x = as.Date(date_start), y = -.01, size = Casualties))

pdf("./paper_figures_tables/output/fig1c.pdf", width = 10, height = 5)
gridExtra::grid.arrange(plot1, nrow = 1)
dev.off()
