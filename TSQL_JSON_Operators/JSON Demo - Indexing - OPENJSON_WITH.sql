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

-- By using OPENJSON+WITH, we can use the JSON index.
SELECT *
FROM Person.PersonOrders_JSON
  CROSS APPLY OPENJSON(CustomerJson)
      WITH (LastName varchar(50) '$.LastName') AS j
WHERE j.LastName = 'Young';

-- but yet this statement is faster without the JSON index
SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'
