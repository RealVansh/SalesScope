-- 1. Basic Year-over-Year KPI Summary
-- Problem: Show total sales, profit, and quantity for 2023 vs 2024
SELECT 
    YEAR(Order_Date) as year,
    ROUND(SUM(Sales), 2) as total_sales,
    ROUND(SUM(Profit), 2) as total_profit,
    SUM(Quantity) as total_quantity,
    COUNT(DISTINCT Order_ID) as total_orders
FROM Orders
WHERE YEAR(Order_Date) IN (2023, 2024)
GROUP BY YEAR(Order_Date)
ORDER BY year;

-- ===============================================

-- 2. Monthly Sales Trends for Current Year
-- Problem: Show monthly sales performance to identify peak months
SELECT 
    MONTH(Order_Date) as month_num,
    MONTHNAME(Order_Date) as month_name,
    ROUND(SUM(Sales), 2) as monthly_sales,
    ROUND(SUM(Profit), 2) as monthly_profit,
    COUNT(DISTINCT Order_ID) as orders_count
FROM Orders
WHERE YEAR(Order_Date) = 2024
GROUP BY MONTH(Order_Date), MONTHNAME(Order_Date)
ORDER BY month_num;

-- ===============================================

-- 3. Top 10 Product Subcategories by Sales
-- Problem: Identify best-performing product subcategories
SELECT 
    p.Sub_Category,
    ROUND(SUM(o.Sales), 2) as total_sales,
    ROUND(SUM(o.Profit), 2) as total_profit,
    SUM(o.Quantity) as total_quantity,
    ROUND((SUM(o.Profit) / SUM(o.Sales)) * 100, 2) as profit_margin_pct
FROM Orders o
JOIN Products p ON o.Product_ID = p.Product_ID
WHERE YEAR(o.Order_Date) = 2024
GROUP BY p.Sub_Category
ORDER BY total_sales DESC
LIMIT 10;

-- ===============================================

-- 4. Weekly Sales and Profit for Current Year
-- Problem: Show weekly trends with simple above/below average flagging
SELECT 
    WEEK(Order_Date) as week_number,
    ROUND(SUM(Sales), 2) as weekly_sales,
    ROUND(SUM(Profit), 2) as weekly_profit,
    COUNT(DISTINCT Order_ID) as weekly_orders,
    CASE 
        WHEN SUM(Sales) > (SELECT AVG(weekly_avg.sales) FROM 
            (SELECT SUM(Sales) as sales FROM Orders 
             WHERE YEAR(Order_Date) = 2024 GROUP BY WEEK(Order_Date)) weekly_avg)
        THEN 'Above Average'
        ELSE 'Below Average'
    END as performance_flag
FROM Orders
WHERE YEAR(Order_Date) = 2024
GROUP BY WEEK(Order_Date)
ORDER BY week_number;

-- ===============================================

-- 5. Sales Performance by Region
-- Problem: Compare regional sales to identify top markets
SELECT 
    l.Region,
    ROUND(SUM(o.Sales), 2) as total_sales,
    ROUND(SUM(o.Profit), 2) as total_profit,
    COUNT(DISTINCT o.Customer_ID) as unique_customers,
    COUNT(DISTINCT o.Order_ID) as total_orders,
    ROUND(AVG(o.Sales), 2) as avg_order_value
FROM Orders o
JOIN Location l ON o.Postal_Code = l.Postal_Code
WHERE YEAR(o.Order_Date) = 2024
GROUP BY l.Region
ORDER BY total_sales DESC;

-- ===============================================

-- 6. Customer Segment Analysis
-- Problem: Compare performance across Consumer, Corporate, and Home Office segments
SELECT 
    Segment,
    ROUND(SUM(Sales), 2) as total_sales,
    ROUND(SUM(Profit), 2) as total_profit,
    COUNT(DISTINCT Customer_ID) as unique_customers,
    COUNT(DISTINCT Order_ID) as total_orders,
    ROUND(AVG(Sales), 2) as avg_order_value,
    ROUND((SUM(Profit) / SUM(Sales)) * 100, 2) as profit_margin_pct
FROM Orders
WHERE YEAR(Order_Date) = 2024
GROUP BY Segment
ORDER BY total_sales DESC;

-- ===============================================

