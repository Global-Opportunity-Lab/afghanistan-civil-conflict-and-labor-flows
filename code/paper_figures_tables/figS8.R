rm(list = ls()); gc()
library(ggplot2); library(dplyr); library(gridExtra); library(knitr)

load("./paper_figures_tables/data/figS8.Rdata")

make_panel <- function(df, title, ylim_vals, annot_y) {
  df %>%
    mutate(label = paste0(4:1, label)) %>%
    ggplot(aes(label, estimate)) +
    geom_pointrange(aes(ymin = CIlow, ymax = CIhigh),
                    color = c("orange", "#fde725", "#1f968b", "#55c667")) +
    theme_classic() +
    geom_hline(yintercept = 0, colour = "grey60", linetype = 2) +
    guides(color = guide_legend(override.aes = list(linetype = "blank")),
           linetype = FALSE) +
    theme(plot.title = element_text(size = 13, face = "bold"),
          axis.text = element_text(size = 11), axis.title = element_text(size = 11)) +
    labs(title = title,
         y = "Increase in in-migration from baseline during harvest", x = "") +
    labs(tag = "Taliban = No \n\n\n\n\n\n\n\n\n Taliban = Yes") +
    theme(plot.tag.position = c(-.025, .53),
          text = element_text(size = 10),
          plot.margin = unit(c(0, 0, 0, 3), "cm")) +
    coord_flip(clip = "off", ylim = ylim_vals) +
    annotate(x = 2.5, xend = 2.5, y = annot_y[1], yend = annot_y[2],
             geom = "segment", colour = "#a8a5a5", size = 1.4, alpha = .4) +
    scale_x_discrete(labels = c("Violence = Yes", "Violence = No",
                                 "Violence = Yes", "Violence = No"))
}

# Leave-one-year-out panels (rows 1–3)
p_2014 <- make_panel(outDTF_2014, "Removing year 2014", c(-.015, 0.08), c(-.06, .08))
p_2015 <- make_panel(outDTF_2015, "Removing year 2015", c(-.015, 0.08), c(-.06, .08))
p_2016 <- make_panel(outDTF_2016, "Removing year 2016", c(-.015, 0.08), c(-.06, .08))
p_2018 <- make_panel(outDTF_2018, "Removing year 2018", c(-.015, 0.08), c(-.06, .08))
p_2019 <- make_panel(outDTF_2019, "Removing year 2019", c(-.015, 0.08), c(-.06, .08))
p_2020 <- make_panel(outDTF_2020, "Removing year 2020", c(-.015, 0.08), c(-.06, .08))

# Pre/Post-2017 panels (row 4)
p_pre  <- make_panel(outDTFpre,  "Pre-2017",  c(-.015, 0.06), c(-.05, .06))
p_post <- make_panel(outDTFpost, "Post-2017", c(-.015, 0.16), c(-.1,  .16))

pdf("./paper_figures_tables/output/figS8.pdf", width = 14, height = 16)
gridExtra::grid.arrange(p_2014, p_2015,
                        p_2016, p_2018,
                        p_2019, p_2020,
                        p_pre,  p_post,
                        nrow = 4, ncol = 2)
dev.off()

# LaTeX summary table (printed to stdout)
knitr::kable(outDTFpre %>%
               select(label, estimate, variance, p, n) %>%
               mutate(SD = as.numeric(sqrt(variance)), p = as.numeric(p)) %>%
               rename(Coefficient = label, Estimate = estimate) %>%
               select(Coefficient, Estimate, SD, p, n),
             format = "latex", booktabs = TRUE,
             digits = c(NA, 4, 4, 3, 1))
