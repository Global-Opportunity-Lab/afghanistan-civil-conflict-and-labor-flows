rm(list = ls()); gc()
library(ggplot2); library(dplyr); library(gridExtra)

load("./paper_figures_tables/data/figS10.Rdata")

make_panel <- function(df, year_label) {
  df %>%
    mutate(label = paste0(c(1, 3, 2, 4), label)) %>%
    ggplot(aes(label, estimate)) +
    geom_pointrange(aes(ymin = CIlow, ymax = CIhigh),
                    color = c("#55c667", "#fde725", "#1f968b", "orange")) +
    theme_classic() +
    geom_hline(yintercept = 0, colour = "grey60", linetype = 2) +
    guides(color = guide_legend(override.aes = list(linetype = "blank")),
           linetype = FALSE) +
    theme(plot.title = element_text(size = 13, face = "bold"),
          axis.text = element_text(size=11), axis.title = element_text(size=11)) +
    labs(title = paste("Dropping", year_label),
         y = "Increase in in-migration, by type of source district", x = "") +
    labs(tag = "Taliban = No \n\n\n\n\n\n\n\n\n Taliban = Yes") +
    theme(plot.tag.position = c(-.03, .53),
          text = element_text(size = 10),
          plot.margin = unit(c(0, 0, 0, 3), "cm")) +
    coord_flip(clip = "off", ylim = c(-.012, 0.042)) +
    annotate(x = 2.5, xend = 2.5, y = -.038, yend = .042,
             geom = "segment", colour = "#a8a5a5", size = 1.4, alpha = .4) +
    scale_x_discrete(labels = c("Violence = Yes", "Violence = No",
                                 "Violence = Yes", "Violence = No"))
}

years <- c(2014, 2015, 2016, 2018, 2019, 2020)
plots <- lapply(years, function(y) make_panel(get(paste0("outDTF_", y)), y))

pdf("./paper_figures_tables/output/figS10.pdf", width = 14, height = 16)
gridExtra::grid.arrange(grobs = plots, nrow = 3, ncol = 2)
dev.off()
