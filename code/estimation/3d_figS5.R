######################## other two-way EDA ########################
# updated 9/27/23
rm(list = ls()); gc()
library(dplyr)
source("config.R")
outcome1 <- readRDS(INMIG_OUTCOME_RDS)
covariates <- readRDS(COVARIATES_RDS) %>%
  dplyr::select(-geometry)# this version should have poppyCat, talibanCurrent and inaccessibleCurrent

newViolence <- readRDS(VIOLENCE_DEST_RDS)

outDTFM4 <- covariates %>%
  left_join(outcome1, by = c("distid", "year")) %>%
  mutate(prov = floor(distid/100)) %>%
  left_join(newViolence %>%
              mutate(violence_monthBefore = ifelse(numEvents_monthBeforePeak > 0, 1, 0)) #%>%
            ,
            by = c("distid", "year")) %>%
  filter(!is.na(maxIn))

# pdf(paste0("/home/xtai/climate/output/5-6-23twoWayEDA.pdf"), width = 10, height = 4)
pdf(file.path(OUT_GENERAL, "9-26-23twoWayEDA.pdf"), width = 10, height = 4)
plot1 <- ggplot(outDTFM4, aes(x = notGovt, fill = as.factor(violence_monthBefore))) +
  geom_bar() +
  labs(fill = "Violence",
       x = "Taliban presence",
       y = "Count") +
  viridis::scale_fill_viridis(discrete = TRUE)

plot2 <- ggplot(outDTFM4, aes(x = notGovt, fill = as.factor(violence_monthBefore))) +
  geom_bar(position = "fill") +
  labs(fill = "Violence",
       x = "Taliban presence",
       y = "Proportion") +
  viridis::scale_fill_viridis(discrete = TRUE)

gridExtra::grid.arrange(plot1, plot2, nrow = 1, top = "Districts with Taliban presence are more likely to have violence")

plot1 <- ggplot(outDTFM4, aes(x = violence_monthBefore, fill = as.factor(notGovt))) +
  geom_bar() +
  labs(fill = "Taliban presence",
       x = "Violence",
       y = "Count") +
  viridis::scale_fill_viridis(discrete = TRUE)

plot2 <- ggplot(outDTFM4, aes(x = violence_monthBefore, fill = as.factor(notGovt))) +
  geom_bar(position = "fill") +
  labs(fill = "Taliban presence",
       x = "Violence",
       y = "Proportion") +
  viridis::scale_fill_viridis(discrete = TRUE)

gridExtra::grid.arrange(plot1, plot2, nrow = 1, top = "Districts with violence are more likely to have Taliban presence")

dev.off()

