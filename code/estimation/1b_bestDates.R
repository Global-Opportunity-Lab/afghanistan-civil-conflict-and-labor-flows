rm(list = ls()); gc()
library(dplyr)
source("config.R")
#### STEP 1: --- DONE
# 1. for each data set in here: /data/afg_satellite/bestdates/pixel_maxdata_real/
      # these are MODIS coords of 250m pixels
      # agrYN: masks according to copernicus
# 2. filter (set NA for invalid values) by corresponding Agr_XXXX column in /data/afg_satellite/bestdates/AgrYN/ 
      # this file: if there are agricultural pixels in the year, they are marked with 1 in the corresponding column, otherwise they are missing. If none of the pixels in that csv file are agricultural in any of the years, you would just see the lat long columns with no Agr columns
      # code below checks for 1s in Agr data, if not sets pixel_maxdata to NA
# (check that corresponding files have the same number of rows)
# 3. then cat all the files 

# fileList <- system("ls /data/afg_satellite/bestdates/pixel_maxdata_real/", intern = TRUE)
fileList <- system(paste0("ls ", PIXEL_MAXDATA_DIR, "/"), intern = TRUE) 
outFile <- c()

for (i in 1:length(fileList)) {
  if (i %% 50 == 0) cat(i, ", ") # ~1100 total
  bestDates <- read.csv(file.path(PIXEL_MAXDATA_DIR, fileList[i]))
  agrYN <- read.csv(file.path(AGR_YN_DIR, fileList[i]))
  
  if ((identical(bestDates$Latitude, agrYN$Latitude) + identical(bestDates$Longitude, agrYN$Longitude) != 2) )
    warning(paste0(fileList[i], ": different lat-longs.\n"))
  
  if (length(colnames(agrYN)) == 2) next # here no agricultural pixels
  
  numNA <- apply(agrYN, 1, FUN = function(x) sum(is.na(x)))
  toKeep <- numNA != (ncol(agrYN) - 2)
  
  bestDates <- bestDates[toKeep, ] %>% # first remove rows where pixel is not agricultural in any year
    select(Latitude, Longitude, starts_with("Best.Start"))
    # select(Latitude, Longitude, starts_with("Peak.NDVI")) # same code works, just replace Best.Start with Peak.NDVI ##### this version for NDVI values 
  agrYN <- agrYN[toKeep, ]
  
  # make NA depending on years 
  if (ncol(agrYN) != 9) {
    fixAgrYN <- data.frame(Latitude = agrYN$Latitude, Longitude = agrYN$Longitude,
                           Agr_2014 = NA, Agr_2015 = NA, Agr_2016 = NA,
                           Agr_2017 = NA, Agr_2018 = NA, Agr_2019 = NA,
                           Agr_2020 = NA)
    tmpColNames <- colnames(agrYN)
    for (year in 2014:2020) {
      if (paste0("Agr_", year) %in% tmpColNames) {
        fixAgrYN[paste0("Agr_", year)] <- agrYN[paste0("Agr_", year)]
      } 
    }
    agrYN <- fixAgrYN
  }
  for (tmpCol in 3:9) { # roundabout way because of dataframe structure
    tmpNAs <- which(is.na(agrYN[, tmpCol]))
    bestDates[tmpNAs, tmpCol] <- NA
  }
  # tmp <- bestDates[, 3:9] 
  # bestDates[, 3:9] <- tmp[as.matrix(agrYN[, 3:9])]
  
  outFile <- outFile %>%
    bind_rows(bestDates)
}

# outFile has 799519 rows --- original around 11 million, i.e., around 7.2% agriculture 

#### STEP 2:  
# match coordinates to district

afghanShape <- sf::st_read(DISTRICT_SHP, quiet = TRUE) %>%
  sf::st_transform(crs = 32642)

sites <- sf::st_as_sf(outFile, coords = c("Longitude", "Latitude"), 
                      crs = 4326) %>% 
  sf::st_transform(crs = 32642)

districts <- sf::st_intersects(afghanShape, sites, sparse = FALSE) # this is 398 by numEvents --- each event is on a column
districtYN <- apply(districts, MARGIN = 2, FUN = function(x) sum(x == TRUE)) # this will only work with points

whichDistricts <- apply(districts, MARGIN = 2, FUN = function(x) which(x == TRUE)) # this will only work with points
whichDistricts[which(districtYN == 0)] <- NA # this one is empty for some reason
distIDs <- afghanShape$DISTID[unlist(whichDistricts)]

outFile$distIDs <- distIDs
outFile <- outFile[!is.na(outFile$distIDs), ]

saveRDS(outFile, file = AGR_BEST_DATES_RDS)
# saveRDS(outFile, file = AGR_BEST_DATES_NDVI_RDS) # second version has peak NDVI values (max) and first version has date with peak NDVI (arg max)

