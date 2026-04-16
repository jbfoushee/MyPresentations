------------------------------------ Setup ------------------------------------

USE AdventureWorks2025

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

-- Turn on "Include Actual Execution Plan" (Cntl + M) 

-- Let's see all persons who ever ordered product 965
SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_CONTAINS(CustomerJson, 965 ,'$.Orders[*].OrderDetails[*].ProductID') = 1
-- We see another 100% Clustered Index Scan on the PK, and a subtree count of : 0.568

-- Let's see all persons who ever ordered product 870
SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_CONTAINS(CustomerJson, 870 ,'$.Orders[*].OrderDetails[*].ProductID') = 1
-- We see another 100% Clustered Index Scan on the PK, and a similar subtree count

--------------------------------------------------------------------------------

CREATE JSON INDEX IXJ_PersonJSON_CustomerJson
ON Person.PersonOrders_JSON(CustomerJson)
   FOR ('$')        
                    -- try { FOR ('$.Orders') }
                    -- and benefit in creation speed and index footprint

--------------------------------------------------------------------------------

SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_CONTAINS(CustomerJson, 965 ,'$.Orders[*].OrderDetails[*].ProductID') = 1
-- The JSON index hits, and the subtree cost goes down to 0.156
-- This is a 60% improvement from the original


SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_CONTAINS(CustomerJson, 870 ,'$.Orders[*].OrderDetails[*].ProductID') = 1
-- The JSON index does not trip, we still use the Clustered Index Scan.
-- Too many rows returned for this product; index not selective enough
-- Even WITH (FORCESEEK), SQL Server says "No thanks"

--------------------------------------------------------------------------------
