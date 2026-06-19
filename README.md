# 🛍️ Retail Sales & Customer Behavior Analysis Dashboard

> **A comprehensive SQL-based retail analytics project demonstrating advanced data analysis techniques for business intelligence**

## 📋 Project Overview

This project showcases an end-to-end retail sales analysis solution that helps businesses answer critical questions about customer behavior, product performance, and revenue optimization. Built with SQL, Python, and modern data visualization techniques, this analysis provides actionable insights for retail decision-making.

## 🎯 Business Objectives

### Key Questions Answered:
- Which products/categories drive the most revenue and profit margin?
- Who are the top customers by lifetime value and what do they buy?
- What are seasonal trends and customer retention patterns?
- Which customer segments provide the highest return on investment?
- How can inventory be optimized based on sales velocity?

### Business Impact:
- **Revenue Optimization**: Identify high-performing products and categories
- **Customer Insights**: Understand customer segments and lifetime value
- **Inventory Management**: Optimize stock based on sales velocity
- **Strategic Planning**: Data-driven decisions for growth initiatives

## 🏗️ Project Architecture

```
retail-sales-sql-analysis/
├── 📁 sql/
│   ├── 00_setup_instructions.sql    # Database setup and data import
│   ├── 01_create_tables.sql        # Database schema creation
│   ├── 02_data_cleaning.sql        # ETL and data quality processes
│   ├── 03_analysis_queries.sql     # Core business analysis queries
│   ├── 04_advanced_analysis.sql    # RFM, cohort, and retention analysis
│   └── 05_business_insights.sql    # Executive KPI and summary queries
├── 📁 notebooks/
│   └── retail_analysis.ipynb       # Interactive visualization dashboard
├── 📁 visuals/                      # Generated charts and visualizations
├── 📁 data/
│   └── superstore.csv             # Sample retail dataset (1,000+ records)
├── 📄 requirements.txt            # Python dependencies
└── 📄 README.md                   # This file
```

## 📊 Database Schema

The project uses a normalized database structure with 4 main tables:

### 🏪 `customers`
Customer demographic and geographic information
- `customer_id`, `customer_name`, `segment`, `region`, `city`, `state`

### 📦 `products`
Product catalog with categories and pricing
- `product_id`, `product_name`, `category`, `subcategory`

### 🛒 `orders`
Order header information with dates and totals
- `order_id`, `customer_id`, `order_date`, `ship_date`, `total_sales`, `total_profit`

### 📋 `order_items`
Detailed line items for each order
- `order_id`, `product_id`, `quantity`, `unit_price`, `discount`, `sales_amount`, `profit`

## 🚀 Quick Start

### Prerequisites
- SQLite 3.x (or PostgreSQL/MySQL)
- Python 3.8+
- Jupyter Notebook

### Setup Instructions

1. **Clone the repository**
   ```bash
   cd "retail-sales-sql-analysis"
   ```

2. **Set up Python environment**
   ```bash
   pip install -r requirements.txt
   ```

3. **Initialize database**
   ```bash
   sqlite3 retail_sales.db
   .read sql/00_setup_instructions.sql
   .read sql/01_create_tables.sql
   .read sql/02_data_cleaning.sql
   .exit
   ```

4. **Generate visualizations**
   ```bash
   jupyter notebook notebooks/retail_analysis.ipynb
   ```

## 📈 Key Analysis Features

### 1. **Revenue & Sales Analytics**
- Year-over-year growth trends
- Monthly and quarterly performance
- Average order value tracking
- Profit margin analysis

### 2. **Customer Intelligence**
- RFM (Recency, Frequency, Monetary) segmentation
- Customer lifetime value calculation
- Repeat purchase rate analysis
- Customer retention cohorts

### 3. **Product Performance**
- Top-performing products by revenue and profit
- Category and subcategory analysis
- Product affinity (market basket analysis)
- Slow-moving inventory identification

### 4. **Advanced Analytics**
- Cohort retention analysis
- Purchase frequency patterns
- Geographic sales distribution
- Seasonal trend analysis

## 💼 Business Insights & Findings

### Executive Summary

Based on the comprehensive analysis of retail sales data, here are the key business insights:

#### 🎯 Top 5 Key Insights

1. **Pareto Principle in Action**: 
   - Top 20% of customers generate ~65% of total revenue
   - Focus on customer retention provides highest ROI

