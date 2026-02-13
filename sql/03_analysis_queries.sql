-- Core Retail Sales Analysis Queries
-- This file contains fundamental business analysis queries for retail sales data

-- ==========================================
-- 1. REVENUE AND SALES ANALYSIS
-- ==========================================

-- Total revenue, profit, and average order value by year
SELECT 
    strftime('%Y', order_date) as order_year,
    COUNT(DISTINCT order_id) as total_orders,
    COUNT(DISTINCT customer_id) as unique_customers,
    ROUND(SUM(total_sales), 2) as total_revenue,
    ROUND(SUM(total_profit), 2) as total_profit,
    ROUND(AVG(total_sales), 2) as average_order_value,
    ROUND(SUM(total_profit) / SUM(total_sales) * 100, 2) as profit_margin_pct
FROM orders
GROUP BY strftime('%Y', order_date)
ORDER BY order_year;

-- Monthly sales trends
SELECT 
    strftime('%Y-%m', order_date) as month,
    COUNT(DISTINCT order_id) as orders,
    ROUND(SUM(total_sales), 2) as revenue,
    ROUND(SUM(total_profit), 2) as profit,
    ROUND(AVG(total_sales), 2) as avg_order_value
FROM orders
GROUP BY strftime('%Y-%m', order_date)
ORDER BY month;

-- Quarterly performance
SELECT 
    strftime('%Y', order_date) as year,
    CASE 
        WHEN CAST(strftime('%m', order_date) AS INTEGER) IN (1,2,3) THEN 'Q1'
        WHEN CAST(strftime('%m', order_date) AS INTEGER) IN (4,5,6) THEN 'Q2'
        WHEN CAST(strftime('%m', order_date) AS INTEGER) IN (7,8,9) THEN 'Q3'
        ELSE 'Q4'
    END as quarter,
    COUNT(DISTINCT order_id) as orders,
    ROUND(SUM(total_sales), 2) as revenue,
    ROUND(SUM(total_profit), 2) as profit
FROM orders
GROUP BY year, quarter
ORDER BY year, quarter;

-- ==========================================
-- 2. PRODUCT PERFORMANCE ANALYSIS
-- ==========================================

-- Top 10 products by revenue
SELECT 
    p.product_name,
    p.category,
    p.subcategory,
    COUNT(DISTINCT oi.order_id) as times_ordered,
    SUM(oi.quantity) as total_quantity,
    ROUND(SUM(oi.sales_amount), 2) as total_revenue,
    ROUND(SUM(oi.profit), 2) as total_profit,
    ROUND(AVG(oi.unit_price), 2) as avg_unit_price,
    ROUND(SUM(oi.profit) / SUM(oi.sales_amount) * 100, 2) as profit_margin_pct
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category, p.subcategory
ORDER BY total_revenue DESC
LIMIT 10;

-- Category and subcategory performance
SELECT 
    p.category,
    p.subcategory,
    COUNT(DISTINCT oi.order_id) as orders,
    COUNT(DISTINCT p.product_id) as unique_products,
    SUM(oi.quantity) as total_quantity,
    ROUND(SUM(oi.sales_amount), 2) as revenue,
    ROUND(SUM(oi.profit), 2) as profit,
    ROUND(SUM(oi.sales_amount) * 100.0 / (SELECT SUM(total_sales) FROM orders), 2) as revenue_share_pct,
    ROUND(SUM(oi.profit) / SUM(oi.sales_amount) * 100, 2) as profit_margin_pct
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category, p.subcategory
ORDER BY revenue DESC;

-- Best and worst performing products by profit margin
SELECT 
    p.product_name,
    p.category,
    p.subcategory,
    SUM(oi.sales_amount) as revenue,
    SUM(oi.profit) as profit,
    ROUND(SUM(oi.profit) / SUM(oi.sales_amount) * 100, 2) as profit_margin_pct,
    COUNT(DISTINCT oi.order_id) as orders
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category, p.subcategory
HAVING SUM(oi.sales_amount) > 100  -- Only include products with meaningful sales
ORDER BY profit_margin_pct DESC
LIMIT 10;

-- ==========================================
-- 3. CUSTOMER ANALYSIS
-- ==========================================

-- Top 10 customers by total spending
SELECT 
    c.customer_name,
    c.segment,
    c.region,
    COUNT(DISTINCT o.order_id) as total_orders,
    COUNT(DISTINCT strftime('%Y', o.order_date)) as years_active,
    MIN(o.order_date) as first_order_date,
    MAX(o.order_date) as last_order_date,
    ROUND(SUM(o.total_sales), 2) as lifetime_value,
    ROUND(SUM(o.total_profit), 2) as lifetime_profit,
    ROUND(AVG(o.total_sales), 2) as avg_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name, c.segment, c.region
HAVING COUNT(DISTINCT o.order_id) >= 1
ORDER BY lifetime_value DESC
LIMIT 10;

-- Customer segment analysis
SELECT 
    segment,
    COUNT(DISTINCT customer_id) as customer_count,
    COUNT(DISTINCT order_id) as total_orders,
    ROUND(SUM(total_sales), 2) as total_revenue,
    ROUND(AVG(total_sales), 2) as avg_order_value,
    ROUND(SUM(total_sales) / COUNT(DISTINCT customer_id), 2) as revenue_per_customer,
    ROUND(COUNT(DISTINCT customer_id) * 100.0 / (SELECT COUNT(*) FROM customers), 2) as customer_share_pct
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.segment
ORDER BY total_revenue DESC;

-- Geographic sales distribution
SELECT 
    region,
    state,
    COUNT(DISTINCT o.order_id) as orders,
    COUNT(DISTINCT c.customer_id) as customers,
    ROUND(SUM(o.total_sales), 2) as revenue,
    ROUND(SUM(o.total_sales) * 100.0 / (SELECT SUM(total_sales) FROM orders), 2) as revenue_share_pct,
    ROUND(AVG(o.total_sales), 2) as avg_order_value
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY region, state
ORDER BY revenue DESC
LIMIT 15;

-- ==========================================
-- 4. ORDER AND SHIPPING ANALYSIS
-- ==========================================

-- Ship mode performance
SELECT 
    ship_mode,
    COUNT(DISTINCT order_id) as orders,
    ROUND(SUM(total_sales), 2) as revenue,
    ROUND(AVG(total_sales), 2) as avg_order_value,
    COUNT(DISTINCT customer_id) as customers,
    ROUND(AVG(JULIANDAY(ship_date) - JULIANDAY(order_date)), 1) as avg_shipping_days
FROM orders
GROUP BY ship_mode
ORDER BY revenue DESC;

-- Order size distribution (number of items per order)
SELECT 
    CASE 
        WHEN total_items = 1 THEN '1 Item'
        WHEN total_items BETWEEN 2 AND 3 THEN '2-3 Items'
        WHEN total_items BETWEEN 4 AND 5 THEN '4-5 Items'
        WHEN total_items BETWEEN 6 AND 10 THEN '6-10 Items'
        ELSE '10+ Items'
    END as order_size_category,
    COUNT(*) as order_count,
    COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders) as percentage
FROM (
    SELECT 
        order_id,
        SUM(quantity) as total_items
    FROM order_items
    GROUP BY order_id
) size_distribution
GROUP BY order_size_category
ORDER BY order_count DESC;