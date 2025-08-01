# sales-forecasting-predictions

This project builds a full **machine learning pipeline** to predict daily sales for **Rossmann stores** using historical data. It includes **preprocessing**, **feature engineering**, **exploratory data analysis**, **model training with XGBoost**, **evaluation**, and a **Shiny dashboard** for interactive predictions and visualizations.

---

## Project Structure

`Code/`

- `01_preprocessing.Rmd`: Cleans raw data and creates engineered features

- `02_EDA.Rmd`: Performs exploratory data analysis and visualizations

- `03_train_global_model.R`: Trains the baseline XGBoost model

- `04_tune_xgboost_model.R`: Performs hyperparameter tuning with time-series cross-validation

- `05_model_evaluation.Rmd`: Evaluates model performance on training data

- `06_app.R`: Shiny app to visualize and interact with store-level forecasts

- `Utils/`

    - `load_packages.R`: Loads and installs required packages

`Data/`

- `train.csv`: Raw training data from the original competition

- `store.csv`: Store-specific metadata

- `preprocessed_train_data.RData`: Cleaned and feature-rich dataset for modeling

`Models/`

- `best_xgb_params.rds`: Best parameters for XGBoost model

- `xgb_global_model.rds`: Final trained XGBoost model after tuning

`sales-forecasting-predictions.Rproj`: RStudio project file

---

## How to Run Shiny App

- Open `06_app.R`

- Select `Run App` in the top right of the code window

---

## Shiny App Features

- Interactive interface to explore predictions

- Choose a store and number of recent days (7–90)

- View actual vs predicted sales line plot

- Display total predicted vs actual sales for selected duration

---

## Engineered Features

**New variables created to improve prediction accuracy:**

- `IsPromo`: readable label for Promo (Promo / No Promo)

- `IsClosedDay`: indicates if the store was closed (`Open == 0`)

- `IsMonthStart`: flags if the date is within the first 3 days of the month

- `IsMonthEnd`: flags if the date is within the last 3 days of the month

- `PromoActive`: indicates if either Promo or Promo2 was active

- `CompetitionActive`: indicates if competition has opened (based on date info)

**Additional time-based features:**

- `Year`, `Month`, `Week`, `Day`

- `IsWeekend`: Saturday or Sunday

**Sales history features:**

- Lagged sales: `Sales_lag_1`, `Sales_lag_7`, `Sales_lag_14`

- Rolling averages: `Sales_roll_mean_7`, `Sales_roll_mean_14`

---

## Model Details

- Model: XGBoost Regressor (`reg:squarederror`)

- Features: 28 variables including calendar info, promo status, competition, lag & rolling sales

- Cross-validation: Time-series aware (preventing leakage)

Baseline performance (before tuning and feature engineering):

- RMSE: 1433.87

- MAE: 1081.46

Performance after tuning and feature engineering:

- RMSE: 663.47

- MAE: 438.57

---

## Packages Used

- tidyverse
- lubridate
- janitor
- zoo
- ggplot2
- skimr
- plotly
- xgboost
- Metrics
- readr
- shiny

---

## Author

Tyler Katz

B.S. in Applied Data Analytics, Class of 2026
Syracuse University

[GitHub Profile](https://github.com/tkatz123) • [LinkedIn](https://www.linkedin.com/in/tylerkatz1/)

---

## License

This project is released under the MIT License.

---

## Acknowledgments

This work is inspired by the Rossmann Store Sales competition on Kaggle and adapted as a full end-to-end forecasting project in R with an interactive Shiny dashboard.

[Dataset](https://www.kaggle.com/competitions/rossmann-store-sales/data)