# Load required libraries
library(shiny)
library(shinydashboard)
library(dplyr)
library(ggplot2)
library(plotly)
library(DT)
library(tidyr)

# =====================================================================
# TASK 1: Data Exploration & Preparation
# - Identifies key dimensions/measures and performs preprocessing.
# - Handles missing values, outliers, and formatting.
# =====================================================================

df <- read.csv("C:/Users/vinay/Downloads/telecom_customer_churn.csv", stringsAsFactors = FALSE)

# Handle missing values & format (converting currency to numeric)
df$Total.Charges <- as.numeric(df$Total.Charges)
df$Total.Revenue <- as.numeric(df$Total.Revenue)

# Replace NAs in numerical columns with 0 or drop them for simplicity
df <- df %>% drop_na(Total.Charges, Total.Revenue, Tenure.in.Months)

# Replace empty strings in Internet Type with "None"
df$Internet.Type[df$Internet.Type == ""] <- "None"


# =====================================================================
# UI Definition 
# Fulfills TASK 2 (Dashboard Development) & TASK 4 (Interactivity)
# =====================================================================
ui <- dashboardPage(
  dashboardHeader(title = "Telecom Churn Insights"),
  
  # -------------------------------------------------------------------
  # TASK 4: Interactivity (Filters)
  # - Implementing Date (Tenure), Category (Internet), Region (City)
  # -------------------------------------------------------------------
  dashboardSidebar(
    selectInput("city", "Select City (Region Filter):", 
                choices = c("All", unique(df$City)), selected = "All"),
    
    selectInput("internet_type", "Select Internet Type (Category Filter):", 
                choices = c("All", unique(df$Internet.Type)), selected = "All"),
    
    sliderInput("tenure", "Tenure in Months (Time Filter):", 
                min = min(df$Tenure.in.Months, na.rm = TRUE), 
                max = max(df$Tenure.in.Months, na.rm = TRUE), 
                value = c(min(df$Tenure.in.Months), max(df$Tenure.in.Months)))
  ),
  
  # -------------------------------------------------------------------
  # TASK 2: Dashboard Development
  # - Creating layout for Time-series, Category, Distribution, and Relationship
  # -------------------------------------------------------------------
  dashboardBody(
    fluidRow(
      box(plotlyOutput("timeSeriesPlot"), width = 6, title = "Trend: Revenue over Tenure"),
      box(plotlyOutput("categoryPlot"), width = 6, title = "Category: Revenue by Contract & Internet")
    ),
    fluidRow(
      box(plotlyOutput("distPlot"), width = 6, title = "Distribution: Monthly Charges"),
      box(plotlyOutput("scatterPlot"), width = 6, title = "Relationship: Monthly Charge vs Total Revenue")
    ),
    fluidRow(
      # TASK 4: Interactivity (Drill-down capabilities)
      box(DTOutput("dataTable"), width = 12, title = "Data Drill-down Explorer")
    )
  )
)

# =====================================================================
# Server Logic
# Fulfills TASK 3 (Justification) and TASK 6 (Optimization)
# =====================================================================
server <- function(input, output) {
  
  # Reactive subset of data based on filters
  filtered_data <- reactive({
    data <- df
    if (input$city != "All") {
      data <- data %>% filter(City == input$city)
    }
    if (input$internet_type != "All") {
      data <- data %>% filter(Internet.Type == input$internet_type)
    }
    data <- data %>% filter(Tenure.in.Months >= input$tenure[1] & Tenure.in.Months <= input$tenure[2])
    return(data)
  })
  
  # ---------------------------------------------------------
  # TASK 2: Time-series analysis proxy (Revenue over Tenure)
  # ---------------------------------------------------------
  output$timeSeriesPlot <- renderPlotly({
    req(nrow(filtered_data()) > 0)
    
    # TASK 6: Performance Optimization
    # Aggregating large dataset points into a summary table before rendering
    trend_data <- filtered_data() %>%
      group_by(Tenure.in.Months) %>%
      summarise(Avg_Revenue = mean(Total.Revenue, na.rm = TRUE))
    
    # TASK 3: Visualization Justification
    # Line charts are the best choice to show continuous trends over time (Tenure).
    p <- ggplot(trend_data, aes(x = Tenure.in.Months, y = Avg_Revenue)) +
      geom_line(color = "steelblue", size = 1) + 
      geom_point(color = "darkred", size = 1.5) +
      theme_minimal() + 
      labs(x = "Tenure (Months)", y = "Average Total Revenue")
    
    # TASK 4: Interactivity (Tooltips) via ggplotly integration
    ggplotly(p) 
  })
  
  # ---------------------------------------------------------
  # TASK 2: Category-wise and region-wise comparisons
  # ---------------------------------------------------------
  output$categoryPlot <- renderPlotly({
    req(nrow(filtered_data()) > 0)
    
    # TASK 6: Performance Optimization (Pre-calculating sums)
    cat_data <- filtered_data() %>%
      group_by(Contract, Internet.Type) %>%
      summarise(Total_Rev = sum(Total.Revenue, na.rm = TRUE), .groups = 'drop')
    
    # TASK 3: Visualization Justification
    # Grouped bar charts are ideal for comparing total magnitudes across multiple categories.
    p <- ggplot(cat_data, aes(x = Contract, y = Total_Rev, fill = Internet.Type)) +
      geom_bar(stat = "identity", position = "dodge") +
      theme_minimal() + 
      labs(x = "Contract Type", y = "Total Revenue", fill = "Internet Type")
    
    ggplotly(p)
  })
  
  # ---------------------------------------------------------
  # TASK 2: Distribution of key variables
  # ---------------------------------------------------------
  output$distPlot <- renderPlotly({
    req(nrow(filtered_data()) > 0)
    
    # TASK 3: Visualization Justification
    # Histograms are specifically designed to show the frequency distribution of a single numerical variable.
    p <- ggplot(filtered_data(), aes(x = Monthly.Charge)) +
      geom_histogram(bins = 30, fill = "#17becf", color = "white") +
      theme_minimal() + 
      labs(x = "Monthly Charge ($)", y = "Count of Customers")
    
    ggplotly(p)
  })
  
  # ---------------------------------------------------------
  # TASK 2: Relationship between variables
  # ---------------------------------------------------------
  output$scatterPlot <- renderPlotly({
    req(nrow(filtered_data()) > 0)
    
    # TASK 3: Visualization Justification
    # Scatterplots are the standard method for mapping correlation between two continuous variables.
    p <- ggplot(filtered_data(), aes(x = Monthly.Charge, y = Total.Revenue, color = Customer.Status)) +
      geom_point(alpha = 0.6) +
      theme_minimal() + 
      labs(x = "Monthly Charge ($)", y = "Total Revenue ($)", color = "Status")
    
    ggplotly(p)
  })
  
  # ---------------------------------------------------------
  # TASK 4: Interactivity (Drill-down capabilities)
  # ---------------------------------------------------------
  output$dataTable <- renderDT({
    # datatable allows users to search, sort, and drill down into the specific raw data
    datatable(filtered_data() %>% select(Customer.ID, City, Tenure.in.Months, Internet.Type, Monthly.Charge, Total.Revenue, Customer.Status),
              options = list(pageLength = 5, scrollX = TRUE), 
              rownames = FALSE)
  })
}

# =====================================================================
# TASK 5: Insight Generation
# Note for submission: The insights (trends, anomalies, best/worst 
# categories) are documented in the separate GitHub README.md file.
# =====================================================================

# Run the application 
shinyApp(ui = ui, server = server)
