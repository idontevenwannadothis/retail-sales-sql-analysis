-- Data Cleaning and Loading Script
-- This script handles data import from CSV and performs cleaning operations

-- Import data from CSV and populate normalized tables

-- Clear existing data
DELETE FROM order_items;
DELETE FROM orders;
DELETE FROM customers;
DELETE FROM products;

-- Load customers (unique customers from source data)
INSERT INTO customers (customer_id, customer_name, segment, country, city, state, postal_code, region)
SELECT DISTINCT 
    Customer_ID,
    Customer_Name,
    Segment,
    Country,
    City,
    State,
    Postal_Code,
    Region
FROM superstore_raw
WHERE Customer_ID IS NOT NULL AND Customer_ID != '';

-- Load products (unique products from source data)
INSERT INTO products (product_id, product_name, category, subcategory)
SELECT DISTINCT 
    Product_ID,
    Product_Name,
    Category,
    "Sub-Category"
FROM superstore_raw
WHERE Product_ID IS NOT NULL AND Product_ID != '';

-- Load orders (unique orders from source data)
INSERT INTO orders (order_id, customer_id, order_date, ship_date, ship_mode, total_sales, total_profit)
SELECT 
    Order_ID,
    Customer_ID,
    DATE(Order_Date) as order_date,
    DATE(Ship_Date) as ship_date,
    Ship_Mode,
    SUM(Sales) as total_sales,
    SUM(Profit) as total_profit
FROM superstore_raw
WHERE Order_ID IS NOT NULL AND Order_ID != ''
GROUP BY Order_ID, Customer_ID, Order_Date, Ship_Date, Ship_Mode;

-- Load order_items (detailed line items)
INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount, sales_amount, profit)
SELECT 
    Order_ID,
    Product_ID,
    Quantity,
    CASE WHEN Quantity > 0 THEN Sales / Quantity ELSE 0 END as unit_price,
    Discount,
    Sales,
    Profit
FROM superstore_raw
WHERE Order_ID IS NOT NULL AND Order_ID != '' 
AND Product_ID IS NOT NULL AND Product_ID != '';

-- Data quality checks and cleaning
-- Remove records with invalid dates
DELETE FROM orders WHERE order_date > ship_date OR order_date > CURRENT_DATE;

-- Remove negative quantities (shouldn't exist but just in case)
UPDATE order_items SET quantity = 1 WHERE quantity <= 0;

-- Ensure discount is within valid range
UPDATE order_items SET discount = 0 WHERE discount < 0 OR discount > 1;

-- Handle NULL values
UPDATE orders SET ship_mode = 'Standard Class' WHERE ship_mode IS NULL OR ship_mode = '';
UPDATE customers SET segment = 'Consumer' WHERE segment IS NULL OR segment = '';

-- Update order totals based on order_items to ensure consistency
UPDATE orders 
SET total_sales = (
    SELECT COALESCE(SUM(sales_amount), 0) 
    FROM order_items 
    WHERE order_items.order_id = orders.order_id
),
total_profit = (
    SELECT COALESCE(SUM(profit), 0) 
    FROM order_items 
    WHERE order_items.order_id = orders.order_id
);

-- Create a view for easy analysis (denormalized view)
CREATE VIEW sales_analysis AS
SELECT 
    o.order_id,
    o.customer_id,
    c.customer_name,
    c.segment,
    c.region,
    c.city,
    c.state,
    o.order_date,
    o.ship_date,
    o.ship_mode,
    oi.product_id,
    p.product_name,
    p.category,
    p.subcategory,
    oi.quantity,
    oi.unit_price,
    oi.discount,
    oi.sales_amount,
    oi.profit
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id;