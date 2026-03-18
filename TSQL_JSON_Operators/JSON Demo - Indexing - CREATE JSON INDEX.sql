--https://sqlsunday.com/2025/05/19/json-indexes-first-impressions/

SET NOCOUNT ON;
-- Need AdventureWorks2025?
-- Visit https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure

------------------------------------ Setup ------------------------------------

USE AdventureWorks2025

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
ORDER BY NEWID()
-- We have three high-level properties: a first- and last name, and an Orders array
-- Within the Orders array are order objects with some properties and an OrderDetails array
-- Within the OrderDetails array are some product objects with some properties

--------------------------------------------------------------------------------------------

-- Add some dummy data to one row for later demos

UPDATE [Person].[PersonOrders_JSON]
SET CustomerJson.modify('lax $.json_expert', Convert(bit, 1))
WHERE CustomerID = 11000

--------------------------------------------------------------------------------------------

--Let's add a JSON index. We can specify a path, or cover the whole of the contents
CREATE JSON INDEX IXJ_PersonJSON_CustomerJson
ON Person.PersonOrders_JSON(CustomerJson)
   FOR ('$') -- path is root, so we are covering the contents
   WITH (DATA_COMPRESSION=PAGE, FILLFACTOR=80, PAD_INDEX=ON);


  

-- Where is this new JSON index documented?
SELECT index_id, * FROM sys.indexes WHERE type_desc = 'JSON'
SELECT index_id, * FROM sys.json_indexes sji

SELECT index_id, [object_id], OBJECT_NAME([object_id]), [path] 
FROM sys.json_index_paths

-- What is the JSON index bound to?
SELECT si.type_desc AS index_type, si.name AS index_name
    , '|' AS '|'
    , SCHEMA_NAME(so.schema_id) AS [Schema_Name], so.name AS Table_Name
    , so.[object_id], so.type, so.type_desc
FROM sys.objects so
  INNER JOIN sys.indexes si
      ON so.[object_id] = si.[object_id]
WHERE si.type_desc = 'JSON'

-- So if I take the same query and change the WHERE clause to a index name...
SELECT si.type_desc AS index_type, si.name AS index_name
    , '|' AS '|'
    , SCHEMA_NAME(so.schema_id) AS [Schema_Name], so.name AS Table_Name
    , so.[object_id], so.type, so.type_desc , si.type_desc
FROM sys.objects so
  INNER JOIN sys.indexes si
      ON so.[object_id] = si.[object_id]
WHERE si.name = 'IXJ_PersonJSON_CustomerJson'
-- A new challenger appears!

-- What properties does this internal table have?
SELECT SCHEMA_NAME(sit.schema_id) AS SchemaName, sit.name AS TableName, sit.object_id
  , sit.parent_object_id, sit.type, sit.type_desc, sit.create_date
  , sit.internal_type, sit.internal_type_desc
  , '|' AS '|'
  , CONCAT(SCHEMA_NAME(so.schema_id), '.', so.name) AS 'parent_object_name'
FROM sys.internal_tables sit  --<-- check out this new table name
  INNER JOIN sys.objects so
      ON sit.parent_object_id = so.[object_id]
WHERE so.name = 'PersonOrders_JSON'

-- Can I query from it?
SELECT * FROM sys.json_index_1895677801_1216000   --< -- use the name from last query

--------------------------------------------------------------------------------------------

-- Open file "JSON Demo - Indexing - DAC session.sql" and follow instructions

---------------------------------------------------------------------------------

SELECT * 
FROM [Person].[PersonOrders_JSON__json_index_1895677801_1216000]
ORDER BY posting_1, json_array_index, Len(json_path) -- the ORDER BY really helps explain the data

-- Switch back to presentation for column description

-- An overall summary of all the indexes involved
SELECT so.object_id
    , CONCAT('[', SCHEMA_NAME(so.schema_id) , '].[', so.name, ']') AS Target_Table
    , so.type_desc
    , '|' AS '|'
    , si.[index_id], si.name AS Index_Name, si.type_desc AS Index_Type, ji.optimize_for_array_search
    , '|' AS '|'
    , ic.index_id, ic.key_ordinal, c.name AS column_name
FROM sys.objects so
  INNER JOIN sys.indexes si
      ON so.object_id = si.object_id
    INNER JOIN sys.index_columns ic
        ON si.[object_id] = ic.[object_id]
        AND si.[index_id] = ic.[index_id]
      INNER JOIN sys.columns c 
          ON ic.object_id = c.object_id
          AND ic.column_id = c.column_id
  LEFT JOIN sys.json_indexes ji
      ON si.[object_id] = ji.[object_id]
      AND si.type_desc = 'JSON'
  LEFT JOIN sys.objects parent
      ON so.parent_object_id = parent.[object_id]
WHERE 'PersonOrders_Json' IN (parent.name, so.name)
ORDER BY SCHEMA_NAME(so.schema_id), so.name, si.[index_id], ~Convert(bit, ic.key_ordinal)
