# --- Loading Required Libraries & Data ---

#Load utility function
source("Code/Utils/load_packages.R")

#Use function to install and library packages
load_required_packages(c("tidyverse", "lubridate", "janitor", "xgboost", "Metrics"))

#Reading in preprocessed training data
train <- read_csv("Data/preprocessed_train_data.csv", show_col_types = FALSE)

# --- Data Preparation ---

#Filtering data to only stores that are open to avoid extreme values
train <- train %>% filter(Open == 1)

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
  "StoreType", "Assortment"
)

#Converts DataFrames to DMatrix where the features are stored as data, and the target is stores as label
train_matrix <- xgb.DMatrix(data = as.matrix(train_set[, features]), label = train_set$Sales)
test_matrix   <- xgb.DMatrix(data = as.matrix(test_set[, features]), label = test_set$Sales)

# --- Parameter Tuning ---

#Define hyperparameter grid
grid <- expand.grid(
  eta = c(0.01, 0.1, 0.3),
  max_depth = c(6, 8, 10),
  subsample = c(0.7, 0.9),
  colsample_bytree = c(0.7, 0.9),
  nrounds = c(100, 200)
)

#Initialize dataframe to hold results
results <- data.frame()

#Loop through all combinations of the parameter grid
for (i in 1:nrow(grid)) {
  
  params <- grid[i, ]
  
  cat("Training model", i, "of", nrow(grid), "\n")
  
  model <- xgboost(
    data = train_matrix,
    eta = params$eta,
    max_depth = params$max_depth,
    subsample = params$subsample,
    colsample_bytree = params$colsample_bytree,
    nrounds = params$nrounds,
    objective = "reg:squarederror",
    verbose = 0
  )
  
  #Predict and evaluate
  preds <- predict(model, test_matrix)
  rmse <- sqrt(mean((preds - test_set$Sales)^2))
  mae <- mean(abs(preds - test_set$Sales))
  
  #Save results
  results <- rbind(
    results,
    cbind(params, RMSE = rmse, MAE = mae)
  )
}

#Sort and display the best results
results <- results %>% arrange(RMSE)
print(head(results))

#Save the best performing configuration
best_params <- results[1, ]
saveRDS(best_params, "Models/best_xgb_params.rds")



