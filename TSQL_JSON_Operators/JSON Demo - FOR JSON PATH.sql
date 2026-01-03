USE AdventureWorks

SELECT per.BusinessEntityID, per.FirstName, per.LastName
    , '|' AS '|', soh.SalesOrderNumber, soh.OrderDate, soh.TotalDue
    , '|' AS '|', sod.ProductID, sod.OrderQty, sod.UnitPrice
FROM Person.Person per
  INNER JOIN Sales.SalesOrderHeader soh
      ON soh.CustomerID = per.BusinessEntityID
    INNER JOIN Sales.SalesOrderDetail sod
        ON soh.SalesOrderID = sod.SalesOrderID
ORDER BY per.BusinessEntityID, soh.SalesOrderID, sod.UnitPrice DESC

-- Let's group products together within one order...

SELECT per.BusinessEntityID, per.FirstName, per.LastName
    , '|' AS '|', soh.SalesOrderNumber, soh.OrderDate, soh.TotalDue
    , (
        SELECT 
            sod.ProductID, sod.OrderQty, sod.UnitPrice
        FROM Sales.SalesOrderDetail sod
        WHERE sod.SalesOrderID = soh.SalesOrderID  --<-- a new subquery with a WHERE join
        FOR JSON PATH                              --<-- FOR JSON PATH
       ) AS Products
FROM Person.Person per
  INNER JOIN Sales.SalesOrderHeader soh
      ON soh.CustomerID = per.BusinessEntityID
                                                --<-- an INNER JOIN is lost
ORDER BY per.BusinessEntityID, soh.SalesOrderID;

-- But let's further group by person...

SELECT
    per.BusinessEntityID, per.FirstName, per.LastName
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
                FOR JSON PATH                              --<-- FOR JSON PATH
              ) AS OrderDetails
        FROM Sales.SalesOrderHeader soh
        WHERE soh.CustomerID = per.BusinessEntityID  --<-- a new subquery with a WHERE join
        FOR JSON PATH                                --<-- FOR JSON PATH
      ) AS Orders
FROM Person.Person per

ORDER BY per.BusinessEntityID;


-- Too much? How to fix?