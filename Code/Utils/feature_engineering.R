#-------------------------------------------------------------------------------------
# Title: feature_engineering
# Author: Tyler Katz
# Description:
# This script defines a reusable function, `feature_engineering()`, which applies 
# all data cleaning and feature transformation steps used in the main preprocessing 
# pipeline. The logic here is modularized from the `01_preprocessing.Rmd` file to 
# promote reusability and consistency across training, testing, and deployment scripts.
#-------------------------------------------------------------------------------------

feature_engineering <- function(df) {
  library(dplyr)
  library(lubridate)
  library(tidyr)
  
  df %>%
    mutate(
      # Convert date to Date type
      Date = ymd(date),
      
      # Extract temporal features
      Year = year(date),
      Month = month(date),
      Day = day(date),
      Week = week(date),
      
      #Impute competition distance
      CompetitionDistance = ifelse(
        is.na(CompetitionDistance),
        median(CompetitionDistance, na.rm = TRUE),
        CompetitionDistance
      ),
      
      #Impute competition open since month
      CompetitionOpenSinceMonth = ifelse(
        is.na(CompetitionOpenSinceMonth),
        median(CompetitionOpenSinceMonth, na.rm = TRUE),
        CompetitionOpenSinceMonth
      ),
      
      #Impute competition open since year
      CompetitionOpenSinceYear = ifelse(
        is.na(CompetitionOpenSinceYear),
        median(CompetitionOpenSinceYear, na.rm = TRUE),
        CompetitionOpenSinceYear
      ),
      
      #Add dummy values to indicate no Promo2
      Promo2SinceWeek = ifelse(is.na(Promo2SinceWeek), -1, Promo2SinceWeek),
      Promo2SinceYear = ifelse(is.na(Promo2SinceYear), -1, Promo2SinceYear),
      
      #Add a none value to indicate no promo intervals
      PromoInterval = replace_na(PromoInterval, "None"),
      
      # Derived categorical and binary features
      DayOfWeekLabel = factor(
        DayOfWeek,
        levels = 1:7,
        labels = c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
      ),
      
      IsWeekend = ifelse(DayOfWeekLabel %in% c("Sat", "Sun"), 1, 0),
      IsPromo = ifelse(Promo == 1, "Promo", "No Promo")
    )
}