-- 7. Product Category Performance Comparison
-- Problem: Compare 2024 vs 2023 performance by main categories
SELECT 
    p.Category,
    SUM(CASE WHEN YEAR(o.Order_Date) = 2024 THEN o.Sales ELSE 0 END) as sales_2024,
    SUM(CASE WHEN YEAR(o.Order_Date) = 2023 THEN o.Sales ELSE 0 END) as sales_2023,
    SUM(CASE WHEN YEAR(o.Order_Date) = 2024 THEN o.Profit ELSE 0 END) as profit_2024,
    SUM(CASE WHEN YEAR(o.Order_Date) = 2023 THEN o.Profit ELSE 0 END) as profit_2023
FROM Orders o
JOIN Products p ON o.Product_ID = p.Product_ID
WHERE YEAR(o.Order_Date) IN (2023, 2024)
GROUP BY p.Category
ORDER BY sales_2024 DESC;

-- ===============================================

-- 8. Shipping Mode Analysis
-- Problem: Analyze order distribution and performance by shipping method
SELECT 
    Ship_Mode,
    COUNT(Order_ID) as order_count,
    ROUND(SUM(Sales), 2) as total_sales,
    ROUND(SUM(Profit), 2) as total_profit,
    ROUND(AVG(Sales), 2) as avg_order_value,
    ROUND((COUNT(Order_ID) * 100.0 / (SELECT COUNT(*) FROM Orders WHERE YEAR(Order_Date) = 2024)), 2) as order_percentage
FROM Orders
WHERE YEAR(Order_Date) = 2024
GROUP BY Ship_Mode
ORDER BY order_count DESC;

-- ===============================================

-- 9. Customer Segment Profitability Analysis
-- Problem: Analyze performance by customer segments
WITH segment_performance AS (
    SELECT 
        Segment,
        YEAR(Order_Date) as year,
        SUM(Sales) as total_sales,
        SUM(Profit) as total_profit,
        COUNT(DISTINCT Customer_ID) as unique_customers,
        COUNT(DISTINCT Order_ID) as total_orders,
        AVG(Sales) as avg_order_value
    FROM Orders
    WHERE YEAR(Order_Date) IN (2023, 2024)
    GROUP BY Segment, YEAR(Order_Date)
)
SELECT 
    sp2024.Segment,
    sp2024.total_sales as sales_2024,
    sp2023.total_sales as sales_2023,
    ROUND(((sp2024.total_sales - sp2023.total_sales) / sp2023.total_sales * 100), 2) as sales_growth_pct,
    sp2024.total_profit as profit_2024,
    sp2023.total_profit as profit_2023,
    ROUND((sp2024.total_profit / sp2024.total_sales * 100), 2) as profit_margin_pct_2024,
    sp2024.unique_customers as customers_2024,
    sp2024.avg_order_value as aov_2024,
    ROUND(sp2024.total_sales / SUM(sp2024.total_sales) OVER() * 100, 2) as sales_contribution_pct
FROM segment_performance sp2024
LEFT JOIN segment_performance sp2023 
    ON sp2024.Segment = sp2023.Segment AND sp2023.year = 2023
WHERE sp2024.year = 2024
ORDER BY sp2024.total_sales DESC;

-- ===============================================

-- 10. Order Fulfillment and Shipping Analysis
-- Problem: Analyze shipping performance and its correlation with business metrics
WITH shipping_analysis AS (
    SELECT 
        Ship_Mode,
        Segment,
        SUM(Sales) as total_sales,
        SUM(Profit) as total_profit,
        COUNT(Order_ID) as order_count,
        AVG(Sales) as avg_order_value,
        AVG(DATEDIFF(Ship_Date, Order_Date)) as avg_ship_days,
        ROUND(SUM(Sales) / SUM(SUM(Sales)) OVER() * 100, 2) as sales_share_pct
    FROM Orders
    WHERE YEAR(Order_Date) = 2024 
    AND Ship_Date IS NOT NULL 
    AND Order_Date IS NOT NULL
    GROUP BY Ship_Mode, Segment
)
SELECT 
    Ship_Mode,
    Segment,
    total_sales,
    total_profit,
    order_count,
    ROUND(avg_order_value, 2) as avg_order_value,
    ROUND(avg_ship_days, 1) as avg_shipping_days,
    sales_share_pct,
    ROUND(total_profit / total_sales * 100, 2) as profit_margin_pct
FROM shipping_analysis
ORDER BY Ship_Mode, total_sales DESC;