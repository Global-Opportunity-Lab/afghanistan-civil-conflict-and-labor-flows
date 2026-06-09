library(ggplot2); library(dplyr); library(gridExtra)
rm(list = ls()); gc()
load("./paper_figures_tables/data/fig2.Rdata")

viridisThreeColor <- c("#fde725", "#21918c", "#440154")

### Figure 2A: daily in-migration event study
pdf("./paper_figures_tables/output/fig2a.pdf", width = 10, height = 5)
print(
  forPlot2a %>%
    ggplot(aes(daysFromPeak, meanEffect, col = poppyCat)) +
    geom_point() +
    geom_pointrange(aes(ymin = conf.low, ymax = conf.high, col = poppyCat),
                    position = position_dodge(width = .5)) +
    labs(x = "Days since district's peak NDVI (16-day MODIS)",
         y = "Daily increase in in-migration rate from baseline",
         col = "Poppy Cultivation\nIntensity") +
    geom_vline(xintercept = 0, color = "red3", linetype = 2) +
    geom_hline(yintercept = 0, color = "red3") +
    scale_x_continuous(breaks = seq(-180, 180, 10)) +
    theme_classic(base_size = 14) +
    scale_color_manual(values = viridisThreeColor, labels = c("None", "Low", "High")) +
    theme(legend.position = c(1, 1.02), legend.justification = c("right", "top"),
          legend.text = element_text(size=14), axis.text=element_text(size=14),
          axis.title=element_text(size=14), axis.text.x = element_text(size = 14)) +
    guides(col = guide_legend(override.aes = list(shape = 15, size = 1.7)))
)
dev.off()

### Figure 2B: daily out-migration event study
pdf("./paper_figures_tables/output/fig2b.pdf", width = 10, height = 5)
print(
  forPlot2b %>%
    ggplot(aes(daysFromPeak, meanEffect, col = poppyCat)) +
    geom_point() +
    geom_pointrange(aes(ymin = conf.low, ymax = conf.high, col = poppyCat),
                    position = position_dodge(width = .5)) +
    labs(x = "Days since district's peak NDVI (16-day MODIS)",
         y = "Daily increase in out-migration rate from baseline",
         col = "Poppy Cultivation\nIntensity") +
    geom_vline(xintercept = 0, color = "red3", linetype = 2) +
    geom_hline(yintercept = 0, color = "red3") +
    scale_x_continuous(breaks = seq(-180, 180, 10)) +
    theme_classic(base_size = 14) +
    scale_color_manual(values = viridisThreeColor, labels = c("None", "Low", "High")) +
    theme(legend.position = c(1, 1.02), legend.justification = c("right", "top"),
          legend.text = element_text(size=14), axis.text=element_text(size=14),
          axis.title=element_text(size=14), axis.text.x = element_text(size = 14)) +
    guides(col = guide_legend(override.aes = list(shape = 15, size = 1.7)))
)
dev.off()

### Figure 2C: baseline vs harvest in-migration rate distributions
outDTFM4 <- forPlot2c
viridisThreeColor <- c("#440154E6", "#21908C80", "#FDE72580")

plot1 <- outDTFM4 %>%
  ggplot(aes(x = baseline, fill = poppyCat)) +
  geom_histogram(position = "identity") +
  scale_fill_manual(values = rev(viridisThreeColor), labels = c("None", "Low", "High")) +
  xlim(c(0, .23)) +
  geom_vline(xintercept = c(median(outDTFM4$baseline[outDTFM4$poppyCat == "N"]),
                            median(outDTFM4$baseline[outDTFM4$poppyCat == "L"]),
                            median(outDTFM4$baseline[outDTFM4$poppyCat == "H"])),
             color = rev(scales::viridis_pal()(3)), lwd = 1.3) +
  geom_vline(xintercept = c(median(outDTFM4$baseline[outDTFM4$poppyCat == "N"]),
                            median(outDTFM4$baseline[outDTFM4$poppyCat == "L"]),
                            median(outDTFM4$baseline[outDTFM4$poppyCat == "H"])),
             color = "black", lty = 3) +
  theme_classic(base_size = 14) +
  labs(x = "Baseline in-migration rate", fill = "Poppy Cultivation\nIntensity", y = "Count") +
  theme(legend.position = c(1, 1.02), legend.justification = c("right", "top"),
        legend.title = element_text(size=14), legend.text = element_text(size=14),
        axis.text=element_text(size=14), axis.title=element_text(size=14),
        axis.text.y = element_text(vjust = .5, hjust = 1)) +
  guides(fill = guide_legend(override.aes = list(alpha = 1)))

plot2 <- outDTFM4 %>%
  ggplot(aes(x = harvest, fill = poppyCat)) +
  geom_histogram(position = "identity") +
  scale_fill_manual(values = rev(viridisThreeColor), labels = c("None", "Low", "High")) +
  labs(x = "In-migration rate during harvest", fill = "Poppy Cultivation\nIntensity", y = "Count") +
  xlim(c(0, .23)) +
  geom_vline(xintercept = c(median(outDTFM4$harvest[outDTFM4$poppyCat == "N"]),
                            median(outDTFM4$harvest[outDTFM4$poppyCat == "L"]),
                            median(outDTFM4$harvest[outDTFM4$poppyCat == "H"])),
             color = rev(scales::viridis_pal()(3)), lwd = 1.3) +
  geom_vline(xintercept = c(median(outDTFM4$harvest[outDTFM4$poppyCat == "N"]),
                            median(outDTFM4$harvest[outDTFM4$poppyCat == "L"]),
                            median(outDTFM4$harvest[outDTFM4$poppyCat == "H"])),
             color = "black", lty = 3) +
  theme_classic(base_size = 14) +
  theme(legend.position = c(1, 1.02), legend.justification = c("right", "top"),
        legend.title = element_text(size=14), legend.text = element_text(size=14),
        axis.text=element_text(size=14), axis.title=element_text(size=14),
        axis.text.y = element_text(vjust = .5, hjust = 1)) +
  guides(fill = guide_legend(override.aes = list(alpha = 1)))

pdf("./paper_figures_tables/output/fig2c.pdf", width = 8, height = 7)
gridExtra::grid.arrange(plot1, plot2, nrow = 2)
dev.off()

### Figure 2D: district-year regression point estimates
plot1 <- plotDTF %>%
  ggplot(aes(label, estimate)) +
  theme_classic() +
  geom_pointrange(aes(ymin = CIlow, ymax = CIhigh)) +
  coord_flip() +
  geom_hline(yintercept = 0, colour = "grey60", linetype = 2) +
  guides(color = guide_legend(override.aes = list(linetype = "blank")), linetype = FALSE) +
  theme(axis.text = element_text(size = 14), axis.title=element_text(size=14)) +
  labs(y = "Increase in in-migration from baseline during harvest", x = "")

pdf("./paper_figures_tables/output/fig2d.pdf", width = 6.5, height = 1.5)
gridExtra::grid.arrange(plot1, nrow = 1)
dev.off()