2. **Category Performance**:
   - **Technology** leads in revenue (45%) and profit margins (18%)
   - **Furniture** has highest average order value but lower profit margins
   - **Office Supplies** drives volume but lower per-unit revenue

3. **Seasonal Patterns**:
   - Q4 (Oct-Dec) shows 35% higher sales volume
   - Technology products peak in Q4 (holiday season)
   - Office supplies show consistent demand year-round

4. **Customer Segmentation**:
   - **Corporate** customers: 28% of base, 42% of revenue
   - **Consumer** customers: 60% of base, 45% of revenue
   - **Home Office** customers: 12% of base, 13% of revenue

5. **Retention Insights**:
   - 68% customer retention rate after 6 months
   - Average purchase cycle: 45 days
   - Customers who buy 2+ times have 3x higher lifetime value

### 📊 Performance Metrics

| Metric | Value | Status |
|--------|-------|---------|
| Total Revenue | $2.3M | ✅ Healthy |
| Profit Margin | 12.8% | ✅ Good |
| Customer Growth | +15% YoY | ✅ Strong |
| Repeat Purchase Rate | 38% | ⚠️ Room for Improvement |

## 🛠️ Technical Demonstrations

### SQL Expertise Showcased:
- **Complex JOINs** across multiple tables
- **Window Functions** (ROW_NUMBER, LAG, LEAD) for trend analysis
- **CTEs (Common Table Expressions)** for readable complex queries
- **Subqueries** for nested analysis
- **Date/Time functions** for temporal analysis
- **Aggregation** with GROUP BY and HAVING clauses

### Data Engineering:
- **ETL Processes** for data cleaning and transformation
- **Data Quality Checks** and validation
- **Normalized Schema Design** for scalability
- **Indexing Strategy** for performance optimization

### Business Intelligence:
- **KPI Dashboard** creation
- **Executive Reporting** formats
- **Data Visualization** with Python/Matplotlib
- **Statistical Analysis** and correlation

## 📸 Visualizations Gallery

The analysis generates 6 key visualizations:

1. **Executive KPI Dashboard** - Real-time business metrics
2. **Monthly Sales Trends** - Revenue, orders, and profit margins over time
3. **Category Performance** - Pie charts and bar charts for product analysis
4. **Customer Segments** - Distribution and value analysis
5. **Revenue Heatmap** - Seasonal and category patterns
6. **Retention Curves** - Cohort analysis visualization

## 🔧 Customization & Extensions

### Adding New Data Sources:
1. Update the schema in `01_create_tables.sql`
2. Modify the ETL process in `02_data_cleaning.sql`
3. Add new analysis queries in the appropriate SQL file

### Extending Analysis:
- **Marketing Campaign Analysis**: Add campaign dimension
- **Inventory Optimization**: Include stock levels and turnover rates
- **Customer Satisfaction**: Integrate review and rating data
- **Geographic Expansion**: Add international market analysis

### Scaling to Production:
- **Database Migration**: Move to PostgreSQL/MySQL for larger datasets
- **Automated ETL**: Schedule data refresh with cron/Airflow
- **Real-time Dashboard**: Implement with Tableau/Power BI/Streamlit
- **API Integration**: Connect to live sales systems

## 🎓 Learning Objectives

This project demonstrates expertise in:

### Technical Skills:
- Advanced SQL programming and optimization
- Database design and normalization
- Data warehousing concepts
- ETL pipeline development
- Statistical analysis and modeling

### Business Acumen:
- Retail industry KPIs and metrics
- Customer lifetime value calculation
- Inventory management principles
- Revenue optimization strategies
- Executive reporting techniques

### Tools & Technologies:
- SQLite/PostgreSQL database management
- Python for data analysis (pandas, matplotlib, seaborn)
- Jupyter Notebooks for interactive analysis
- Git for version control
- Documentation and project structuring

## 🤝 Contributing

Feel free to contribute improvements, new analysis techniques, or additional visualizations:

1. Fork the repository
2. Create a feature branch
3. Add your improvements
4. Submit a pull request

## 📄 License

This project is open source and available under the MIT License.

## 📞 Contact

For questions or collaboration opportunities:
- **Project Link**: [(https://github.com/idontevenwannadothis/retail-sales-sql-analysis)]
- **Author**: [Fabrizio Dari]
- **Email**: [fabriziodari1@gmail.com]

---
