-- Business Insights Summary - Executive Dashboard Queries
-- These queries provide high-level business insights for decision making

-- ==========================================
-- EXECUTIVE SUMMARY: KEY PERFORMANCE INDICATORS
-- ==========================================

-- Overall Business KPIs
SELECT 
    'Overall Performance' as metric_category,
    COUNT(DISTINCT strftime('%Y-%m', order_date)) as months_of_data,
    COUNT(DISTINCT customer_id) as total_customers,
    COUNT(DISTINCT order_id) as total_orders,
    ROUND(SUM(total_sales), 2) as total_revenue,
    ROUND(SUM(total_profit), 2) as total_profit,
    ROUND(SUM(total_profit) / SUM(total_sales) * 100, 2) as profit_margin_pct,
    ROUND(AVG(total_sales), 2) as avg_order_value,
    ROUND(SUM(total_sales) / COUNT(DISTINCT customer_id), 2) as revenue_per_customer
FROM orders;

-- Year-over-Year Growth Analysis
WITH yearly_metrics AS (
    SELECT 
        strftime('%Y', order_date) as year,
        COUNT(DISTINCT order_id) as orders,
        SUM(total_sales) as revenue,
        SUM(total_profit) as profit,
        COUNT(DISTINCT customer_id) as customers
    FROM orders
    GROUP BY strftime('%Y', order_date)
),
growth_analysis AS (
    SELECT 
        year,
        orders,
        revenue,
        profit,
        customers,
        LAG(revenue) OVER (ORDER BY year) as prev_year_revenue,
        LAG(orders) OVER (ORDER BY year) as prev_year_orders,
        LAG(customers) OVER (ORDER BY year) as prev_year_customers
    FROM yearly_metrics
)
SELECT 
    year,
    orders,
    ROUND(revenue, 2) as revenue,
    ROUND(profit, 2) as profit,
    customers,
    ROUND(revenue / customers, 2) as revenue_per_customer,
    CASE 
        WHEN prev_year_revenue > 0 THEN ROUND((revenue - prev_year_revenue) * 100.0 / prev_year_revenue, 2)
        ELSE NULL
    END as revenue_growth_pct,
    CASE 
        WHEN prev_year_orders > 0 THEN ROUND((orders - prev_year_orders) * 100.0 / prev_year_orders, 2)
        ELSE NULL
    END as orders_growth_pct,
    CASE 
        WHEN prev_year_customers > 0 THEN ROUND((customers - prev_year_customers) * 100.0 / prev_year_customers, 2)
        ELSE NULL
    END as customers_growth_pct
FROM growth_analysis
ORDER BY year;

-- ==========================================
-- CUSTOMER INSIGHTS: 80/20 ANALYSIS
-- ==========================================

-- Pareto Analysis: Do 20% of customers generate 80% of revenue?
WITH customer_revenue_ranked AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        c.segment,
        SUM(o.total_sales) as customer_revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(o.total_sales) DESC) as revenue_rank,
        ROUND(SUM(o.total_sales) * 100.0 / (SELECT SUM(total_sales) FROM orders), 2) as revenue_contribution_pct
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name, c.segment
),
customer_counts AS (
    SELECT 
        COUNT(*) as total_customers
    FROM customer_revenue_ranked
)
SELECT 
    'Top 20% Customers' as customer_tier,
    COUNT(*) as customer_count,
    customer_count.total_customers as total_customers,
    ROUND(COUNT(*) * 100.0 / customer_count.total_customers, 2) as customer_percentage,
    ROUND(SUM(customer_revenue), 2) as total_revenue,
    ROUND(SUM(customer_revenue) * 100.0 / (SELECT SUM(total_sales) FROM orders), 2) as revenue_percentage,
    ROUND(AVG(customer_revenue), 2) as avg_revenue_per_customer
FROM customer_revenue_ranked cr
JOIN customer_count ON 1=1
WHERE revenue_rank <= (SELECT total_customers * 0.2 FROM customer_counts)
UNION ALL
SELECT 
    'All Other Customers' as customer_tier,
    COUNT(*) as customer_count,
    customer_count.total_customers as total_customers,
    ROUND(COUNT(*) * 100.0 / customer_count.total_customers, 2) as customer_percentage,
    ROUND(SUM(customer_revenue), 2) as total_revenue,
    ROUND(SUM(customer_revenue) * 100.0 / (SELECT SUM(total_sales) FROM orders), 2) as revenue_percentage,
    ROUND(AVG(customer_revenue), 2) as avg_revenue_per_customer
