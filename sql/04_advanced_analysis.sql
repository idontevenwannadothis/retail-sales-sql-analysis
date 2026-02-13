-- Advanced Retail Analysis: RFM, Cohort Analysis, and Retention
-- This file contains sophisticated analytical techniques for business insights

-- ==========================================
-- 1. RFM ANALYSIS (Recency, Frequency, Monetary)
-- ==========================================

-- Calculate RFM metrics for each customer
WITH customer_rfm AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        c.segment,
        c.region,
        -- Recency: Days since last order (lower is better)
        JULIANDAY('now') - JULIANDAY(MAX(o.order_date)) as recency_days,
        -- Frequency: Number of orders
        COUNT(DISTINCT o.order_id) as frequency,
        -- Monetary: Total spending
        ROUND(SUM(o.total_sales), 2) as monetary_value,
        -- Additional metrics
        MIN(o.order_date) as first_order_date,
        MAX(o.order_date) as last_order_date,
        ROUND(AVG(o.total_sales), 2) as avg_order_value
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name, c.segment, c.region
),
rfm_quartiles AS (
    SELECT 
        customer_id,
        customer_name,
        segment,
        region,
        recency_days,
        frequency,
        monetary_value,
        first_order_date,
        last_order_date,
        avg_order_value,
        -- Calculate RFM scores (1-5 scale)
        CASE 
            WHEN recency_days <= (SELECT recency_days FROM (SELECT recency_days, NTILE(5) OVER (ORDER BY recency_days ASC) as percentile FROM customer_rfm) WHERE percentile = 1 ORDER BY recency_days DESC LIMIT 1) THEN 5
            WHEN recency_days <= (SELECT recency_days FROM (SELECT recency_days, NTILE(5) OVER (ORDER BY recency_days ASC) as percentile FROM customer_rfm) WHERE percentile = 2 ORDER BY recency_days DESC LIMIT 1) THEN 4
            WHEN recency_days <= (SELECT recency_days FROM (SELECT recency_days, NTILE(5) OVER (ORDER BY recency_days ASC) as percentile FROM customer_rfm) WHERE percentile = 3 ORDER BY recency_days DESC LIMIT 1) THEN 3
            WHEN recency_days <= (SELECT recency_days FROM (SELECT recency_days, NTILE(5) OVER (ORDER BY recency_days ASC) as percentile FROM customer_rfm) WHERE percentile = 4 ORDER BY recency_days DESC LIMIT 1) THEN 2
            ELSE 1
        END as recency_score,
        -- Simplified frequency score based on number of orders
        CASE 
            WHEN frequency >= 10 THEN 5
            WHEN frequency >= 7 THEN 4
            WHEN frequency >= 4 THEN 3
            WHEN frequency >= 2 THEN 2
            ELSE 1
        END as frequency_score,
        -- Simplified monetary score
        CASE 
            WHEN monetary_value >= 5000 THEN 5
            WHEN monetary_value >= 2500 THEN 4
            WHEN monetary_value >= 1000 THEN 3
            WHEN monetary_value >= 500 THEN 2
            ELSE 1
        END as monetary_score
    FROM customer_rfm
)
SELECT 
    customer_id,
    customer_name,
    segment,
    region,
    recency_days,
    frequency,
    monetary_value,
    recency_score,
    frequency_score,
    monetary_score,
    (recency_score * 100) + (frequency_score * 10) + monetary_score as rfm_combined_score,
    CASE 
        WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
        WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Loyal Customers'
        WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'New Customers'
        WHEN recency_score <= 2 AND frequency_score >= 3 THEN 'At Risk'
        WHEN recency_score <= 2 AND frequency_score <= 2 AND monetary_score <= 2 THEN 'Lost'
        ELSE 'Others'
    END as customer_segment,
    first_order_date,
    last_order_date,
    avg_order_value
FROM rfm_quartiles
ORDER BY rfm_combined_score DESC;

