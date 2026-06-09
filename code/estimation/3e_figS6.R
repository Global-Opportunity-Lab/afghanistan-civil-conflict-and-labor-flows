# 3e_figS6.R
# Figure S6: main results stratified by year, replicating the Figure 3 scatter
# separately for each harvest year to assess temporal stability.
# Inputs:  INMIG_OUTCOME_RDS, COVARIATES_RDS, VIOLENCE_DEST_RDS
# Outputs: 1-10-24figA2.pdf (in OUT_GENERAL)

rm(list = ls()); gc()
source("config.R")
outcome1 <- readRDS(INMIG_OUTCOME_RDS)
covariates <- readRDS(COVARIATES_RDS) %>%
  dplyr::select(-geometry) # this version should have poppyCat, talibanCurrent and inaccessibleCurrent

newViolence <- readRDS(VIOLENCE_DEST_RDS)

outDTFM4 <- covariates %>%
  left_join(outcome1, by = c("distid", "year")) %>%
  mutate(prov = floor(distid/100)) %>%
  left_join(newViolence %>%
              mutate(violence_monthBefore = ifelse(numEvents_monthBeforePeak > 0, 1, 0)) #%>%
            # dplyr::select(-starts_with("numEvents"))
            ,
            by = c("distid", "year")) %>%
  filter(!is.na(maxIn)) # %>%

####### FIG S5: loess curves EDA 
pdf(file.path(OUT_GENERAL, "1-10-24figA2.pdf"), width = 7, height = 5)

outDTFM4 %>%
  # filter(tmpPoppy < 5000) %>%
  ggplot(aes(tmpPoppy, violence_monthBefore)) +
  geom_point() +
  geom_smooth(method = loess) +
  labs(
    x = "Number of hectares of opium poppy cultivation",
    y = "Violent events in the month before peak NDVI"
  ) +
  theme(#plot.title = element_text(size = 15, face = "bold"),
    axis.text = element_text(size=14),
    axis.title = element_text(size=14),
  )

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
  )+
  theme(#plot.title = element_text(size = 15, face = "bold"),
    axis.text = element_text(size=14),
    axis.title = element_text(size=14),
  )


outDTFM4 %>%
  # filter(tmpPoppy < 5000) %>%
  ggplot(aes(tmpPoppy, maxIn)) +
  geom_point() +
  geom_smooth(method = loess) +
  labs(
    x = "Number of hectares of opium poppy cultivation",
    y = "Difference between harvest and \nbaseline in-migration rates"
  )+
  theme(#plot.title = element_text(size = 15, face = "bold"),
    axis.text = element_text(size=14),
    axis.title = element_text(size=14),
  )

dev.off()
