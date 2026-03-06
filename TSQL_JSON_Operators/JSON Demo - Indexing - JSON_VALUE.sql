USE AdventureWorks2025

-- Turn on "Include Actual Execution Plan" (Cntl + M) 

------------------------------------ Setup ------------------------------------

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


-- Let's look for any customer whose last name is Young

SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'
-- We see a 100% Clustered Index Scan on the PK, and a subtree cost of : 0.568
-- Note the simple, clean, warning-free execution plan


CREATE JSON INDEX IXJ_PersonJSON_CustomerJson
ON Person.PersonOrders_JSON(CustomerJson)
   FOR ('$')        -- default is { FOR ('$') }
   WITH (DATA_COMPRESSION=PAGE);


-- Let's look for any customer whose last name is Young
SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'

-- The subtree cost did not change, but
-- We introduced a CONVERT_IMPLICIT warning... just from creating the JSON index?
-- Why? Hint: Look at the definition of the JSON index table
SELECT Convert(varchar(400), 0x5468652073716C5F76616C756520636F6C756D6E206F662074686520696E646578206C6F6F6B7570207461626C652069732073716C5F76617269616E74)
-- Could I fix it by adding RETURNING varchar ?
SELECT Convert(varchar(400), 0x4E6F2E207468652073716C5F76616C756520636F6C756D6E20776F756C64206E65656420746F206265204A534F4E20746F20757365207468652052455455524E494E47206B6579776F7264)


SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_VALUE(CustomerJson,'$.json_expert') = Convert(bit, 1)
-- JSON index hits, Subtree cost of 0.0066

SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_VALUE(CustomerJson,'$.json_expert') = Convert(bit, 1)
  AND JSON_VALUE(CustomerJson,'$.LastName') = 'Young'
-- JSON index hits twice, Subtree cost of 0.013


-- Run together..

    SELECT *
    FROM Person.PersonOrders_JSON
    WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'
    --Clustered index scan, Subtree cost of 1.084

    SELECT CustomerID
    FROM Person.PersonOrders_JSON
    WHERE JSON_VALUE(CustomerJson, '$.LastName') = 'Young'
    --JSON index Seek, Subtree cost of 0.142


-- Is this worth bringing up?
DROP INDEX IXJ_PersonJSON_CustomerJson
ON Person.PersonOrders_JSON
CREATE JSON INDEX IXJ_PersonJSON_CustomerJson_LastName
ON Person.PersonOrders_JSON(CustomerJson)
   FOR ('$.LastName')        -- default is { FOR ('$') }
   WITH (DATA_COMPRESSION=PAGE);