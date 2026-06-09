rm(list = ls()); gc()
library(ggplot2); library(dplyr)

# for file "./paper_figures_tables/data/figS13.Rdata"
# see code 6a_figS13.R
# then select the relevant columns as follows

# out <- out %>%
#   select(district_id, origin_district, diff)
# destinationLabels <- destinationLabels %>%
#   select(breaks, finalLabel)
# sourceLabels <- sourceLabels %>%
#   select(breaks, finalLabel)
# save(out, destinationLabels, sourceLabels, file = "./paper_figures_tables/data/figS13.Rdata")

load("./paper_figures_tables/data/figS13.Rdata")

pdf("./paper_figures_tables/output/figS13.pdf", width = 12, height = 10)

out %>%
  mutate(diff = ifelse(diff > .025, .025, diff)) %>%
  mutate(diff = ifelse(diff < -.025, -.025, diff)) %>%
  ggplot(aes(x = district_id, y = origin_district, fill = diff)) + 
  geom_tile() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        panel.background = element_blank(), axis.line = element_line(colour = "black")) +
  theme(axis.text.x = element_text(angle = 90, size = 8)) + #,
  colorspace::scale_fill_continuous_diverging(palette = "Blue-Red",
                                              alpha = 1,
                                              name = "Harvest-baseline",
                                              # limits = c(-.05, .05),
                                              mid = 0,
                                              rev = TRUE,
                                              na.value = "transparent") +
  labs(x = "Destination", y = "Source") +
  scale_y_discrete(breaks = sourceLabels$breaks[!is.na(sourceLabels$finalLabel)], 
                   labels = sourceLabels$finalLabel[!is.na(sourceLabels$finalLabel)]) +
  scale_x_discrete(breaks = destinationLabels$breaks[!is.na(destinationLabels$finalLabel)], 
                   labels = destinationLabels$finalLabel[!is.na(destinationLabels$finalLabel)]) +
  theme(axis.text.x = element_text(hjust = 1,
                                   lineheight = 0.5,
                                   vjust = .5)) +
  theme(axis.text.y = element_text(size = 8,
                                   lineheight = 4,
                                   vjust = -.05))

dev.off()
