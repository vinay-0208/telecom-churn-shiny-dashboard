# Telecom Customer Churn - Interactive Shiny Dashboard

**Name:** VINAY VISWANATHAN  
**Registration Number:** 23MID0429  

## Project Overview
This repository contains an R Shiny dashboard developed for analyzing telecom customer churn. This project fulfills the requirements for the **Advanced Data Visualization Techniques** assessment (Course Code: CSI 3005) by extracting relevant business insights through interactive data visualization.

## Files Included
* `app.R`: The complete R Shiny application containing the UI layout and Server logic.
* `telecom_customer_churn.csv`: The dataset used to generate the dashboard.

## How to Run the Application
1. Download or clone this repository.
2. Open `app.R` in RStudio.
3. Ensure the required libraries (`shiny`, `shinydashboard`, `dplyr`, `ggplot2`, `plotly`, `DT`, `tidyr`) are installed.
4. Verify the file path in `read.csv()` points to the local location of the dataset.
5. Click **"Run App"** in RStudio.

---

## Task 3: Visualization Justification
The following charts were selected to provide the most effective visual representation of the dataset:

1. **Line Chart (Trend: Revenue over Tenure)**
   * *Justification:* Line charts are the optimal visual choice for displaying continuous trends over a sequential or time-based variable. This makes it immediately clear how average revenue grows as a customer's tenure (lifespan) increases.
2. **Grouped Bar Chart (Category: Revenue by Contract & Internet)**
   * *Justification:* Bar charts allow for rapid visual comparison of total magnitudes across discrete categories. Grouping them allows us to observe the intersection of two categories (Contract Types and Internet Services) simultaneously.
3. **Histogram (Distribution: Monthly Charges)**
   * *Justification:* Histograms are specifically designed to show the frequency distribution, spread, and skewness of a single continuous numerical variable, revealing where the majority of customers' monthly bills fall.
4. **Scatter Plot (Relationship: Monthly Charge vs. Total Revenue)**
   * *Justification:* Scatter plots are the standard and most effective method for mapping the correlation, clusters, and potential outliers between two continuous numerical variables.

---

## Task 5: Insight Generation
Based on the interactive dashboard analysis, the following insights were generated:

* **Key Trends and Patterns:** There is a strong, predictable positive correlation between Tenure and Total Revenue. However, the time-series analysis reveals that revenue growth stabilizes for certain early-tenure cohorts, indicating a high risk of customer churn within the first few months of service.
* **Best and Worst Performing Categories:** * *Best Revenue Generator:* The "Fiber Optic" internet type yields the highest monthly charges and total revenue.
  * *Worst Retention Category:* Customers on "Month-to-Month" contracts are the worst-performing in terms of retention (highest churn rate) compared to those locked into One-Year or Two-Year contracts.
* **Anomalies / Unusual Observations:** The scatter plot reveals distinct horizontal clusters of customers who have very high tenure but surprisingly low total revenue. This anomaly points to a segment of legacy customers who are likely still on outdated, cheaper plans and have not been up-sold to newer services.

---

## Task 6: Performance Optimization
To ensure the dashboard remains highly responsive and handles the large dataset efficiently, **server-side data aggregation** was implemented using the `dplyr` package. 

Instead of passing the raw dataset directly to the `plotly` rendering engine (which can cause browser lag), the code uses the `group_by %>% summarise` pipeline. By calculating the mathematical summaries (like sums and averages) on the backend server first, the dashboard only has to render the significantly smaller set of summarized visual points, drastically optimizing UI performance.