-- ==========================================
-- 2. COHORT ANALYSIS (Customer Retention)
-- ==========================================

-- Monthly cohort retention analysis
WITH customer_cohorts AS (
    SELECT 
        c.customer_id,
        DATE(MIN(o.order_date), 'start of month') as cohort_month,
        DATE(o.order_date, 'start of month') as order_month,
        JULIANDAY(DATE(o.order_date, 'start of month')) - JULIANDAY(DATE(MIN(o.order_date), 'start of month')) as months_since_first
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, DATE(o.order_date, 'start of month')
),
cohort_sizes AS (
    SELECT 
        cohort_month,
        COUNT(DISTINCT customer_id) as cohort_size
    FROM (
        SELECT DISTINCT customer_id, cohort_month
        FROM customer_cohorts
    ) base_customers
    GROUP BY cohort_month
),
retention_table AS (
    SELECT 
        cc.cohort_month,
        cc.months_since_first,
        COUNT(DISTINCT cc.customer_id) as active_customers
    FROM customer_cohorts cc
    GROUP BY cc.cohort_month, cc.months_since_first
)
SELECT 
    ct.cohort_month,
    cs.cohort_size,
    rt.months_since_first,
    rt.active_customers,
    ROUND(rt.active_customers * 100.0 / cs.cohort_size, 2) as retention_percentage
FROM retention_table rt
JOIN cohort_sizes cs ON rt.cohort_month = cs.cohort_month
JOIN (SELECT DISTINCT cohort_month FROM customer_cohorts) ct ON rt.cohort_month = ct.cohort_month
WHERE rt.months_since_first <= 12  -- First 12 months
ORDER BY ct.cohort_month, rt.months_since_first;

-- ==========================================
-- 3. REPEAT PURCHASE ANALYSIS
-- ==========================================

-- Time between purchases analysis
WITH purchase_intervals AS (
    SELECT 
        o.customer_id,
        o.order_date,
        LAG(o.order_date) OVER (PARTITION BY o.customer_id ORDER BY o.order_date) as previous_order_date,
        JULIANDAY(o.order_date) - JULIANDAY(LAG(o.order_date) OVER (PARTITION BY o.customer_id ORDER BY o.order_date)) as days_between_orders,
        ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_date) as order_number
    FROM orders o
)
SELECT 
    customer_id,
    COUNT(*) as total_orders,
    COUNT(*) - 1 as repeat_purchases,
    ROUND(AVG(days_between_orders), 1) as avg_days_between_orders,
    MIN(days_between_orders) as min_days_between_orders,
    MAX(days_between_orders) as max_days_between_orders,
    CASE 
        WHEN COUNT(*) >= 5 THEN 'High Frequency'
        WHEN COUNT(*) >= 3 THEN 'Medium Frequency'
        WHEN COUNT(*) >= 2 THEN 'Low Frequency'
        ELSE 'Single Purchase'
    END as purchase_frequency_segment
FROM purchase_intervals
GROUP BY customer_id
HAVING COUNT(*) >= 1
ORDER BY total_orders DESC;

-- Repeat purchase rate by segment
WITH repeat_customers AS (
    SELECT 
        c.customer_id,
        c.segment,
        COUNT(DISTINCT o.order_id) as total_orders,
        CASE WHEN COUNT(DISTINCT o.order_id) > 1 THEN 1 ELSE 0 END as is_repeat_customer
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.segment
)
SELECT 
    segment,
    COUNT(*) as total_customers,
    SUM(is_repeat_customer) as repeat_customers,
    ROUND(SUM(is_repeat_customer) * 100.0 / COUNT(*), 2) as repeat_purchase_rate,
    ROUND(AVG(total_orders), 2) as avg_orders_per_customer
FROM repeat_customers
GROUP BY segment
ORDER BY repeat_purchase_rate DESC;

-- ==========================================
-- 4. PRODUCT AFFINITY ANALYSIS
-- ==========================================