########
# 1. because agricultural mask is not very accurate 
#     also these might be agriculture at any point in the year?), use only pixels that have NDVI > .3 at peak (first half)
# 2. get mode, second and third
# 3. in addition to the date, get also the proportion

# check:
# sum(!is.na(bestDatesFile$Best.Start.Date.2014)) # 658392
# sum(outFile$Peak.NDVI.2014 <= .3, na.rm = TRUE) # 240802
bestDatesFile <- readRDS(AGR_BEST_DATES_RDS)
outFile <- readRDS(AGR_BEST_DATES_NDVI_RDS)
for (tmpCol in 3:9) { # roundabout way because of dataframe structure
  tmpNAs <- which(outFile[, tmpCol] <= .3) # HERE is the NDVI filter
  bestDatesFile[tmpNAs, tmpCol] <- NA
}

#### STEP 3:  
# then find mode and second-highest occurring in each district-year
# + do maps

modeFun <- function(x){
  # x <- x[as.numeric(substr(x, 6, 7)) <= 6] # this line for 4/6/22 version
  if (length(x) == 0) return(NA) else {
    tmp <- table(x)
    # ret <- list(maxDate = names(which.max(tmp)), prop = max(tmp)/sum(tmp))
    # return(ret)
    return(tibble(maxDate = names(which.max(tmp)), totalPixels = sum(tmp), modePixels = max(tmp)))
  }
}
secondMostFun <- function(x){
  theMode <- modeFun(x)$maxDate
  xNew <- x[x != theMode]
  tmp <- modeFun(xNew)
  if (is.na(tmp)) return(NA) else {
    return(tmp)
  }
}
thirdMostFun <- function(x){
  theMode <- modeFun(x)$maxDate
  xNew <- x[x != theMode]
  secondMode <- modeFun(xNew)
  if (is.na(secondMode)) return(NA) else {
    xNew <- xNew[xNew != secondMode$maxDate]
    tmp <- modeFun(xNew)
    if (is.na(tmp)) return(NA) else return(tmp)
  }
}

myModes <- bestDatesFile %>%
  group_by(distIDs) %>%
  summarise_if(is.character, modeFun)

secondMost <- bestDatesFile %>%
  group_by(distIDs) %>%
  summarise_if(is.character, secondMostFun)

thirdMost <- bestDatesFile %>%
  group_by(distIDs) %>%
  summarise_if(is.character, thirdMostFun)

#### desired output:
# long data set: distIDs, year, date, prop1 (for mode), prop2 (for second-most)

bestDates <- data.frame(distIDs = myModes$distIDs, myModes$Best.Start.Date.2014, secondDate = secondMost$Best.Start.Date.2014$maxDate, secondPixels = secondMost$Best.Start.Date.2014$modePixels) %>%
  mutate(prop1 = modePixels/totalPixels,
         prop2 = secondPixels/totalPixels,
         year = 2014)

for (y in 2015:2020) {
  tmpDates <- data.frame(distIDs = myModes$distIDs, 
                         myModes[[paste0("Best.Start.Date.", y)]], 
                         secondDate = secondMost[[paste0("Best.Start.Date.", y)]]$maxDate, 
                         secondPixels = secondMost[[paste0("Best.Start.Date.", y)]]$modePixels) %>%
    mutate(prop1 = modePixels/totalPixels,
           prop2 = secondPixels/totalPixels,
           year = y)
  bestDates <- bestDates %>%
    bind_rows(tmpDates)
}

saveRDS(bestDates, file = BEST_DATES_SAT)

bestDatesLong <- readRDS(BEST_DATES_SAT)
write.csv(bestDatesLong %>%
            select(distIDs, year, maxDate) %>%
            rename(distID = distIDs,
                   date = maxDate),
          BEST_DATES_SAT_CSV,
          row.names = FALSE)

# check if they are unimodal or bimodal
bestDates %>% ggplot(aes(x = prop1, y = prop2, col = as.factor(year))) +
  geom_point() 

################ 7/12/22
# count number of agricultural pixels (NDVI > .3 in first half)
rm(list = ls()); gc()
library(dplyr)
source("config.R")
outFile <- readRDS(AGR_BEST_DATES_NDVI_RDS)

# just need this 
tryThis <- outFile %>%
  group_by(distIDs) %>%
  summarize_at(vars(starts_with("Peak.NDVI")), funs(numHectares = sum(!is.na(.) & . > .3)*.25*.25*100))
# .25*.25*100 does the conversion into hectares

agHectaresLong <- tryThis %>%
  tidyr::pivot_longer(cols = starts_with("Peak.NDVI"), 
                      names_to = "year", 
                      names_prefix = "Peak.NDVI.",
                      names_transform = list(year = function(x) (as.numeric(substr(x, 1, 4)))),
                      values_to = "agHectares") 
saveRDS(agHectaresLong, file = AG_HECTARES_RDS)



