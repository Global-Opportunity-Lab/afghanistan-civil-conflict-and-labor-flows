rm(list = ls()); gc()
library(ggplot2); library(dplyr)

## for file ./demo/data/figS6.Rdata:
# outcome1 <- readRDS(INMIG_OUTCOME_RDS)
# covariates <- readRDS(COVARIATES_RDS) %>%
#   dplyr::select(-geometry) # this version should have poppyCat, talibanCurrent and inaccessibleCurrent
#
# newViolence <- readRDS(VIOLENCE_DEST_RDS)
# 
# outDTFM4 <- covariates %>%
#   left_join(outcome1, by = c("distid", "year")) %>%
#   mutate(prov = floor(distid/100)) %>%
#   left_join(newViolence %>%
#               mutate(violence_monthBefore = ifelse(numEvents_monthBeforePeak > 0, 1, 0)) #%>%
#             # dplyr::select(-starts_with("numEvents"))
#             ,
#             by = c("distid", "year")) %>%
#   filter(!is.na(maxIn)) # %>%
# outDTFM4 <- outDTFM4 %>%
#   select(tmpPoppy, maxIn, violence_monthBefore, notGovt)
# save(outDTFM4, file = "./paper_figures_tables/data/figS6.Rdata")

load("./paper_figures_tables/data/figS6.Rdata")

pdf("./paper_figures_tables/output/figS6.pdf", width = 8, height = 6)

print(
  outDTFM4 %>%
    # filter(tmpPoppy < 5000) %>%
    ggplot(aes(tmpPoppy, maxIn)) +
    geom_point() +
    geom_smooth(method = loess) +
    labs(
      x = "Number of hectares of opium poppy cultivation",
      y = "Difference between harvest and \nbaseline in-migration rates"
    ) +
    theme(axis.text = element_text(size=14), axis.title = element_text(size=14))
)

print(
  outDTFM4 %>%
    # filter(tmpPoppy < 5000) %>%
    ggplot(aes(tmpPoppy, violence_monthBefore)) +
    geom_point() +
    geom_smooth(method = loess) +
    labs(
      x = "Number of hectares of opium poppy cultivation",
      y = "Violent events in the month before peak NDVI"
    ) +
    theme(axis.text = element_text(size=14), axis.title = element_text(size=14))
)

print(
  outDTFM4 %>%
    mutate(taliban = notGovt) %>%
    # mutate(taliban = ifelse(scale4 == TRUE | scale5 == TRUE, 1, 0)) %>%
    # filter(tmpPoppy < 5000) %>%
    ggplot(aes(tmpPoppy, taliban)) +
    geom_point() +
    geom_smooth(method = loess) +
    labs(
      x = "Number of hectares of opium poppy cultivation",
      y = "Taliban presence"
    ) +
    theme(axis.text = element_text(size=14), axis.title = element_text(size=14))
)

dev.off()
