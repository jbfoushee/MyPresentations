USE AdventureWorks2025

-- Create the new "Person.PersonOrders_JSON" table with this statement
CREATE TABLE [Person].[PersonOrders_JSON](
	[CustomerID] [int] NOT NULL,
	[CustomerJson] [json] NOT NULL,  --<-- must be JSON to use a JSON INDEX
  CONSTRAINT [PK_PersonOrders_JSON] PRIMARY KEY CLUSTERED 
  (
	 [CustomerID] ASC
  ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

INSERT INTO [Person].[PersonOrders_JSON] (CustomerID, CustomerJson)
SELECT
    per.BusinessEntityID AS CustomerID
    , (
        SELECT
            per.FirstName
            , per.LastName
            , (
                SELECT
                    soh.SalesOrderID
                    , soh.SalesOrderNumber
                    , soh.OrderDate
                    , soh.TotalDue
                    , (
                        SELECT
                            sod.ProductID,
                            sod.OrderQty,
                            sod.UnitPrice,
                            NULLIF(sod.SpecialOfferID, 1) AS SpecialOfferID
                        FROM Sales.SalesOrderDetail sod
                        WHERE sod.SalesOrderID = soh.SalesOrderID
                        FOR JSON PATH
                    ) AS OrderDetails
                FROM Sales.SalesOrderHeader soh
                WHERE soh.CustomerID = per.BusinessEntityID
                FOR JSON PATH
            ) AS Orders
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    ) AS CustomerJson
FROM Person.Person per
WHERE EXISTS 
    (SELECT 1 
     FROM Sales.SalesOrderHeader soh
     WHERE per.BusinessEntityID = soh.CustomerID)

-- Review the JSON data.
SELECT TOP 10 * 
FROM [Person].[PersonOrders_JSON]
WHERE JSON_PATH_EXISTS(CustomerJson, '$.Orders[*].OrderDetails[1]') = 1
  OR JSON_PATH_EXISTS(CustomerJson, '$.Orders[1]') = 1
ORDER BY NEWID()

-- Add some dummy data to one row for later demos

UPDATE [Person].[PersonOrders_JSON]
SET CustomerJson.modify('lax $.json_expert', Convert(bit, 1))
WHERE CustomerID = 11000

SELECT * FROM [Person].[PersonOrders_JSON]
WHERE CustomerID = 11000

-- Turn on "Display Actual Execution Plans" (Cntl-M)

-- Base query
SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'
-- Point out the icon for the SELECT operation

-- Create our JSON index
CREATE JSON INDEX IXJ_PersonJSON_CustomerJson
ON Person.PersonOrders_JSON(CustomerJson)
   FOR ('$') 

-- Run the query again
SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'
-- Still does not use the JSON Index Seek

--It hits when combined with another predicate
SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_VALUE(CustomerJson,'$.json_expert') = Convert(bit, 1)
  AND JSON_VALUE(CustomerJson,'$.LastName') = 'Young'

-- Run the query again
SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'
-- Still does not use the JSON Index Seek

-- "Aggitate" the plan store by querying every unique customer
SELECT DISTINCT 
CONCAT(
    'SELECT * FROM Person.PersonOrders_JSON
    WHERE JSON_VALUE(CustomerJson,''$.LastName'') = ''', JSON_VALUE(CustomerJson,'$.LastName'),'''

    SELECT * FROM Person.PersonOrders_JSON WITH (INDEX(IXJ_PersonJSON_CustomerJson), FORCESEEK)
    WHERE JSON_VALUE(CustomerJson,''$.LastName'') = ''', JSON_VALUE(CustomerJson,'$.LastName'),'''
    ')
FROM Person.PersonOrders_JSON

-- Open a new query and issue the commands created
--
-- Meanwhile, run this query again and again until it switches 
-- over to a JSON index seek
SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'
