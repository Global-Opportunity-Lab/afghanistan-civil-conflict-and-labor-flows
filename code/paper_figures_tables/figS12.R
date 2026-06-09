rm(list = ls()); gc()
library(dplyr); library(ggplot2)

# for file ./demo/data/figS12.Rdata
# see code 5a_figS12.R
# save outDTF_joint as figS12.Rdata

load("./paper_figures_tables/data/figS12.Rdata")

pdf("./paper_figures_tables/output/figS12.pdf", width = 8, height = 6)

plot5 <- outDTF_joint %>%
  mutate(label = paste0(8:1, label)) %>%
  ggplot(aes(label, estimate))+
  geom_pointrange(aes(ymin = CIlow, ymax = CIhigh),
                  color = c("orange", "#fde725", "#1f968b", "#55c667", "orange", "#fde725", "#1f968b", "#55c667")
  ) + # fatten changes the circles only; size changes bars and legend circles
  theme_classic() + 
  geom_hline(yintercept = 0, colour = "grey60", linetype = 2) + 
  guides(color = guide_legend(override.aes = list(linetype = "blank")), 
         linetype = FALSE # suppress line for first plot; only do color
  ) +  # shape for the type of dot
  theme(plot.title = element_text(size = 15, face = "bold"),
        axis.text = element_text(size=14),
        axis.title = element_text(size=14),
  ) +
  labs(#title = paste0("Effect of violence on destination of movers: non-capitals"),
    # title = "Violence definition: any violent event", 
    y = "Increase in in-migration\nfrom baseline during harvest",
    x = ""
  ) +
  labs(tag = "Taliban = No \n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n Taliban = Yes") +
  # labs(tag = "Violence = Yes \n\n\n\n\n Violence = No") +
  theme(plot.tag.position = c(-.07, .57),
        text = element_text(size = 12),
        plot.margin = unit(c(0, 0, 0, 3), "cm")
  ) +
  coord_flip(clip = "off"
             , ylim = c(-.05, 0.1)
             # , ylim = c(-.03, 0.09) # for low-growing
  ) +
  annotate(x = 4.5, xend = 4.5, y = -.063, yend = .1,
           geom = "segment",
           colour = "#a8a5a5", size = 1.4, alpha = .4) +
  # geom_vline(xintercept = 2.5, colour = "grey60", linetype = 2) +
  scale_x_discrete(labels = c("V = Yes, RV = Yes", "V = Yes, RV = No","V = No, RV = Yes", "V = No, RV = No",
                              "V = Yes, RV = Yes", "V = Yes, RV = No","V = No, RV = Yes", "V = No, RV = No")) # bottom to top 

gridExtra::grid.arrange(plot5, nrow = 1)

dev.off()

knitr::kable(outDTF_joint %>%
               select(label, estimate, variance, p, n) %>%
               mutate(SD = as.numeric(sqrt(variance)),
                      p = as.numeric(p)) %>%
               rename(Coefficient = label,
                      Estimate = estimate) %>%
               select(Coefficient, Estimate, SD, p, n),
             format = "latex",
             booktabs = TRUE,  # nicer lines
             digits = c(NA, 4, 4, 3, 1))

