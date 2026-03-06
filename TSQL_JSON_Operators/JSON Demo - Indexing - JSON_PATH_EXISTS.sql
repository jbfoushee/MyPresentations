USE AdventureWorks

-- Turn on "Include Actual Execution Plan" (Cntl + M) 

------------------------------------ Setup ------------------------------------

IF DB_NAME() != 'AdventureWorks'
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

-- Find all order with a property of "TotalDue"
SELECT po.CustomerID
FROM Person.PersonOrders_JSON AS po
WHERE JSON_PATH_EXISTS(po.CustomerJson, '$.Orders[*].TotalDue') = 1

-- Find all Orders consisting of 8 products or more
SELECT COUNT(*)
FROM Person.PersonOrders_JSON 
WHERE JSON_PATH_EXISTS(CustomerJson, '$.Orders[*].OrderDetails[7]') = 1
OPTION  ( MAXDOP 1)

-- Update one random OrderDetail with a new property "blah"
UPDATE Person.PersonOrders_JSON
SET [CustomerJson].modify('$.Orders[0].OrderDetails[0].blah', 'value')
WHERE CustomerID IN
    (SELECT TOP 1 CustomerID
     FROM Person.PersonOrders_JSON
     ORDER BY NEWID() )

SELECT CustomerID
FROM Person.PersonOrders_JSON 
WHERE JSON_PATH_EXISTS(CustomerJson, '$.Orders[0].OrderDetails[0].blah') = 1
OPTION  ( MAXDOP 1)

-----------------------------------------------------------------------------
-- Add our JSON index...
CREATE JSON INDEX IXJ_PersonJSON_CustomerJson
ON Person.PersonOrders_JSON(CustomerJson)
   FOR ('$')        -- default is { FOR ('$') }
                    -- try { FOR ('$.Orders') } and see the difference
;
-----------------------------------------------------------------------------

-- Find all order with a property of "TotalDue"
SELECT po.CustomerID
FROM Person.PersonOrders_JSON AS po
WHERE JSON_PATH_EXISTS(po.CustomerJson, '$.Orders[*].TotalDue') = 1

-- Find all Orders consisting of 8 products or more
SELECT po.CustomerID
FROM Person.PersonOrders_JSON AS po
WHERE JSON_PATH_EXISTS(CustomerJson, '$.Orders[*].OrderDetails[7]') = 1


SELECT po.CustomerID
FROM Person.PersonOrders_JSON AS po
WHERE JSON_PATH_EXISTS(CustomerJson, '$.Orders[*].OrderDetails[7].ProductID') = 1


-- Find the one random OrderDetail with a new property "blah"
SELECT CustomerID
FROM Person.PersonOrders_JSON 
WHERE JSON_PATH_EXISTS(CustomerJson, '$.Orders[0].OrderDetails[0].blah') = 1


-- What about "json_expert?"
SELECT CustomerID
FROM Person.PersonOrders_JSON 
WHERE JSON_PATH_EXISTS(CustomerJson, '$.json_expert') = 1

SELECT po.CustomerID
FROM Person.PersonOrders_JSON AS po
WITH (INDEX=[IX_PersonJSON_CustomerJson])
WHERE JSON_PATH_EXISTS(CustomerJson, '$.Orders[6]') = 1