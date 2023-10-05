-- Identify the tables in the database that contain information about the storage facilities and the items stored in them.
SELECT w.warehouseCode, w.warehouseName, COUNT(p.productCode) AS TotalProducts
FROM Warehouses w
LEFT JOIN Products p ON w.warehouseCode = p.warehouseCode
GROUP BY w.warehouseCode, w.warehouseName;

-- Query to identify items and their storage locations.
SELECT p.productName, p.quantityInStock, w.warehouseName AS warehouseName
FROM Products p
JOIN orderdetails od ON p.productCode = od.productCode
JOIN Warehouses w ON p.warehouseCode = w.warehouseCode
LIMIT 5000;

-- Query to select the warehouse with the least orders
SELECT w.warehouseCode, w.warehouseName, COUNT(od.orderNumber) AS TotalOrders
FROM Warehouses w
LEFT JOIN Products p ON w.warehouseCode = p.warehouseCode
LEFT JOIN orderdetails od ON p.productCode = od.productCode
GROUP BY w.warehouseCode, w.warehouseName
ORDER BY TotalOrders ASC
LIMIT 1;

-- show the warehouse with the most orders
SELECT w.warehouseCode, w.warehouseName, COUNT(od.orderNumber) AS TotalOrders
FROM Warehouses w
LEFT JOIN Products p ON w.warehouseCode = p.warehouseCode
LEFT JOIN orderdetails od ON p.productCode = od.productCode
GROUP BY w.warehouseCode, w.warehouseName
ORDER BY TotalOrders DESC
LIMIT 1;

-- Total number of orders for each warehouse
SELECT w.warehouseCode, w.warehouseName, SUM(od.quantityOrdered) AS TotalOrders
FROM Warehouses w
LEFT JOIN Products p ON w.warehouseCode = p.warehouseCode
LEFT JOIN orderdetails od ON p.productCode = od.productCode
GROUP BY w.warehouseCode, w.warehouseName;

-- List of Products and Their Storage Locations
SELECT p.productCode, p.productName, w.warehouseName
FROM Products p
JOIN Warehouses w ON p.warehouseCode = p.warehouseCode;

-- Calculate Warehouse Product Count Utilization
SELECT w.warehouseName, COUNT(p.productCode) AS ProductCount
FROM Warehouses w
LEFT JOIN Products p ON w.warehouseCode = p.warehouseCode
GROUP BY w.warehouseName;

-- Calculate Sales Figures by product
SELECT p.productCode, p.productName, SUM(od.quantityOrdered) AS TotalSales
FROM Products p
JOIN orderdetails od ON p.productCode = od.productCode
GROUP BY p.productCode, p.productName;

-- Products with consistently high quantity levels but low orders
WITH AverageQuantity AS (
    SELECT p.productCode, p.productName, AVG(p.quantityInStock) AS AvgQuantity
    FROM Products p
    GROUP BY p.productCode, p.productName
),
AverageOrders AS (
    SELECT p.productCode, p.productName, AVG(od.quantityOrdered) AS AvgOrders
    FROM Products p
    LEFT JOIN orderdetails od ON p.productCode = od.productCode
    GROUP BY p.productCode, p.productName
)
SELECT aq.productCode, aq.productName, aq.AvgQuantity, ao.AvgOrders
FROM AverageQuantity aq
LEFT JOIN AverageOrders ao ON aq.productCode = ao.productCode
WHERE aq.AvgQuantity > IFNULL(ao.AvgOrders, 0)
ORDER BY ao.AvgOrders ASC;

-- product with high orders but low quantity levels, leading to potential stockouts
WITH AverageQuantity AS (
    SELECT p.productCode, p.productName, AVG(p.quantityInStock) AS AvgQuantity
    FROM Products p
    GROUP BY p.productCode, p.productName
),
AverageOrders AS (
    SELECT p.productCode, p.productName, AVG(od.quantityOrdered) AS AvgOrders
    FROM Products p
    LEFT JOIN orderdetails od ON p.productCode = od.productCode
    GROUP BY p.productCode, p.productName
)
SELECT aq.productCode, aq.productName, aq.AvgQuantity, ao.AvgOrders
FROM AverageQuantity aq
LEFT JOIN AverageOrders ao ON aq.productCode = ao.productCode
WHERE aq.AvgQuantity < IFNULL(ao.AvgOrders, 0)
ORDER BY ao.AvgOrders DESC;

