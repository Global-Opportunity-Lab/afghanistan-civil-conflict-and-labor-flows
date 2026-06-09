source("config.R")

# Packages the pre-computed point-range outputs from 2d_fig4.R into a single
# Rdata file for paper_figures_tables/fig4.R.

plotDTF  <- readRDS(FIG4A_DATA_RDS)
fig4bdata <- readRDS(SOURCE_HL_RDS)
fig4cdata <- readRDS(SOURCE_H_RDS)

save(plotDTF, fig4bdata, fig4cdata, file = "./paper_figures_tables/data/fig4.Rdata")
