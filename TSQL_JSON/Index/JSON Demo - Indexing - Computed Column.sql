------------------------------------ Setup ------------------------------------

USE AdventureWorks2025

SET NOCOUNT ON;

IF DB_NAME() != 'AdventureWorks2025'
  RAISERROR('Scripts will not reliabily run!', 20, 1) WITH LOG;

IF NOT EXISTS (
    SELECT 1 FROM sys.tables
    WHERE name = 'PersonOrders_JSON'
      AND schema_id = SCHEMA_ID('Person')
)
  RAISERROR('Scripts will not reliabily run if table is missing!', 20, 1) WITH LOG;

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IXJ_PersonJSON_CustomerJson'
      AND object_id = OBJECT_ID('Person.PersonOrders_JSON')
)
  DROP INDEX IXJ_PersonJSON_CustomerJson ON Person.PersonOrders_JSON

--------------------------------- End Setup -----------------------------------

SELECT TOP 100 * FROM [Person].[PersonOrders_JSON]

-- Cntl + M for Execution Plans

-- Using JSON_VALUE to locate some data
SELECT CustomerID, JSON_VALUE(CustomerJson, '$.LastName')
FROM [Person].[PersonOrders_JSON]


-- Add a persisted computed column for help with indexing
ALTER TABLE [Person].[PersonOrders_JSON]
	ADD c_LastName AS 
	(
		JSON_VALUE(CustomerJson, '$.LastName')
	)
PERSISTED


SELECT TOP 100 * FROM [Person].[PersonOrders_JSON]
-- What is its datatype? Review Object Explorer.


SELECT * FROM [Person].[PersonOrders_JSON]
WHERE c_LastName = 'Young'
-- Clustered index scan, subtree cost of 1.11


-- Add an index upon JSON data, though not a JSON index
CREATE NONCLUSTERED INDEX IX_PersonOrders_JSON__LastName
ON Person.PersonOrders_JSON (c_LastName)
WITH( STATISTICS_NORECOMPUTE = OFF
	, IGNORE_DUP_KEY = OFF
	, ALLOW_ROW_LOCKS = ON
	, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
-- Warning on length!

SELECT * FROM [Person].[PersonOrders_JSON]
WHERE c_LastName = 'Young'
-- Subtree cost of 0.124 (90% savings)

-- What happens here?
SELECT * FROM [Person].[PersonOrders_JSON]
WHERE JSON_VALUE(CustomerJson, '$.LastName') = 'Young'

-- It used the same plan because the formulae matched

-- Clean-up
DROP INDEX IX_PersonOrders_JSON__LastName ON Person.PersonOrders_JSON
GO
ALTER TABLE Person.PersonOrders_JSON DROP COLUMN c_LastName


--- Wait! Wait! I'm a good steward of data!
--- I would have issued it as :



ALTER TABLE [Person].[PersonOrders_JSON]
	ADD c_LastName AS 
	(
		Convert(varchar(50), JSON_VALUE(CustomerJson, '$.LastName'))
	)  --- ^^^^^^^^^^^^^^^
PERSISTED
-- Refresh SSMS Object Explorer

CREATE NONCLUSTERED INDEX IX_PersonOrders_JSON__LastName 
ON Person.PersonOrders_JSON (c_LastName)
WITH( STATISTICS_NORECOMPUTE = OFF
	, IGNORE_DUP_KEY = OFF
	, ALLOW_ROW_LOCKS = ON
	, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

SELECT * FROM [Person].[PersonOrders_JSON]
WHERE c_LastName = 'Young'
-- Subtree cost of 0.124

SELECT * FROM [Person].[PersonOrders_JSON]
WHERE JSON_VALUE(CustomerJson, '$.LastName') = 'Young'
-- Back to a clustered index scan because the formulae don't match

SELECT * FROM [Person].[PersonOrders_JSON]
WHERE Convert(varchar(50), JSON_VALUE(CustomerJson, '$.LastName')) = 'Young'
-- Subtree cost of 0.124 because formulae match

SELECT * FROM [Person].[PersonOrders_JSON]
WHERE Convert(nvarchar(50), JSON_VALUE(CustomerJson, '$.LastName')) = 'Young'
-- Back to a clustered index scan because the formulae don't match