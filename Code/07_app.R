# ------------------------------------------------------------------------------
# Title: Rossmann Sales Forecasting App
# Description: Interactive Shiny app to forecast sales for selected store and
#              duration using pre-trained XGBoost model.
# ------------------------------------------------------------------------------

# --- Load Required Packages ---
source("Utils/load_packages.R")
load_required_packages(c("shiny", "tidyverse", "lubridate", "xgboost", "ggplot2"))

load_required_packages(c("shiny", "tidyverse", "lubridate", "xgboost", "ggplot2"))

# --- Load Data and Model Once When App Launches ---
load("../Data/preprocessed_test_data.RData")
test_data <- test_processed
xgb_model <- readRDS("../Models/xgb_global_model.rds")

# --- Converts Variables Similar to Training Data ---
to_numeric_factors <- function(df){
  df$StateHoliday <- as.numeric(df$StateHoliday)
  df$StoreType <- as.numeric(as.factor(df$StoreType))
  df$Assortment <- as.numeric(as.factor(df$Assortment))
  return(df)
}

test_data <- to_numeric_factors(test_data)

# --- UI ---
ui <- fluidPage(
  
  #Sets title for shiny app
  titlePanel("Rossmann Store Sales Forecast"),
  sidebarLayout(
    sidebarPanel(
      
      #Creates input for store
      selectInput("store_id", "Select Store:", 
                  choices = sort(unique(test_data$Store)), 
                  selected = sort(unique(test_data$Store))[1]),
      
      #Creates slider for time period of prediction
      sliderInput("forecast_days", "Select Forecast Duration (Days):", min = 7, max = 47, value = 14)
    ),
    mainPanel(
      plotOutput("salesPlot"),
      textOutput("totalSalesText")
    )
  )
)

# --- Server ---
server <- function(input, output) {
  
  #Filters data to inputted store
  filtered_data <- reactive({
    test_data %>%
      filter(Store == input$store_id) %>%
      arrange(Date) %>%
      head(input$forecast_days)
  })
  
  #Makes predictions for inputted store
  predictions <- reactive({
    new_data <- filtered_data()
    
    features <- c(
      "Store", "DayOfWeek", "Promo", "SchoolHoliday", "StateHoliday",
      "Year", "Month", "Day", "Week", "IsWeekend",
      "CompetitionDistance", "CompetitionOpenSinceMonth", "CompetitionOpenSinceYear",
      "Promo2SinceWeek", "Promo2SinceYear",
      "StoreType", "Assortment",
      "Sales_lag_1", "Sales_lag_7", "Sales_lag_14",
      "Sales_roll_mean_7", "Sales_roll_mean_14"
    )
    
    feature_matrix <- new_data[, features]
    
    feature_matrix <- feature_matrix %>% 
      mutate(across(everything(), ~ as.numeric(.)))
    
    dmatrix <- xgb.DMatrix(data = as.matrix(feature_matrix))
    
    dmatrix <- xgb.DMatrix(data = as.matrix(new_data[, features]))
    preds <- predict(xgb_model, dmatrix)
    
    new_data$PredictedSales <- preds
    new_data
  })
  
  #Creates a linegraph of predictions made for inputted store
  output$salesPlot <- renderPlot({
    df <- predictions()
    ggplot(df, aes(x = Date, y = PredictedSales)) +
      geom_line(color = "steelblue", size = 1.2) +
      geom_point(color = "darkblue") +
      labs(title = paste("Predicted Sales - Store", input$store_id),
           x = "Date", y = "Predicted Sales") +
      theme_minimal()
  })
  
  #Outputs the total sales for the inputted store in the designated time period
  output$totalSalesText <- renderText({
    df <- predictions()
    total <- sum(df$PredictedSales)
    paste("Total Forecasted Sales:", round(total, 2))
  })
}

# --- Run App ---
shinyApp(ui = ui, server = server)