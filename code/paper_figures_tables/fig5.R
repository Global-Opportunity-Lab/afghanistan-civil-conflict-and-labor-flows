library(ggplot2); library(dplyr); library(gridExtra)
rm(list = ls()); gc()
load("./paper_figures_tables/data/fig5.Rdata")

### Figure 5A: eradication interaction regression estimates
plot1 <- outDTF %>%
  mutate(label = paste0(3:1, ": ", label)) %>%
  ggplot(aes(x = label, y = estimate)) +
  geom_pointrange(aes(ymin = CIlow, ymax = CIhigh)) +
  theme_classic() +
  geom_hline(yintercept = 0, colour = "grey60", linetype = 2) +
  guides(color = guide_legend(override.aes = list(linetype = "blank")), linetype = "none") +
  theme(plot.title = element_text(size = 15, face = "bold"),
        axis.text = element_text(size=14), axis.title = element_text(size=14)) +
  labs(y = "Increase in in-migration from baseline during harvest", x = "") +
  coord_flip(clip = "off", ylim = c(-.13, 0.05)) +
  scale_x_discrete(labels = c("High*Eradication Percent", "Eradication Percent", "High-cultivation"))

pdf("./paper_figures_tables/output/fig5a.pdf", width = 8, height = 2.8)
gridExtra::grid.arrange(plot1, nrow = 1)
dev.off()

### Figure 5B: eradication distribution by Taliban control
pdf("./paper_figures_tables/output/fig5b.pdf", width = 8, height = 4.5)
print(
  fig5bdata %>%
    ggplot(aes(x = eradPercent, fill = as.factor(notGovt))) +
    geom_histogram(alpha = .8, position = "identity", bins = 50) +
    theme_classic(base_size = 14) +
    scale_fill_manual(values = c("#FFBF00", "#40B5AD")) +
    theme(legend.position = c(1, 1.02), legend.justification = c("right", "top"),
          plot.title = element_text(size = 15, face = "bold"),
          axis.text = element_text(size=14), axis.title = element_text(size=14)) +
    labs(fill = "Taliban", x = "Eradication Percentage", y = "Count",
         title = "High-cultivation districts with eradication")
)
dev.off()
