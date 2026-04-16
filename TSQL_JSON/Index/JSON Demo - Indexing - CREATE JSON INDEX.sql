-- Need AdventureWorks2025?
-- Visit https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure

------------------------------------ Setup ------------------------------------

-- Turn on ZoomIt !

USE AdventureWorks2025

SET NOCOUNT ON;

IF DB_NAME() != 'AdventureWorks2025'
  RAISERROR('Scripts will not reliabily run!', 20, 1) WITH LOG;

DROP TABLE IF EXISTS [Person].[PersonOrders_JSON]

--------------------------------- End Setup -----------------------------------

-- Let's merge some data from three tables to generate some JSON data
-- We will only work with persons with 1/more orders
-- We will be skipping a lot of columns such as taxes and discounts
/*
 ┌---------------┐    ┌------------------------┐    ┌------------------------┐
 | Person.Person |--1<| Sales.SalesOrderHeader |--1<| Sales.SalesOrderDetail |
 └---------------┘    └------------------------┘    └------------------------┘
     Customer               overall order                  line items
*/

-- Original data in hierarchical structure
SELECT per.BusinessEntityID, per.FirstName, per.LastName
    , '|' AS '|'
    , soh.SalesOrderID, soh.SalesOrderNumber, soh.OrderDate, soh.TotalDue
    , '|' AS '|'
    , sod.ProductID, sod.OrderQty, sod.UnitPrice
    , NULLIF(sod.SpecialOfferID, 1) AS SpecialOfferID
FROM Person.Person per
  INNER JOIN Sales.SalesOrderHeader soh
      ON per.BusinessEntityID = soh.CustomerID
    INNER JOIN Sales.SalesOrderDetail sod
        ON soh.SalesOrderID = sod.SalesOrderID
ORDER BY per.BusinessEntityID

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
-- We have three high-level properties: a first- and last name, and an Orders array
-- Within the Orders array are order objects with some properties and an OrderDetails array
-- Within the OrderDetails array are some product objects with some properties

--------------------------------------------------------------------------------------------

-- Add some dummy data to one row for later demos

UPDATE [Person].[PersonOrders_JSON]
SET CustomerJson.modify('lax $.json_expert', Convert(bit, 1))
WHERE CustomerID = 11000

SELECT * FROM [Person].[PersonOrders_JSON]
WHERE CustomerID = 11000

--------------------------------------------------------------------------------------------

--Let's add a JSON index. We can specify a path, or cover the whole of the contents
CREATE JSON INDEX IXJ_PersonJSON_CustomerJson
ON Person.PersonOrders_JSON(CustomerJson)
   FOR ('$'); -- path is root, so we are covering the contents

  

-- Where is this new JSON index documented?
-- Run together:
        SELECT index_id, * FROM sys.indexes WHERE type_desc = 'JSON'
        SELECT index_id, * FROM sys.json_indexes sji

        SELECT index_id, [object_id], OBJECT_NAME([object_id]), [path] 
        FROM sys.json_index_paths
-- Right now, this is the only way you can see this info. 
-- SSMS enumerates the index, but does not allow scripting or viewing properties


-- What is the JSON index bound to?
SELECT si.[type_desc] AS index_type, si.[name] AS index_name
    , '|' AS '|'
    , SCHEMA_NAME(so.schema_id) AS [Schema_Name], so.[name] AS Table_Name
    , so.[object_id], so.[type], so.[type_desc]
FROM sys.objects so
  INNER JOIN sys.indexes si
      ON so.[object_id] = si.[object_id]
WHERE si.[type_desc] = 'JSON'

-- So if I take the same query and change the WHERE clause to a index name...
SELECT si.[type_desc] AS index_type, si.[name] AS index_name
    , '|' AS '|'
    , SCHEMA_NAME(so.schema_id) AS [Schema_Name], so.[name] AS Table_Name
    , so.[object_id], so.[type], so.[type_desc] , si.[type_desc]
FROM sys.objects so
  INNER JOIN sys.indexes si
      ON so.[object_id] = si.[object_id]
WHERE si.[name] = 'IXJ_PersonJSON_CustomerJson'   --<-- this line changed
-- A new challenger appears!


-- Can I query from it?
SELECT * FROM sys.json_index_1895677801_1216000   --< -- use the name from last query

--------------------------------------------------------------------------------------------

-- Open file "JSON Demo - Indexing - DAC session.sql" and follow instructions

---------------------------------------------------------------------------------

SELECT * 
FROM [Person].[PersonOrders_JSON__json_index_1895677801_1216000]
ORDER BY posting_1, json_array_index, Len(json_path) -- the ORDER BY really helps explain the data

-- Expand [Person].[PersonOrders_JSON__json_index_1895677801_1216000] in SSMS
-- Switch back to presentation for column description and indexes