-- Products frequently bought together (Market Basket Analysis)
WITH product_pairs AS (
    SELECT 
        a.product_id as product_a,
        b.product_id as product_b,
        a.order_id
    FROM order_items a
    JOIN order_items b ON a.order_id = b.order_id AND a.product_id < b.product_id
),
pair_frequency AS (
    SELECT 
        product_a,
        product_b,
        COUNT(DISTINCT order_id) as times_bought_together
    FROM product_pairs
    GROUP BY product_a, product_b
    HAVING COUNT(DISTINCT order_id) >= 3  -- Only show pairs bought together at least 3 times
),
product_frequency AS (
    SELECT 
        product_id,
        COUNT(DISTINCT order_id) as total_times_ordered
    FROM order_items
    GROUP BY product_id
)
SELECT 
    pa.product_a,
    p1.product_name as product_a_name,
    p1.category as product_a_category,
    pa.product_b,
    p2.product_name as product_b_name,
    p2.category as product_b_category,
    pa.times_bought_together,
    pf1.total_times_ordered as product_a_orders,
    pf2.total_times_ordered as product_b_orders,
    ROUND(pa.times_bought_together * 100.0 / pf1.total_times_ordered, 2) as affinity_pct_a,
    ROUND(pa.times_bought_together * 100.0 / pf2.total_times_ordered, 2) as affinity_pct_b
FROM pair_frequency pa
JOIN product_frequency pf1 ON pa.product_a = pf1.product_id
JOIN product_frequency pf2 ON pa.product_b = pf2.product_id
JOIN products p1 ON pa.product_a = p1.product_id
JOIN products p2 ON pa.product_b = p2.product_id
ORDER BY pa.times_bought_together DESC
LIMIT 15;

-- ==========================================
-- 5. INVENTORY ANALYSIS
-- ==========================================

-- Slow-moving inventory analysis
WITH product_sales_timeline AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.category,
        p.subcategory,
        oi.order_id,
        o.order_date,
        oi.quantity,
        oi.sales_amount,
        CASE 
            WHEN o.order_date >= DATE('now', '-6 months') THEN 'Last 6 Months'
            WHEN o.order_date >= DATE('now', '-12 months') THEN '6-12 Months'
            WHEN o.order_date >= DATE('now', '-24 months') THEN '12-24 Months'
            ELSE '24+ Months'
        END as time_period
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    LEFT JOIN orders o ON oi.order_id = o.order_id
),
product_performance AS (
    SELECT 
        product_id,
        product_name,
        category,
        subcategory,
        COUNT(DISTINCT order_id) as total_orders,
        COALESCE(SUM(quantity), 0) as total_quantity,
        COALESCE(SUM(sales_amount), 0) as total_revenue,
        COALESCE(SUM(sales_amount), 0) / NULLIF(COUNT(DISTINCT order_id), 0) as avg_revenue_per_order,
        MAX(order_date) as last_sale_date,
        JULIANDAY('now') - JULIANDAY(MAX(order_date)) as days_since_last_sale
    FROM product_sales_timeline
    GROUP BY product_id, product_name, category, subcategory
)
SELECT 
    product_name,
    category,
    subcategory,
    total_orders,
    total_quantity,
    ROUND(total_revenue, 2) as total_revenue,
    ROUND(avg_revenue_per_order, 2) as avg_revenue_per_order,
    days_since_last_sale,
    CASE 
        WHEN total_orders = 0 THEN 'Never Sold'
        WHEN days_since_last_sale > 365 THEN 'Slow Moving (1+ year)'
        WHEN days_since_last_sale > 180 THEN 'Slow Moving (6+ months)'
        WHEN days_since_last_sale > 90 THEN 'Moderate Activity'
        WHEN days_since_last_sale <= 30 THEN 'Fast Moving'
        ELSE 'Normal Activity'
    END as inventory_status
FROM product_performance
ORDER BY days_since_last_sale DESC NULLS LAST, total_revenue DESC;