-- Top 5 products with the highest sales figures
WITH ProductSales AS (
    SELECT p.productCode, p.productName, SUM(od.quantityOrdered) AS TotalSales
    FROM Products p
    LEFT JOIN orderdetails od ON p.productCode = od.productCode
    GROUP BY p.productCode, p.productName
)
SELECT productCode, productName, TotalSales
FROM ProductSales
ORDER BY TotalSales DESC
LIMIT 5;

-- Top 5 products with the least sales figures
WITH ProductSales AS (
    SELECT p.productCode, p.productName, SUM(od.quantityOrdered) AS TotalSales
    FROM Products p
    LEFT JOIN orderdetails od ON p.productCode = od.productCode
    GROUP BY p.productCode, p.productName
)
SELECT productCode, productName, TotalSales
FROM ProductSales
ORDER BY TotalSales ASC
LIMIT 5;

--  products that have not sold at all or have very limited sales
WITH ProductSales AS (
    SELECT p.productCode, p.productName, COALESCE(SUM(od.quantityOrdered), 0) AS TotalSales
    FROM Products p
    LEFT JOIN orderdetails od ON p.productCode = od.productCode
    GROUP BY p.productCode, p.productName
)
SELECT productCode, productName, TotalSales
FROM ProductSales
WHERE TotalSales <= 500; -- Adjust the threshold as needed

-- products that consistently perform well over time
WITH ProductSalesByYear AS (
    SELECT
        p.productCode,
        p.productName,
        YEAR(o.orderDate) AS OrderYear,
        SUM(od.quantityOrdered) AS TotalSales
    FROM
        Products p
    LEFT JOIN
        orderdetails od ON p.productCode = od.productCode
    LEFT JOIN
        orders o ON od.orderNumber = o.orderNumber
    GROUP BY
        p.productCode,
        p.productName,
        OrderYear
),
AverageProductSales AS (
    SELECT
        productCode,
        productName,
        AVG(TotalSales) AS AvgSales
    FROM
        ProductSalesByYear
    GROUP BY
        productCode,
        productName
)
SELECT
    p.productCode,
    p.productName,
    aps.AvgSales AS AverageSales
FROM
    Products p
LEFT JOIN
    AverageProductSales aps ON p.productCode = aps.productCode
ORDER BY
    aps.AvgSales DESC
LIMIT 5; -- Limit to the top 5 products with the highest average sales

-- products that consistently perform poorly over time.
WITH ProductSalesByYear AS (
    SELECT
        p.productCode,
        p.productName,
        YEAR(o.orderDate) AS OrderYear,
        SUM(od.quantityOrdered) AS TotalSales
    FROM
        Products p
    LEFT JOIN
        orderdetails od ON p.productCode = od.productCode
    LEFT JOIN
        orders o ON od.orderNumber = o.orderNumber
    GROUP BY
        p.productCode,
        p.productName,
        OrderYear
),
AverageProductSales AS (
    SELECT
        productCode,
        productName,
        AVG(TotalSales) AS AvgSales
    FROM
        ProductSalesByYear
    GROUP BY
        productCode,
        productName
)
SELECT
    p.productCode,
    p.productName,
    aps.AvgSales AS AverageSales
FROM
    Products p
LEFT JOIN
    AverageProductSales aps ON p.productCode = aps.productCode
ORDER BY
    aps.AvgSales ASC
LIMIT 5; -- Limit to the top 5 products with the lowest average sales

-- How efficiently are the storage facilities being utilized in terms of inventory levels?
SELECT
    sf.warehouseName,
    sf.warehousePctCap,
    SUM(p.quantityInStock) AS TotalInventory,
    CONCAT(FORMAT((SUM(p.quantityInStock) / sf.warehousePctCap) / 100, 2), '%') AS UtilizationPercentage
