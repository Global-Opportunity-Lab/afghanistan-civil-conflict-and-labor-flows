library(ggplot2); library(dplyr); library(gridExtra); library(tidyr)
rm(list = ls()); gc()
load("./paper_figures_tables/data/fig4.Rdata")

plotDTF$label <- c("2_Violence Y, Taliban Y",
                   "4_Violence Y, Taliban N",
                   "3_Violence N, Taliban Y",
                   "5_Violence N, Taliban N",
                   "1_Low")

myColors <- c("lightgray", "azure4", "#55c667", "#1f968b", "#fde725", "orange")

### Figure 4A: migrant composition bar chart (baseline vs harvest)
plot1 <- rbind(plotDTF, data.frame(model = "High-growing",
                                   label = "0_No growing",
                                   baselineMean = 1 - sum(plotDTF$baselineMean),
                                   baselineMedian = 1 - sum(plotDTF$baselineMedian),
                                   harvestMean = 1 - sum(plotDTF$harvestMean),
                                   harvestMedian = 1 - sum(plotDTF$harvestMedian))) %>%
  select(-baselineMean, -harvestMean) %>%
  tidyr::pivot_longer(cols = c("baselineMedian", "harvestMedian")) %>%
  mutate(name = ifelse(name == "baselineMedian", "baseline", ".harvest")) %>%
  ggplot(aes(x = as.factor(name), y = value, fill = label)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values = myColors,
                    labels = c("No poppy", "Low-growing",
                               "Taliban = Yes\nViolence = Yes", "Taliban = Yes\nViolence = No",
                               "Taliban = No\nViolence = Yes", "Taliban = No\nViolence = No"),
                    guide = guide_legend(reverse = TRUE)) +
  coord_flip() + theme_void() +
  labs(fill = "Source of in-migrants\n(district type)", y = "", x = "") +
  theme(plot.title = element_text(size = 15, face = "bold"),
        axis.text = element_text(size=14), axis.title = element_text(size=14),
        legend.position = "bottom", legend.text = element_text(size=10),
        legend.title = element_text(size=10, face = "bold")) +
  scale_x_discrete(labels = c("Harvest", "Baseline")) +
  scale_y_continuous(labels = scales::label_percent())

pdf("./paper_figures_tables/output/fig4a.pdf", width = 8, height = 4)
gridExtra::grid.arrange(plot1, nrow = 1)
dev.off()

### Figure 4B: in-migration by source district type (high vs low cultivation)
plot1 <- fig4bdata %>%
  ggplot(aes(label, estimate)) +
  geom_pointrange(aes(ymin = CIlow, ymax = CIhigh)) +
  theme_classic() +
  geom_hline(yintercept = 0, colour = "grey60", linetype = 2) +
  guides(color = guide_legend(override.aes = list(linetype = "blank")), linetype = FALSE) +
  theme(plot.title = element_text(size = 15, face = "bold"),
        axis.text = element_text(size=14), axis.title = element_text(size=14)) +
  labs(y = "Increase in in-migration, by type of source district", x = "") +
  coord_flip() +
  scale_x_discrete(labels = c("High-cultivation\nsources", "Low-cultivation\nsources")) +
  theme(axis.text.y = element_text(hjust=0.5))

pdf("./paper_figures_tables/output/fig4b.pdf", width = 7, height = 2)
gridExtra::grid.arrange(plot1, nrow = 1)
dev.off()

### Figure 4C: in-migration by source district type (violence x Taliban, 4 groups)
plot1 <- fig4cdata %>%
  mutate(label = paste0(c(1, 3, 2, 4), label)) %>%
  ggplot(aes(label, estimate)) +
  geom_pointrange(aes(ymin = CIlow, ymax = CIhigh),
                  color = c("#55c667", "#fde725", "#1f968b", "orange")) +
  theme_classic() +
  geom_hline(yintercept = 0, colour = "grey60", linetype = 2) +
  guides(color = guide_legend(override.aes = list(linetype = "blank")), linetype = FALSE) +
  theme(plot.title = element_text(size = 15, face = "bold"),
        axis.text = element_text(size=14), axis.title = element_text(size=14)) +
  labs(y = "Increase in in-migration, by type of source district", x = "") +
  labs(tag = "Taliban = No \n\n\n\n\n\n Taliban = Yes") +
  theme(plot.tag.position = c(-.07, .58), text = element_text(size = 12)) +
  coord_flip(clip = "off", ylim = c(-.005, 0.042)) +
  annotate(x = 2.5, xend = 2.5, y = -.025, yend = .042,
           geom = "segment", colour = "#a8a5a5", size = 1.4, alpha = .4) +
  scale_x_discrete(labels = c("Violence = Yes", "Violence = No", "Violence = Yes", "Violence = No"))

pdf("./paper_figures_tables/output/fig4c.pdf", width = 7, height = 3.5)
gridExtra::grid.arrange(plot1, nrow = 1)
dev.off()
