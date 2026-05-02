------------------------------------ Setup ------------------------------------

USE AdventureWorks2025

SET NOCOUNT OFF;

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


-- Turn on "Display Actual Execution Plans" (Cntl-M)

-- Let's look for any customer whose last name is Young

SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'
-- Point out the icon for the SELECT operation

-- Create our JSON index
CREATE JSON INDEX IXJ_PersonJSON_CustomerJson
ON Person.PersonOrders_JSON(CustomerJson)
   FOR ('$') -- path is root, so we are covering the contents


-- Let's look for any customer whose last name is Young
SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'
-- Two things of note in the Execution Plan:
-- 1. We introduced a CONVERT_IMPLICIT warning. (What is the datatype being converted?)
--    However, this is not the reason it went with the Clustered Index Scan.
--    It is just noise.
-- 2. This query did not use the JSON index


--It hits when combined with another predicate
SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_VALUE(CustomerJson,'$.json_expert') = Convert(bit, 1)
  AND JSON_VALUE(CustomerJson,'$.LastName') = 'Young'
-- JSON index hits twice, Subtree cost of 0.013


-- and side note: the json_expert clause by itself works fine:
SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_VALUE(CustomerJson,'$.json_expert') = Convert(bit, 1)
-- JSON index hits, Subtree cost of 0.006


-- What's the subtree cost of the original statement? (0.576)
SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'
-- Appears to be about 0.576
-- Still not using the JSON index.


-- Review the Execution Plan for StatementEstRows and SamplingPercent
-- Can we force it?
SELECT *
FROM Person.PersonOrders_JSON WITH (INDEX(IXJ_PersonJSON_CustomerJson), FORCESEEK)
WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'
-- Review if Subtree cost is better (and it's not!? Over 2.0)

-- Run together for workload comparison
-- Screen-shot the plan and workload ratios
    SELECT *
    FROM Person.PersonOrders_JSON
    WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'

    SELECT *
    FROM Person.PersonOrders_JSON WITH (INDEX(IXJ_PersonJSON_CustomerJson), FORCESEEK)
    WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'


-- "Aggitate" the plan store by taking those two queries against every unique customer
    SELECT DISTINCT 
    CONCAT(
        'SELECT * FROM Person.PersonOrders_JSON
        WHERE JSON_VALUE(CustomerJson,''$.LastName'') = ''', JSON_VALUE(CustomerJson,'$.LastName'),'''

        SELECT * FROM Person.PersonOrders_JSON WITH (INDEX(IXJ_PersonJSON_CustomerJson), FORCESEEK)
        WHERE JSON_VALUE(CustomerJson,''$.LastName'') = ''', JSON_VALUE(CustomerJson,'$.LastName'),'''
        ')
    FROM Person.PersonOrders_JSON
-- Take this new script and run in a new window

-- Run this statement in tandem with the agitation script:
SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'
-- It should change while the agitation script runs.

-- If the agitation script finishes and no change, parameter sniffing may have occurred
-- Switch the parameter:
SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Zhu'
-- and switch back
SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'
-- Subtree cost of 0.296


-- How do the oroginal and FORCESEEK statements compare now?
-- Run together and compare with screenshot
    SELECT *
    FROM Person.PersonOrders_JSON
    WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'

    SELECT *
    FROM Person.PersonOrders_JSON WITH (INDEX(IXJ_PersonJSON_CustomerJson), FORCESEEK)
    WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'




-- New example:

-- Let's search on an integer within the recordset...
    --SELECT *
    --FROM Person.PersonOrders_JSON
    --WHERE CustomerID = 11002

    SELECT * FROM [Person].[PersonOrders_JSON__json_index_1895677801_1216000]
    WHERE posting_1 = 11002
    ORDER BY posting_1, json_path, LEN(json_array_index), json_array_index

-- Which of these statements will run the fastest? Which the slowest?
-- Note: You will get different results between SQL 2025 RTM and CU3

    USE AdventureWorks2025

    SELECT @@VERSION, *
    FROM Person.PersonOrders_JSON
    WHERE JSON_VALUE(CustomerJson,'$.Orders[2].SalesOrderID') = '53237'
    
    SELECT @@VERSION, *
    FROM Person.PersonOrders_JSON
    WHERE JSON_VALUE(CustomerJson,'$.Orders[2].SalesOrderID') = 53237
 
    SELECT @@VERSION, *
    FROM Person.PersonOrders_JSON
    WHERE Convert(int, JSON_VALUE(CustomerJson,'$.Orders[2].SalesOrderID')) = 53237

    SELECT @@VERSION, *
    FROM Person.PersonOrders_JSON
    WHERE JSON_VALUE(CustomerJson,'$.Orders[2].SalesOrderID' RETURNING int) = 53237
 

-----------------------------------------------------------
-- More content... skip for time...
-----------------------------------------------------------


-- Even when you force the index, SQL may not want it...
-- Run together:

    SELECT *
    FROM Person.PersonOrders_JSON
    WHERE JSON_VALUE(CustomerJson,'$.Orders[1].SalesOrderNumber') = 'SO51421'
    -- Subtree cost of 0.576; Does not use JSON index

    SELECT *
    FROM Person.PersonOrders_JSON WITH (FORCESEEK)
    WHERE JSON_VALUE(CustomerJson,'$.Orders[1].SalesOrderNumber') = 'SO51421'
    -- Subtree cost of 0.879

    SELECT *
    FROM Person.PersonOrders_JSON WITH (INDEX(IXJ_PersonJSON_CustomerJson))
    WHERE JSON_VALUE(CustomerJson,'$.Orders[1].SalesOrderNumber') = 'SO51421'
    -- Subtree cost of 0.629

    SELECT *
    FROM Person.PersonOrders_JSON WITH (INDEX(IXJ_PersonJSON_CustomerJson), FORCESEEK)
    WHERE JSON_VALUE(CustomerJson,'$.Orders[1].SalesOrderNumber') = 'SO51421'
    OPTION (OPTIMIZE FOR UNKNOWN, RECOMPILE); 
    -- Subtree cost of 0.879