FROM customer_revenue_ranked cr
JOIN customer_count ON 1=1
WHERE revenue_rank > (SELECT total_customers * 0.2 FROM customer_counts);

-- Customer Lifetime Value by Segment
WITH customer_ltv AS (
    SELECT 
        c.segment,
        c.customer_id,
        COUNT(DISTINCT o.order_id) as total_orders,
        MIN(o.order_date) as first_order,
        MAX(o.order_date) as last_order,
        JULIANDAY(MAX(o.order_date)) - JULIANDAY(MIN(o.order_date)) as customer_lifetime_days,
        SUM(o.total_sales) as lifetime_value
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.segment, c.customer_id
)
SELECT 
    segment,
    COUNT(*) as customer_count,
    ROUND(AVG(lifetime_value), 2) as avg_ltv,
    ROUND(MEDIAN(lifetime_value), 2) as median_ltv,
    ROUND(AVG(total_orders), 2) as avg_orders_per_customer,
    ROUND(AVG(customer_lifetime_days), 0) as avg_customer_lifetime_days,
    ROUND(lifetime_value / NULLIF(customer_lifetime_days, 0) * 365, 2) as annualized_value
FROM customer_ltv
GROUP BY segment
ORDER BY avg_ltv DESC;

-- ==========================================
-- PRODUCT INSIGHTS: CATEGORY PERFORMANCE
-- ==========================================

-- Category Performance Summary
WITH category_metrics AS (
    SELECT 
        p.category,
        COUNT(DISTINCT p.product_id) as unique_products,
        COUNT(DISTINCT oi.order_id) as total_orders,
        SUM(oi.quantity) as total_quantity,
        ROUND(SUM(oi.sales_amount), 2) as total_revenue,
        ROUND(SUM(oi.profit), 2) as total_profit,
        ROUND(SUM(oi.profit) / SUM(oi.sales_amount) * 100, 2) as profit_margin_pct
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY p.category
),
total_metrics AS (
    SELECT 
        SUM(total_revenue) as grand_total_revenue,
        SUM(total_profit) as grand_total_profit,
        SUM(total_orders) as grand_total_orders
    FROM category_metrics
)
SELECT 
    cm.category,
    cm.unique_products,
    cm.total_orders,
    ROUND(cm.total_revenue, 2) as revenue,
    ROUND(cm.total_profit, 2) as profit,
    cm.profit_margin_pct,
    ROUND(cm.total_revenue * 100.0 / tm.grand_total_revenue, 2) as revenue_share_pct,
    ROUND(cm.total_orders * 100.0 / tm.grand_total_orders, 2) as order_share_pct,
    ROUND(cm.total_revenue / cm.unique_products, 2) as revenue_per_product
FROM category_metrics cm
CROSS JOIN total_metrics tm
ORDER BY cm.total_revenue DESC;

-- Product Category Trends Over Time
SELECT 
    strftime('%Y', o.order_date) as year,
    p.category,
    COUNT(DISTINCT oi.order_id) as orders,
    ROUND(SUM(oi.sales_amount), 2) as revenue,
    ROUND(SUM(oi.profit), 2) as profit,
    ROUND(SUM(oi.profit) / SUM(oi.sales_amount) * 100, 2) as profit_margin_pct,
    ROUND(SUM(oi.sales_amount) * 100.0 / (SELECT SUM(total_sales) FROM orders WHERE strftime('%Y', order_date) = strftime('%Y', o.order_date)), 2) as revenue_share_pct_year
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o ON oi.order_id = o.order_id
GROUP BY strftime('%Y', o.order_date), p.category
ORDER BY year, revenue DESC;

-- ==========================================
-- OPERATIONAL INSIGHTS: EFFICIENCY METRICS
-- ==========================================

