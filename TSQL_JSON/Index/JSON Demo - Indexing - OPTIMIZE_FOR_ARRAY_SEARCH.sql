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


-- Re-run the query

SELECT * FROM [Person].[SalesOrderNumbers_JSON]
WHERE JSON_CONTAINS(SalesOrderNumbers, 'SO51702', '$.SalesOrderNumber[*]') = 1
-- Subquery cost of 0.147 (50% savings), because I added a JSON index
-- (If you look at the Execution Plan, it is a Clustered Index Scan on the sys.json_index table)

-- Rebuild the JSON index for OPTIMIZE_FOR_ARRAY_SEARCH
DROP INDEX IXJ_SOHJSON_SalesOrderNumbers ON Person.SalesOrderNumbers_JSON
CREATE JSON INDEX IXJ_SOHJSON_SalesOrderNumbers
ON Person.SalesOrderNumbers_JSON(SalesOrderNumbers)
   FOR ('$')
   WITH (OPTIMIZE_FOR_ARRAY_SEARCH = ON);
       -- ^^^^^^^^^^^^^^^^^^^^^^^

-- Let's re-run the query now

SELECT * FROM [Person].[SalesOrderNumbers_JSON]
WHERE JSON_CONTAINS(SalesOrderNumbers, 'SO51702', '$.SalesOrderNumber[*]') = 1
-- Subquery cost of 0.018 (90%+ savings from original) from adding OPTIMIZE_FOR_ARRAY_SEARCH


-- In our Index Summary query, see that the optimize_for_array_search flag is now 1
SELECT * FROM sys.json_indexes ji


-----------------------------------------------------------
-- More content; Skip for time...
-----------------------------------------------------------

-- Run the DAC query to witness any rowcount change before/after OPTIMIZE_FOR_ARRAY_SEARCH
-- Spoiler alert: Rowcount does not change with OPTIMIZE_FOR_ARRAY_SEARCH


-- Bonus content: You may have noticed usage of JSON_QUERY + CONCAT + STRING_AGG 
-- to build a different style of array. Compare these two SQL statements:

/* 
SELECT 
    p.BusinessEntityID AS CustomerID,
    (
        SELECT soh.SalesOrderNumber
        FROM Sales.SalesOrderHeader AS soh
        WHERE soh.CustomerID = c.CustomerID
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    ) AS SalesOrderNumbers
FROM Person.Person AS p
  INNER JOIN Sales.Customer AS c
      ON p.BusinessEntityID = c.PersonID

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

*/