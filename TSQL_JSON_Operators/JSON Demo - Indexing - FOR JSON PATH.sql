SET NOCOUNT ON;
-- Need AdventureWorks2025?
-- Visit https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure

USE AdventureWorks2025

/*
 ┌---------------┐     ┌------------------------┐    ┌------------------------┐
 | Person.Person |--01<| Sales.SalesOrderHeader |--1<| Sales.SalesOrderDetail |
 └---------------┘     └------------------------┘    └------------------------┘
*/

SELECT per.BusinessEntityID, per.FirstName, per.LastName
    , '|' AS '|', soh.SalesOrderNumber, soh.OrderDate, soh.TotalDue
    , '|' AS '|', sod.ProductID, sod.OrderQty, sod.UnitPrice
FROM Person.Person per
  INNER JOIN Sales.SalesOrderHeader soh
      ON soh.CustomerID = per.BusinessEntityID
    INNER JOIN Sales.SalesOrderDetail sod
        ON soh.SalesOrderID = sod.SalesOrderID
ORDER BY per.BusinessEntityID, soh.SalesOrderID, sod.UnitPrice DESC

-------------------------------------------------------------------------------------------------

-- I want one row per customer, 
--      with JSON content of all the customer orders,
--           indented with the products per order

-------------------------------------------------------------------------------------------------

-- Let's group products together within one order...
-- So for example, on BusinessEntityID 11000, 
--    the 5 rows of SalesOrderNumber SO57418 should be one row with a JSON of 5 products

;WITH cte(BusinessEntityID, FirstName, LastName, [|], SalesOrderNumber, OrderDate, TotalDue, [||], Products)
AS
(
    SELECT TOP 100 PERCENT per.BusinessEntityID, per.FirstName, per.LastName
        , '|' AS '|', soh.SalesOrderNumber, soh.OrderDate, soh.TotalDue
        , '||' AS '||'
        , (
            SELECT 
                sod.ProductID, sod.OrderQty, sod.UnitPrice
            FROM Sales.SalesOrderDetail sod
            WHERE sod.SalesOrderID = soh.SalesOrderID  --<-- a new subquery with a WHERE join
            FOR JSON PATH , WITHOUT_ARRAY_WRAPPER    --<-- FOR JSON PATH keyword
           ) AS Products
    FROM Person.Person per
      INNER JOIN Sales.SalesOrderHeader soh
          ON soh.CustomerID = per.BusinessEntityID
                                                       --<-- an INNER JOIN is lost
    ORDER BY per.BusinessEntityID, soh.SalesOrderID
)
SELECT *
    , ISJSON(Products) AS [ISJSON(Products)] 
    , TRY_CONVERT(json, Products) AS Products_Json
FROM cte

-- What happens if I use "WITHOUT_ARRAY_WRAPPER" ? Compare the JSON viewer
-- FOR JSON PATH groups multiple rows in an array surrounded by array brackets [].
-- Specifying WITHOUT_ARRAY_WRAPPER makes it look like an ungrouped list of objects,
-- but it is actually a STRING.

-- Why are some values not JSON?
SELECT CONVERT(varchar(300), 0x4974206973206173206C6F6E672061732074686520637573746F6D657220686164206F6E6C79206F6E65206F726465722E20227B7D2C7B7D22206973206E6F742076616C6964204A534F4E)

-- Notice that "Products" is a column right now.
-------------------------------------------------------------------------------------------------

-- But let's further group by person...

;WITH cte(BusinessEntityID, FirstName, LastName, [|], Orders)
AS
(
    SELECT TOP 100 PERCENT
        per.BusinessEntityID, per.FirstName, per.LastName, '|' AS '|'
        , (
            SELECT
                soh.SalesOrderID, soh.SalesOrderNumber, soh.OrderDate, soh.TotalDue
                , (
                    SELECT
                        sod.ProductID,
                        sod.OrderQty,
                        sod.UnitPrice
                    FROM Sales.SalesOrderDetail sod
                    WHERE sod.SalesOrderID = soh.SalesOrderID  --<-- a new subquery with a WHERE join
                    FOR JSON PATH --, WITHOUT_ARRAY_WRAPPER    --<-- FOR JSON PATH keyword
                  ) AS OrderDetails
            FROM Sales.SalesOrderHeader soh
            WHERE soh.CustomerID = per.BusinessEntityID        --<-- a new subquery with a WHERE join
            FOR JSON PATH --, WITHOUT_ARRAY_WRAPPER            --<-- FOR JSON PATH keyword
          ) AS Orders
    FROM Person.Person per
                                                               --<-- both INNER JOINs are lost
    ORDER BY 5 DESC
)
SELECT *
    , ISJSON(Orders) AS [ISJSON(Orders)]
    , TRY_CONVERT(json, Orders) AS Orders_JSON
