library(ggplot2); library(dplyr); library(gridExtra)
rm(list = ls()); gc()
load("./paper_figures_tables/data/fig3.Rdata")

### Figure 3A: in-migration density by violence x Taliban category
pdf("./paper_figures_tables/output/fig3a.pdf", width = 8, height = 4)
print(
  outDTFM4 %>%
    ggplot(aes(x = maxIn, fill = as.factor(cat))) +
    geom_density() +
    labs(fill = "Destination district",
         x = "Difference between harvest and baseline in-migration rates",
         y = "Density") +
    theme_classic(base_size = 14) +
    scale_fill_manual(values = c("#FFA50080", "#fde72580", "#1f968b80", "#55c66780")) +
    theme(legend.position = c(1, .6), legend.justification = c("right", "bottom"),
          legend.title = element_text(size=14), legend.text = element_text(size=14),
          plot.title = element_text(hjust = 0.5, face = 2),
          axis.text=element_text(size=14), axis.title = element_text(size=14))
)
dev.off()

### Figure 3B: violence x Taliban interaction regression estimates
plot1 <- outDTF %>%
  mutate(label = paste0(4:1, label)) %>%
  ggplot(aes(label, estimate)) +
  geom_pointrange(aes(ymin = CIlow, ymax = CIhigh),
                  color = c("orange", "#fde725", "#1f968b", "#55c667")) +
  theme_classic() +
  geom_hline(yintercept = 0, colour = "grey60", linetype = 2) +
  guides(color = guide_legend(override.aes = list(linetype = "blank")), linetype = FALSE) +
  theme(plot.title = element_text(size = 15, face = "bold"),
        axis.text = element_text(size=14), axis.title = element_text(size=14)) +
  labs(y = "Increase in in-migration from baseline during harvest", x = "") +
  labs(tag = "Taliban = No \n\n\n\n\n Taliban = Yes") +
  theme(plot.tag.position = c(-.07, .57), text = element_text(size = 12)) +
  coord_flip(clip = "off", ylim = c(-.01, 0.075)) +
  annotate(x = 2.5, xend = 2.5, y = -.063, yend = .075,
           geom = "segment", colour = "#a8a5a5", size = 1.4, alpha = .4) +
  scale_x_discrete(labels = c("Violence = Yes", "Violence = No", "Violence = Yes", "Violence = No"))

pdf("./paper_figures_tables/output/fig3b.pdf", width = 8, height = 3)
gridExtra::grid.arrange(plot1, nrow = 1)
dev.off()
