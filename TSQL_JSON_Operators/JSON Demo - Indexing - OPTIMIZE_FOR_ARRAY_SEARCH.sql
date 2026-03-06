USE AdventureWorks2025

/*
 ┌---------------┐     ┌------------------------┐
 | Person.Person |--01<| Sales.SalesOrderHeader |
 └---------------┘     └------------------------┘
*/

-------------------------------------------------------------------------------------------------

-- I want one row per customer, 
--      with JSON content of all the customer orders in an array

-------------------------------------------------------------------------------------------------


-- Create a table to store our JSON

CREATE TABLE [Person].[SalesOrderNumbers_JSON](
	[CustomerID] [int] NOT NULL,
	[SalesOrderNumbers] [json] NOT NULL,
 CONSTRAINT [PK_SalesOrderNumbers_JSON] PRIMARY KEY CLUSTERED 
(
	[CustomerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

INSERT INTO [Person].[SalesOrderNumbers_JSON] ([CustomerID], [SalesOrderNumbers])
SELECT 
    p.BusinessEntityID AS CustomerID,
    (
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

SELECT * FROM [Person].[SalesOrderNumbers_JSON]

-- Turn on Execution Plans (Cntl + M)

-- Query, no indexing

SELECT * FROM [Person].[SalesOrderNumbers_JSON]
WHERE JSON_CONTAINS(SalesOrderNumbers, 'SO51702', '$.SalesOrderNumber[*]') = 1
-- Subquery cost of 0.229

-- Introduce a JSON index

CREATE JSON INDEX IXJ_SOHJSON_SalesOrderNumbers
ON Person.SalesOrderNumbers_JSON(SalesOrderNumbers)
   FOR ('$')
   WITH (DATA_COMPRESSION=PAGE);


SELECT so.object_id
    , CONCAT('''[', SCHEMA_NAME(so.schema_id) , '].[', so.name, ']') AS Target_Table
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
WHERE 'SalesOrderNumbers_JSON' IN (parent.name, so.name)
ORDER BY SCHEMA_NAME(so.schema_id), so.name, si.[index_id], ic.key_ordinal
-- Take a snapshot of the results 

-- Run the DAC query to see the contents

-- Re-run the query

SELECT * FROM [Person].[SalesOrderNumbers_JSON]
WHERE JSON_CONTAINS(SalesOrderNumbers, 'SO51702', '$.SalesOrderNumber[*]') = 1
-- Subquery cost of 0.147


-- Rebuild the JSON index for OPTIMIZE_FOR_ARRAY_SEARCH
CREATE JSON INDEX IXJ_SOHJSON_SalesOrderNumbers
ON Person.SalesOrderNumbers_JSON(SalesOrderNumbers)
   FOR ('$')
   WITH (DATA_COMPRESSION=PAGE, DROP_EXISTING = ON
         , OPTIMIZE_FOR_ARRAY_SEARCH = ON);
            -- ^^^^^^^^^^^^^^^^^^^

-- See that the optimize_for_array_search flag is now 1
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
WHERE 'SalesOrderNumbers_JSON' IN (parent.name, so.name)
ORDER BY SCHEMA_NAME(so.schema_id), so.name, si.[index_id], ~Convert(bit, ic.key_ordinal)

-- Run the DAC query to see the contents

SELECT * FROM [Person].[SalesOrderNumbers_JSON]
WHERE JSON_CONTAINS(SalesOrderNumbers, 'SO51702', '$.SalesOrderNumber[*]') = 1
-- Subquery cost of 0.017