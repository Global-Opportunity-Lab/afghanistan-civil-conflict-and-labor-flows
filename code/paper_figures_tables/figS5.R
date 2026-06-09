rm(list = ls()); gc()
library(ggplot2); library(gridExtra)

load("./paper_figures_tables/data/figS5.Rdata")

### Panel row 1: Taliban presence x violence
plot1a <- ggplot(outDTFM4, aes(x = notGovt, fill = as.factor(violence_monthBefore))) +
  geom_bar() +
  labs(fill = "Violence", x = "Taliban presence", y = "Count") +
  viridis::scale_fill_viridis(discrete = TRUE)

plot1b <- ggplot(outDTFM4, aes(x = notGovt, fill = as.factor(violence_monthBefore))) +
  geom_bar(position = "fill") +
  labs(fill = "Violence", x = "Taliban presence", y = "Proportion") +
  viridis::scale_fill_viridis(discrete = TRUE)

### Panel row 2: violence x Taliban presence
plot2a <- ggplot(outDTFM4, aes(x = violence_monthBefore, fill = as.factor(notGovt))) +
  geom_bar() +
  labs(fill = "Taliban presence", x = "Violence", y = "Count") +
  viridis::scale_fill_viridis(discrete = TRUE)

plot2b <- ggplot(outDTFM4, aes(x = violence_monthBefore, fill = as.factor(notGovt))) +
  geom_bar(position = "fill") +
  labs(fill = "Taliban presence", x = "Violence", y = "Proportion") +
  viridis::scale_fill_viridis(discrete = TRUE)

pdf("./paper_figures_tables/output/figS5.pdf", width = 10, height = 8)
gridExtra::grid.arrange(plot1a, plot1b, plot2a, plot2b, nrow = 2)
dev.off()
