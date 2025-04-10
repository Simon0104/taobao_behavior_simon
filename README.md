# 🛍️ Taobao 100M User Behavior Analytics

This project presents a comprehensive data analytics pipeline for processing and analyzing 100M+ rows of user behavioral data from Taobao. It demonstrates scalable SQL-based data cleaning, transformation, and behavioral analysis using Hive, along with core KPI metrics and business insights.

## 🔧 Tech Stack
- Hive SQL, Hadoop, Python, Streamlit (optional dashboard), Pandas, Plotly

## 📦 Project Scope
- 🧹 Data Cleaning: deduplication, timestamp conversion, outlier removal
- 📊 KPI Analysis: PV, UV, conversion funnel, repurchase rate
- 🧠 User Segmentation: RFM-based scoring model
- 📈 Behavioral Analysis: time series, hourly/weekly distribution, top items/categories

## 📁 Project Structure
- `sql/` — Hive SQL scripts for all data cleaning and analysis tasks
- `data/` — Sample CSV extracted from the original 100M+ dataset
- `screenshots/` — Visualizations of analysis results
- `dashboard/` — (Optional) Streamlit code for building interactive dashboard
- `notebook/` — Python notebooks/scripts for visualization or post-processing

## 🚀 How to Run
This project assumes a Hive environment with sample data loaded. For visualization, Python scripts using pandas + plotly are available.

## 📊 Sample Metrics
- Conversion rate from view to buy: **2.25%**
- Repurchase rate over 9-day period: **66.01%**
- Peak user activity hour: **21:00–22:00**
- Top product categories and behavior types tracked

## 📸 Screenshots
_(Include funnel chart, time series, RFM scores if available)_

## 📚 Reference
Data Source: Alibaba Taobao User Behavior Dataset