FROM
    Warehouses sf
LEFT JOIN
    Products p ON sf.warehouseCode = p.warehouseCode
GROUP BY
    sf.warehouseName,
    sf.warehousePctCap
ORDER BY
    UtilizationPercentage DESC;

-- storage facilities with excess capacity or underutilized space
WITH FacilityCapacity AS (
    SELECT
        w.warehouseCode,
        w.warehouseName,
        w.warehousePctCap,
        SUM(p.quantityInStock) AS TotalInventory
    FROM
        Warehouses w
    LEFT JOIN
        Products p ON w.warehouseCode = p.warehouseCode
    GROUP BY
        w.warehouseCode, w.warehouseName, w.warehousePctCap
),
FacilityOrders AS (
    SELECT
        w.warehouseCode,
        SUM(od.quantityOrdered) AS TotalOrders
    FROM
        Warehouses w
    LEFT JOIN
        Products p ON w.warehouseCode = p.warehouseCode
    LEFT JOIN
        orderdetails od ON p.productCode = od.productCode
    GROUP BY
        w.warehouseCode
)
SELECT
    fc.warehouseName,
    fc.TotalInventory,
    IFNULL(fo.TotalOrders, 0) AS TotalOrders,
    CONCAT(
        ROUND(
            (fc.warehousePctCap - ((fc.TotalInventory - IFNULL(fo.TotalOrders, 0)) / fc.warehousePctCap / 100)),
            2
        ),
        '%'
    ) AS RemainingCapacityPercentage
FROM
    FacilityCapacity fc
LEFT JOIN
    FacilityOrders fo ON fc.warehouseCode = fo.warehouseCode
HAVING
    RemainingCapacityPercentage > 0
ORDER BY
    RemainingCapacityPercentage DESC;

-- verage product turnover rate for different product categories
WITH ProductCategory AS (
    SELECT
        p.productLine,
        p.productCode,
        p.productName,
        AVG(p.quantityInStock) AS AvgInventory,
        AVG(od.quantityOrdered) AS AvgSales
    FROM
        Products p
    LEFT JOIN
        orderdetails od ON p.productCode = od.productCode
    GROUP BY
        p.productLine, p.productCode, p.productName
)
SELECT
    productLine,
    ROUND(SUM(AvgSales) / SUM(AvgInventory), 2) AS AvgProductTurnoverRate
FROM
    ProductCategory
GROUP BY
    productLine
ORDER BY
    AvgProductTurnoverRate DESC;

-- identify slow-moving or obsolete inventory
SELECT
    p.productCode,
    p.productName,
    p.productDescription,
    p.quantityInStock,
    p.buyPrice,
    p.MSRP,
    MAX(o.orderDate) AS LastSaleDate,
    SUM(od.quantityOrdered) AS TotalSales
FROM
    Products p
LEFT JOIN
    orderdetails od ON p.productCode = od.productCode
LEFT JOIN
    orders o ON od.orderNumber = o.orderNumber
GROUP BY
    p.productCode, p.productName, p.productDescription, p.quantityInStock, p.buyPrice, p.MSRP
HAVING
    LastSaleDate IS NULL OR (LastSaleDate < DATE_SUB(CURDATE(), INTERVAL 365 DAY) AND TotalSales < 10)
ORDER BY
    LastSaleDate ASC
LIMIT 1;

-- costs associated with operating each warehouse
SELECT
    w.warehouseCode,
    w.warehouseName,
    SUM(p.buyPrice * p.quantityInStock) AS TotalCost
FROM
    warehouses w
JOIN
    Products p ON w.warehouseCode = p.warehouseCode
GROUP BY
    w.warehouseCode, w.warehouseName
ORDER BY
    TotalCost DESC;

-- Calculate Total Sales for Each Product
SELECT
    p.productCode,
    p.productName,
    SUM(od.quantityOrdered * od.priceEach) AS TotalSales
FROM
    Products p
LEFT JOIN
    orderdetails od ON p.productCode = od.productCode
GROUP BY
    p.productCode, p.productName

















