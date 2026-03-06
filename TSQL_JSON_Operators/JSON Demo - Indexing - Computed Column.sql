SELECT TOP 100 * FROM [Person].[PersonOrders_JSON]

-- Using JSON_VALUE to locate some data
SELECT CustomerID, JSON_VALUE(CustomerJson, '$.LastName')
FROM [Person].[PersonOrders_JSON]

-- Add a persisted computed column for help with indexing
ALTER TABLE [Person].[PersonOrders_JSON]
	ADD LastName AS 
	(
		JSON_VALUE(CustomerJson, '$.LastName')
	)
PERSISTED

SELECT TOP 100 * FROM [Person].[PersonOrders_JSON]
-- What is its datatype?

-- Cntl + M for Execution Plans

SELECT * FROM [Person].[PersonOrders_JSON]
WHERE LastName = 'Young'
-- Clustered index scan, subtree cost of 1.080

-- Add an index upon JSON data, though not a JSON index
CREATE NONCLUSTERED INDEX IX_PersonOrders_JSON 
ON Person.PersonOrders_JSON (LastName)
WITH( STATISTICS_NORECOMPUTE = OFF
	, IGNORE_DUP_KEY = OFF
	, ALLOW_ROW_LOCKS = ON
	, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
-- Warning on length!

SELECT * FROM [Person].[PersonOrders_JSON]
WHERE LastName = 'Young'
-- Subtree cost of 0.124

-- What happens here?
SELECT * FROM [Person].[PersonOrders_JSON]
WHERE JSON_VALUE(CustomerJson, '$.LastName') = 'Young'


-- Clean-up
DROP INDEX IX_PersonOrders_JSON ON Person.PersonOrders_JSON
GO
ALTER TABLE Person.PersonOrders_JSON DROP COLUMN LastName


--- Wait! Wait! I'm a good steward of data!
--- I would have issued it as :



ALTER TABLE [Person].[PersonOrders_JSON]
	ADD LastName AS 
	(
		Convert(varchar(50), JSON_VALUE(CustomerJson, '$.LastName'))
	)  --- ^^^^^^^^^^^^^^^
PERSISTED
-- Refresh SSMS Object Explorer

CREATE NONCLUSTERED INDEX IX_PersonOrders_JSON 
ON Person.PersonOrders_JSON (LastName)
WITH( STATISTICS_NORECOMPUTE = OFF
	, IGNORE_DUP_KEY = OFF
	, ALLOW_ROW_LOCKS = ON
	, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

SELECT * FROM [Person].[PersonOrders_JSON]
WHERE LastName = 'Young'
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