FROM cte 
ORDER BY BusinessEntityID DESC

-- Four things to notice:
-- 1. What is ORDER BY 5 ?
--    It is to order by whatever is in the fifth column. 
--    It doesn't have a column name like "Orders" at compile time. 
--    I cheated to ensure data showed up in the initial results.

-- 2. Too many rows came back. (Scroll down to bottom)
--    Why? 
SELECT CONVERT(varchar(300), 0x546865206C6F7373206F662074686520494E4E4552204A4F494E2063617573657320637573746F6D6572732077686F206E65766572206F7264657220746F2061707065617220696E20746865206C6973742E)
--    How to fix?
SELECT CONVERT(varchar(300), 0x416674657220746865206F757465722046524F4D2C2061646420612057484552452045584953545320746F206C6F6361746520437573746F6D65727320696E207468652053616C65734F72646572486561646572207461626C65)

-- 3. What effect does "WITHOUT_ARRAY_WRAPPER" have now? 
--    Which (if either) will ruin the ISJSON?

-- 4. "Products" now became a property of the JSON rather than a column name


--------------------------------------------------------

-- A proper array using FOR JSON PATH
;WITH cte(CustomerID, SalesOrderNumbers)
AS
(
    SELECT p.BusinessEntityID AS CustomerID
        , (
            SELECT  
                JSON_QUERY(
                    CONCAT(
                        '['
                        , STRING_AGG(
                            CONCAT('"', soh.SalesOrderNumber, '"'),
                            ',')
                        ,']'
                    )
                ) AS [SalesOrderNumber]
            FROM Sales.SalesOrderHeader AS soh
            WHERE soh.CustomerID = c.CustomerID
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS SalesOrderNumbers
    FROM Person.Person AS p
      INNER JOIN Sales.Customer AS c
          ON p.BusinessEntityID = c.PersonID
)
SELECT * 
    , ISJSON(SalesOrderNumbers) AS [ISJSON(SalesOrderNumbers)]
    , TRY_CONVERT(json, SalesOrderNumbers) AS SalesOrderNumbers_JSON
FROM cte



-- But when presented lower than the root-level, could be clumsy to read
;WITH cte(CustomerID, Orders)
AS
(
    SELECT per.BusinessEntityID AS CustomerID
        , (
            SELECT
                soh.SalesOrderID, soh.SalesOrderNumber, soh.OrderDate, soh.TotalDue
                , (
                    SELECT  
                        JSON_QUERY(
                            CONCAT(
                                '['
                                , STRING_AGG(
                                    CONCAT('"', sod.ProductID, '"'),
                                    ',')
                                ,']'
                            )
                        ) AS ProductIDs
                    FROM Sales.SalesOrderDetail AS sod
                    WHERE sod.SalesOrderID = soh.SalesOrderID
                    FOR JSON PATH  --, WITHOUT_ARRAY_WRAPPER --<-- FOR JSON PATH keyword
                  ) AS OrderDetails
            FROM Sales.SalesOrderHeader soh
            WHERE soh.CustomerID = per.BusinessEntityID        --<-- a new subquery with a WHERE join
            FOR JSON PATH --, WITHOUT_ARRAY_WRAPPER            --<-- FOR JSON PATH keyword
          ) AS Orders
    FROM Person.Person per
)
SELECT * 
 , ISJSON(Orders) AS [ISJSON(Orders)]
 , TRY_CONVERT(json, Orders) AS Orders_JSON
FROM cte


