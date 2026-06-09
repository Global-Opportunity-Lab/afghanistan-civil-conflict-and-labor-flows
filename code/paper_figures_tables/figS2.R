rm(list = ls()); gc()
library(sf); library(dplyr); library(ggplot2); library(scales)
# for file ./demo/data/figS2.RData:
# from code 3b_figS2.R
# save(plotDTF, afghanShape, file = "./paper_figures_tables/data/figS2.Rdata")

load("./paper_figures_tables/data/figS2.Rdata")

pdf("./paper_figures_tables/output/figS2.pdf", width = 10, height = 8)

print(
  afghanShape %>%
    ggplot() +
    geom_sf()
)

print(
  plotDTF %>%
    mutate(distid = ifelse(distid == 1115, 0, distid)) %>% # hack so that 1115 appears below
    mutate(val = ifelse(is.na(year), 0, 1),
           distid = as.factor(distid)) %>%
    ggplot(aes(date, distid, fill = as.factor(val))) +
    geom_tile() +
    scale_x_date(labels=scales::date_format(format = "%m/%Y"), breaks = scales::date_breaks(width = "2 months"), expand = c(.02, .02)) +
    theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
          panel.background = element_blank(), axis.line = element_line(colour = "black")) +
    theme(axis.text.x = element_text(angle = 90, size = 8),
          legend.position = "none") +
    scale_fill_manual(values = c("white", "black")) +
    geom_vline(xintercept = seq(as.Date("2015-01-01"), as.Date("2020-01-01"), "1 year")) +
    labs(x = "", y = "") +
    scale_y_discrete(labels = c("2416" = "Zhari",
                                "2407" = "Maywand",
                                "2307" = "Washer",
                                "2302" = "Nahri Sarraj",
                                "2301" = "Lashkar Gah",
                                "2205" = "Khash Rod",
                                "1906" = "Bala Murghab",
                                "807" = "Pachier Agam",
                                "805" = "Khogayani",
                                "0" = "Argo" # hack: this is 1115
    ))
)

dev.off()



