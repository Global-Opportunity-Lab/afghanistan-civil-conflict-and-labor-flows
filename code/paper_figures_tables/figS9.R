rm(list = ls()); gc()
library(dplyr); library(ggplot2); library(gridExtra)

load("./paper_figures_tables/data/figS9.Rdata")

make_panel <- function(df) {
  df %>%
    mutate(label = paste0(4:1, label)) %>%
    ggplot(aes(label, estimate)) +
    geom_pointrange(aes(ymin = CIlow, ymax = CIhigh),
                    color = c("orange", "#fde725", "#1f968b", "#55c667")) +
    theme_classic() +
    geom_hline(yintercept = 0, colour = "grey60", linetype = 2) +
    guides(color = guide_legend(override.aes = list(linetype = "blank")),
           linetype = FALSE) +
    theme(plot.title = element_text(size = 15, face = "bold"),
          axis.text = element_text(size=14), axis.title = element_text(size=14)) +
    labs(y = "Increase in in-migration from baseline during harvest", x = "") +
    labs(tag = "Taliban = No \n\n\n\n\n Taliban = Yes") +
    theme(plot.tag.position = c(-.07, .57),
          text = element_text(size = 12),
          plot.margin = unit(c(0, 0, 0, 3), "cm")) +
    coord_flip(clip = "off", ylim = c(-.02, 0.1)) +
    annotate(x = 2.5, xend = 2.5, y = -.063, yend = .1,
             geom = "segment", colour = "#a8a5a5", size = 1.4, alpha = .4) +
    scale_x_discrete(labels = c("Violence = Yes", "Violence = No",
                                 "Violence = Yes", "Violence = No"))
}

plot1 <- make_panel(outDTFv1)
plot2 <- make_panel(outDTFv2)
plot3 <- make_panel(outDTFv3)

pdf("./paper_figures_tables/output/figS9.pdf", width = 8, height = 14)
gridExtra::grid.arrange(plot1, plot2, plot3, nrow = 3)
dev.off()
