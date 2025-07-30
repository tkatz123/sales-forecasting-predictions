# ------------------------------------------------------------------------------
# Title: Train Global Sales Forecasting Model
# Description: Trains a single machine learning model on all stores using preprocessed
#              training data. 
# ------------------------------------------------------------------------------

# --- Loading Required Libraries & Data ---

#Load utility function
source("Code/Utils/load_packages.R")

#Use function to install and library packages
load_required_packages(c("tidyverse", "lubridate", "janitor", "xgboost", "Metrics"))

#Reading in preprocessed training data

load("Data/preprocessed_train_data.RData")
train <- df

# --- Data Preparation ---

#Filtering data to only stores that are open to avoid extreme values
train <- train %>% filter(Open == 1)

#Remove rows with NA values from lag/rolling features
train <- train %>%
  filter(across(
    c(Sales_lag_1, Sales_lag_7, Sales_lag_14,
      Sales_roll_mean_7, Sales_roll_mean_14),
    ~ !is.na(.)
  ))

#Specify last 6 weeks of data as cutoff date for model validation
cutoff_date <- as.Date("2015-06-15")

#Filter training data to rows with dates before cutoff date
train_set <- train %>% filter(Date < cutoff_date)

#Filter testing data to rows with dates after cutoff date
test_set <- train %>% filter(Date >= cutoff_date)

#Convert categorical variables to numeric
to_numeric_factors <- function(df){
  df$StateHoliday <- as.numeric(df$StateHoliday)
  df$StoreType <- as.numeric(as.factor(df$StoreType))
  df$Assortment <- as.numeric(as.factor(df$Assortment))
  return(df)
}

#Apply function created above to training and testing data
train_set <- to_numeric_factors(train_set)
test_set <- to_numeric_factors(test_set)

# --- Selecting Features & Converting DataFrames to DMatrix ---

#Selecting variables from data to input into model
features <- c(
  "Store", "DayOfWeek", "Promo", "SchoolHoliday", "StateHoliday",
  "Year", "Month", "Day", "Week", "IsWeekend",
  "CompetitionDistance", "CompetitionOpenSinceMonth", "CompetitionOpenSinceYear",
  "Promo2SinceWeek", "Promo2SinceYear",
  "StoreType", "Assortment",
  "Sales_lag_1", "Sales_lag_7", "Sales_lag_14",
  "Sales_roll_mean_7", "Sales_roll_mean_14"
)

#Converts DataFrames to DMatrix where the features are stored as data, and the target is stores as label
train_matrix <- xgb.DMatrix(data = as.matrix(train_set[, features]), label = train_set$Sales)
test_matrix   <- xgb.DMatrix(data = as.matrix(test_set[, features]), label = test_set$Sales)

# --- Model Training ---

best_params <- readRDS("Models/best_xgb_params.rds")

#Trains xgboost model, specifying this as a regression task
xgb_model <- xgboost(
  data = train_matrix,
  eta = best_params$eta,
  max_depth = best_params$max_depth,
  subsample = best_params$subsample,
  colsample_bytree = best_params$colsample_bytree,
  nrounds = best_params$nrounds,
  objective = "reg:squarederror",
  verbose = 1
)


# --- Predict and Evaluate ---

#Makes predictions based on test data using model 
test_predictions <- predict(xgb_model, test_matrix)

#Calculates an RMSE score
rmse <- Metrics::rmse(test_set$Sales, test_predictions)

#Calculates and MAE score
mae <- Metrics::mae(test_set$Sales, test_predictions)

#Outputs evaluation scores
cat("Validation RMSE:", round(rmse, 2), "\n")
cat("Validation MAE: ", round(mae, 2), "\n")

# --- Save Trained Model ---

saveRDS(xgb_model, file = "Models/xgb_global_model.rds")