-- Shipping Performance Analysis
SELECT 
    ship_mode,
    COUNT(DISTINCT order_id) as total_orders,
    ROUND(SUM(total_sales), 2) as revenue,
    ROUND(AVG(total_sales), 2) as avg_order_value,
    COUNT(DISTINCT customer_id) as unique_customers,
    ROUND(AVG(JULIANDAY(ship_date) - JULIANDAY(order_date)), 1) as avg_delivery_days,
    ROUND(SUM(total_sales) * 100.0 / (SELECT SUM(total_sales) FROM orders), 2) as revenue_share_pct,
    ROUND(COUNT(DISTINCT order_id) * 100.0 / (SELECT COUNT(*) FROM orders), 2) as order_share_pct
FROM orders
GROUP BY ship_mode
ORDER BY revenue DESC;

-- Seasonal Sales Patterns
SELECT 
    CASE 
        WHEN CAST(strftime('%m', order_date) AS INTEGER) IN (12, 1, 2) THEN 'Winter'
        WHEN CAST(strftime('%m', order_date) AS INTEGER) IN (3, 4, 5) THEN 'Spring'
        WHEN CAST(strftime('%m', order_date) AS INTEGER) IN (6, 7, 8) THEN 'Summer'
        ELSE 'Fall'
    END as season,
    COUNT(DISTINCT strftime('%Y', order_date)) as years_count,
    COUNT(DISTINCT order_id) as total_orders,
    ROUND(SUM(total_sales) / COUNT(DISTINCT strftime('%Y', order_date)), 2) as avg_annual_revenue,
    ROUND(AVG(total_sales), 2) as avg_order_value,
    COUNT(DISTINCT customer_id) as unique_customers
FROM orders
GROUP BY season
ORDER BY avg_annual_revenue DESC;

-- ==========================================
-- BUSINESS HEALTH CHECK
-- ==========================================

-- Key Business Health Indicators
SELECT 
    'Business Health Metrics' as metric_type,
    CASE 
        WHEN total_revenue_growth_rate >= 0.10 THEN 'Excellent'
        WHEN total_revenue_growth_rate >= 0.05 THEN 'Good'
        WHEN total_revenue_growth_rate >= 0 THEN 'Fair'
        ELSE 'Poor'
    END as revenue_growth_health,
    CASE 
        WHEN profit_margin_pct >= 0.15 THEN 'Excellent'
        WHEN profit_margin_pct >= 0.10 THEN 'Good'
        WHEN profit_margin_pct >= 0.05 THEN 'Fair'
        ELSE 'Poor'
    END as profit_margin_health,
    CASE 
        WHEN repeat_customer_rate >= 0.50 THEN 'Excellent'
        WHEN repeat_customer_rate >= 0.35 THEN 'Good'
        WHEN repeat_customer_rate >= 0.20 THEN 'Fair'
        ELSE 'Poor'
    END as customer_retention_health,
    CASE 
        WHEN avg_days_between_orders <= 30 THEN 'Excellent'
        WHEN avg_days_between_orders <= 60 THEN 'Good'
        WHEN avg_days_between_orders <= 90 THEN 'Fair'
        ELSE 'Poor'
    END as purchase_frequency_health
FROM (
    SELECT 
        (SELECT SUM(total_sales) FROM orders WHERE strftime('%Y', order_date) = strftime('%Y', 'now')) as current_year_revenue,
        (SELECT SUM(total_sales) FROM orders WHERE strftime('%Y', order_date) = strftime('%Y', 'now', '-1 year')) as prev_year_revenue,
        (SUM(CASE WHEN strftime('%Y', order_date) = strftime('%Y', 'now') THEN total_sales ELSE 0 END) - 
         NULLIF(SUM(CASE WHEN strftime('%Y', order_date) = strftime('%Y', 'now', '-1 year') THEN total_sales ELSE 0 END), 0)) / 
        NULLIF(SUM(CASE WHEN strftime('%Y', order_date) = strftime('%Y', 'now', '-1 year') THEN total_sales ELSE 0 END), 0) as total_revenue_growth_rate,
        SUM(total_profit) / SUM(total_sales) as profit_margin_pct,
        COUNT(DISTINCT CASE WHEN order_count > 1 THEN customer_id END) * 1.0 / COUNT(DISTINCT customer_id) as repeat_customer_rate,
        avg_days_between_orders
    FROM (
        SELECT 
            o.*,
            COUNT(*) OVER (PARTITION BY customer_id) as order_count,
            AVG(JULIANDAY(order_date) - LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)) as avg_days_between_orders
        FROM orders o
    ) order_analysis
) business_metrics;