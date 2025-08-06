# ------------------------------------------------------------------------------
# Title: Rossmann Sales Forecasting App
# Description: Interactive Shiny app to forecast sales for selected store and
#              duration using pre-trained XGBoost model.
# ------------------------------------------------------------------------------

# --- Load Required Packages ---
source("Utils/load_packages.R")
load_required_packages(c("shiny", "tidyverse", "lubridate", "xgboost", "ggplot2"))

# --- Load Data and Model Once When App Launches ---
load("../Data/preprocessed_train_data.RData")
train_data <- df
xgb_model <- readRDS("../Models/xgb_global_model.rds")

# --- Converts Variables Similar to Training Data ---
to_numeric_factors <- function(df){
  df$StateHoliday <- as.numeric(df$StateHoliday)
  df$StoreType <- as.numeric(as.factor(df$StoreType))
  df$Assortment <- as.numeric(as.factor(df$Assortment))
  return(df)
}

train_data <- to_numeric_factors(train_data)

# --- UI ---
ui <- fluidPage(
  titlePanel("Rossmann Sales Forecast (Actual vs Predicted)"),
  sidebarLayout(
    sidebarPanel(
      selectInput("store_id", "Select Store:",
                  choices = sort(unique(train_data$Store)),
                  selected = sort(unique(train_data$Store))[1]),
      sliderInput("forecast_days", "Select Time Frame (Days):", min = 7, max = 90, value = 14)
    ),
    mainPanel(
      plotOutput("salesPlot"),
      textOutput("totalSalesText")
    )
  )
)

# --- Server ---
server <- function(input, output) {
  
  filtered_data <- reactive({
    train_data %>%
      filter(Store == input$store_id) %>%
      arrange(Date) %>%
      tail(input$forecast_days)  # use most recent 'n' days
  })
  
  predictions <- reactive({
    df <- filtered_data()
    features <- c(
      "Store", "DayOfWeek", "Promo", "SchoolHoliday", "StateHoliday",
      "Year", "Month", "Day", "Week", "IsWeekend",
      "CompetitionDistance", "CompetitionOpenSinceMonth", "CompetitionOpenSinceYear",
      "Promo2SinceWeek", "Promo2SinceYear",
      "StoreType", "Assortment",
      "Sales_lag_1", "Sales_lag_7", "Sales_lag_14",
      "Sales_roll_mean_7", "Sales_roll_mean_14", "Open", "IsClosedDay",
      "IsMonthStart", "IsMonthEnd", "PromoActive", "CompetitionActive"
    )
    dmatrix <- xgb.DMatrix(data = as.matrix(df[, features]))
    df$PredictedSales <- predict(xgb_model, dmatrix)
    df
  })
  
  output$salesPlot <- renderPlot({
    df <- predictions()
    ggplot(df, aes(x = Date)) +
      geom_line(aes(y = Sales, color = "Actual"), size = 1.2) +
      geom_line(aes(y = PredictedSales, color = "Predicted"), size = 1.2, linetype = "dashed") +
      scale_color_manual(values = c("Actual" = "red", "Predicted" = "steelblue")) +
      labs(title = paste("Store", input$store_id, "- Actual vs Predicted Sales"),
           x = "Date", y = "Sales", color = "") +
      theme_minimal()
  })
  
  output$totalSalesText <- renderText({
    df <- predictions()
    total_actual <- sum(df$Sales)
    total_predicted <- sum(df$PredictedSales)
    paste0("Total Actual Sales: ", round(total_actual, 2), " | Total Predicted Sales: ", round(total_predicted, 2))
  })
}

# --- Run App ---
shinyApp(ui = ui, server = server)