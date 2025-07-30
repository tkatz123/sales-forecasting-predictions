# ------------------------------------------------------------------------------
# Title: Preprocess Test Data
# Description: Applies feature engineering and prepares test data by appending
#              lag and rolling features from final day of training set (2015-07-31).
# ------------------------------------------------------------------------------

# --- Load Required Libraries and Utility Functions ---
source("Code/Utils/load_packages.R")
source("Code/Utils/feature_engineering.R")

load_required_packages(c("tidyverse", "lubridate", "janitor"))

# --- Load Data ---
test_raw <- read_csv("Data/test.csv", show_col_types = FALSE)

store    <- read_csv("Data/store.csv", show_col_types = FALSE)

load("Data/preprocessed_train_data.RData")

train_processed <- df

# --- Merge Test Data with Store Metadata ---

#Merging test data with store data
test_merged <- left_join(test_raw, store, by = "Store")

# --- Apply Feature Engineering ---

#Apply feature engineering function to test data
test_processed <- feature_engineering(test_merged)

#Create a DF of lag and roll values for last day of training data
last_day <- train_processed %>% filter(Date == as.Date("2015-07-31")) %>%
  select(Store, Sales_lag_1, Sales_lag_7, Sales_lag_14, Sales_roll_mean_7, Sales_roll_mean_14)

# Add lag/rolling columns only to rows from 8/1/2015 (first day of test)
test_processed <- test_processed %>%
  left_join(last_day, by = "Store") %>%
  arrange(Store, Date)

#Replaces NA values in Open column to 0
test_processed <- test_processed %>%
  mutate(Open = replace_na(Open, 0))

# --- Save Preprocessed Test Data ---

save(test_processed, file = "Data/preprocessed_test_data.RData")


