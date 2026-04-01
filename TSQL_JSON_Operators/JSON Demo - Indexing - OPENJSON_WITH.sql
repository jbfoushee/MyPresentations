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

-- Turn on "Display Actual Execution Plans" (Cntl-M)

--Create the JSON index

CREATE JSON INDEX IXJ_PersonJSON_CustomerJson
ON Person.PersonOrders_JSON(CustomerJson)
   FOR ('$') -- path is root, so we are covering the contents
   WITH (DATA_COMPRESSION=PAGE, FILLFACTOR=80, PAD_INDEX=ON);


-- Let's locate who ordered SalesOrderNumber SO43793
-- Run together:

    SELECT poj.*, JSON_VALUE(Orders.value, '$.SalesOrderNumber')
    FROM Person.PersonOrders_JSON poj
      CROSS APPLY OPENJSON(poj.CustomerJson, '$.Orders') AS Orders
    WHERE JSON_VALUE(Orders.value, '$.SalesOrderNumber') = 'SO43793'

    SELECT poj.*, ord.SalesOrderNumber
    FROM Person.PersonOrders_JSON AS poj
      CROSS APPLY OPENJSON(poj.CustomerJson, '$.Orders')
         WITH (
            SalesOrderNumber varchar(7) '$.SalesOrderNumber'
         ) AS ord
    WHERE ord.SalesOrderNumber = 'SO43793';




-- Let's locate all customers who ever placed an order under $3

SELECT *
FROM
(
    SELECT poj.*, JSON_VALUE([Order].value, '$.TotalDue') AS TotalDue
    FROM Person.PersonOrders_JSON poj
      CROSS APPLY OPENJSON(poj.CustomerJson, '$') AS Orders
         CROSS APPLY OPENJSON(Orders.value, '$') AS [Order]
    WHERE Orders.[key] = 'Orders'
) a
WHERE TRY_CONVERT(decimal(18,4), TotalDue) < 3
-- We see a merge of our Clustered Index Scan and two TVFs (OPENJSON). 
-- A subtree count of 23.2


SELECT *
FROM
(
    SELECT poj.*, JSON_VALUE([Order].value, '$.TotalDue') AS TotalDue
    FROM Person.PersonOrders_JSON poj
      CROSS APPLY OPENJSON(poj.CustomerJson, '$.Orders') AS [Order] --<-- just shred at a lower
                                                                       -- starting location
) a
WHERE TRY_CONVERT(decimal(18,4), TotalDue) < 3
-- We didn't take advantage of JSON index, 
-- but our subtree cost went to 3.38, an 85% improvement




-- JSON_VALUE is removed. Change the OPENJSON to an OPENJSON/WITH
SELECT 
    poj.*,
    ord.TotalDue
FROM Person.PersonOrders_JSON AS poj
  CROSS APPLY OPENJSON(poj.CustomerJson, '$.Orders')
     WITH (
        TotalDue decimal(18,4) '$.TotalDue'
     ) AS ord
WHERE ord.TotalDue < 3;
-- This took advantage of the JSON index. Subtree cost of 0.822




-- But OPENJSON/WITH is not necessarily the answer to everything
-- Run these statements together with Execution Plans:

    -- OPENJSON+WITH
    SELECT p.*
    FROM Person.PersonOrders_JSON p
      CROSS APPLY OPENJSON(CustomerJson)
          WITH (LastName varchar(50) '$.LastName') AS j
    WHERE j.LastName = 'Young';

    -- Convert(varchar(max)) + LIKE
    SELECT *
    FROM Person.PersonOrders_JSON
    WHERE Convert(varchar(max), CustomerJson) LIKE '%"LastName":"Young"%'

    -- JSON_VALUE
    SELECT *
    FROM Person.PersonOrders_JSON
    WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'