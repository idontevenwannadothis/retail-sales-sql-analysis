-- Data Loading Instructions
-- This file contains instructions for setting up the database and loading data

-- Step 1: Create the database
-- For SQLite:
-- sqlite3 retail_sales.db

-- For PostgreSQL:
-- CREATE DATABASE retail_sales;
-- \c retail_sales

-- For MySQL:
-- CREATE DATABASE retail_sales;
-- USE retail_sales;

-- Step 2: Run the table creation script
-- .read sql/01_create_tables.sql

-- Step 3: Create a temporary table for raw CSV import (SQLite example)
-- For SQLite:
CREATE TEMP TABLE superstore_raw (
    Row_ID INTEGER,
    Order_ID TEXT,
    Order_Date TEXT,
    Ship_Date TEXT,
    Ship_Mode TEXT,
    Customer_ID TEXT,
    Customer_Name TEXT,
    Segment TEXT,
    Country TEXT,
    City TEXT,
    State TEXT,
    Postal_Code TEXT,
    Region TEXT,
    Product_ID TEXT,
    Category TEXT,
    "Sub-Category" TEXT,
    Product_Name TEXT,
    Sales REAL,
    Quantity INTEGER,
    Discount REAL,
    Profit REAL
);

-- Step 4: Import CSV data
-- For SQLite:
.mode csv
.import data/superstore.csv superstore_raw

-- For PostgreSQL:
-- COPY superstore_raw FROM 'data/superstore.csv' WITH CSV HEADER;

-- For MySQL:
-- LOAD DATA INFILE 'data/superstore.csv' 
-- INTO TABLE superstore_raw
-- FIELDS TERMINATED BY ',' 
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS;

-- Step 5: Run data cleaning and loading script
-- .read sql/02_data_cleaning.sql

-- Step 6: Verify data loading
SELECT 
    (SELECT COUNT(*) FROM customers) as total_customers,
    (SELECT COUNT(*) FROM products) as total_products,
    (SELECT COUNT(*) FROM orders) as total_orders,
    (SELECT COUNT(*) FROM order_items) as total_order_items;