# Load required libraries
library(shiny)
library(shinydashboard)
library(dplyr)
library(ggplot2)
library(plotly)
library(DT)
library(tidyr)

# ==========================================
# Task 1: Data Exploration & Preparation
# ==========================================
# Read the dataset (Ensure the CSV is in your working directory)
df <- read.csv("C:/Users/vinay/Downloads/telecom_customer_churn.csv", stringsAsFactors = FALSE)

# Handle missing values & format
# Converting spaces in column names to dots (default read.csv behavior)
# e.g., 'Total Charges' becomes 'Total.Charges'
df$Total.Charges <- as.numeric(df$Total.Charges)
df$Total.Revenue <- as.numeric(df$Total.Revenue)

# Replace NAs in numerical columns with 0 or drop them for simplicity
df <- df %>% drop_na(Total.Charges, Total.Revenue, Tenure.in.Months)

# Replace empty strings in Internet Type with "None"
df$Internet.Type[df$Internet.Type == ""] <- "None"


# ==========================================
# UI Definition (Task 2 & 4: Dashboard & Interactivity)
# ==========================================
ui <- dashboardPage(
  dashboardHeader(title = "Telecom Churn Insights"),
  
  # Task 4: Filters for Region (City), Category (Internet Type), and Date/Time (Tenure proxy)
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
      # Task 4: Drill-down capabilities via interactive Data Table
      box(DTOutput("dataTable"), width = 12, title = "Data Drill-down Explorer")
    )
  )
)

# ==========================================
# Server Logic
# ==========================================
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
  # 1. Time-series analysis proxy (Revenue over Tenure)
  # ---------------------------------------------------------
  output$timeSeriesPlot <- renderPlotly({
    req(nrow(filtered_data()) > 0)
    
    # Task 6: Summarizing data prior to plotting to optimize performance
    trend_data <- filtered_data() %>%
      group_by(Tenure.in.Months) %>%
      summarise(Avg_Revenue = mean(Total.Revenue, na.rm = TRUE))
    
    # Task 3 Justification: A line chart is the most effective way to show longitudinal trends over time/tenure.
    p <- ggplot(trend_data, aes(x = Tenure.in.Months, y = Avg_Revenue)) +
      geom_line(color = "steelblue", size = 1) + 
      geom_point(color = "darkred", size = 1.5) +
      theme_minimal() + 
      labs(x = "Tenure (Months)", y = "Average Total Revenue")
    
    ggplotly(p) # Adds tooltips dynamically
  })
  
  # ---------------------------------------------------------
  # 2. Category-wise comparison
  # ---------------------------------------------------------
  output$categoryPlot <- renderPlotly({
    req(nrow(filtered_data()) > 0)
    
    cat_data <- filtered_data() %>%
      group_by(Contract, Internet.Type) %>%
      summarise(Total_Rev = sum(Total.Revenue, na.rm = TRUE), .groups = 'drop')
    
    # Task 3 Justification: A grouped bar chart allows for easy visual comparison across sub-categories (Internet vs Contract).
    p <- ggplot(cat_data, aes(x = Contract, y = Total_Rev, fill = Internet.Type)) +
      geom_bar(stat = "identity", position = "dodge") +
      theme_minimal() + 
      labs(x = "Contract Type", y = "Total Revenue", fill = "Internet Type")
    
    ggplotly(p)
  })
  
  # ---------------------------------------------------------
  # 3. Distribution of key variables
  # ---------------------------------------------------------
  output$distPlot <- renderPlotly({
    req(nrow(filtered_data()) > 0)
    
    # Task 3 Justification: A histogram is the standard visualization to view the spread and skewness of continuous variables.
    p <- ggplot(filtered_data(), aes(x = Monthly.Charge)) +
      geom_histogram(bins = 30, fill = "#17becf", color = "white") +
      theme_minimal() + 
      labs(x = "Monthly Charge ($)", y = "Count of Customers")
    
    ggplotly(p)
  })
  
  # ---------------------------------------------------------
  # 4. Relationship between variables
  # ---------------------------------------------------------
  output$scatterPlot <- renderPlotly({
    req(nrow(filtered_data()) > 0)
    
    # Task 3 Justification: Scatterplots are ideal for observing correlation and outliers between two continuous variables.
    p <- ggplot(filtered_data(), aes(x = Monthly.Charge, y = Total.Revenue, color = Customer.Status)) +
      geom_point(alpha = 0.6) +
      theme_minimal() + 
      labs(x = "Monthly Charge ($)", y = "Total Revenue ($)", color = "Status")
    
    ggplotly(p)
  })
  
  # ---------------------------------------------------------
  # 5. Interactivity / Drill-down
  # ---------------------------------------------------------
  output$dataTable <- renderDT({
    # Uses DataTables (DT) to allow users to search, page, and drill down into the specific records
    datatable(filtered_data() %>% select(Customer.ID, City, Tenure.in.Months, Internet.Type, Monthly.Charge, Total.Revenue, Customer.Status),
              options = list(pageLength = 5, scrollX = TRUE), 
              rownames = FALSE)
  })
}

# Run the application 
shinyApp(ui = ui, server = server)