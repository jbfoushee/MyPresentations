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


--Clear the proc cache of residue before starting
DBCC FREEPROCCACHE;
--------------------------------- End Setup -----------------------------------


-- Turn on "Display Actual Execution Plans" (Cntl-M)

-- Let's look for any customer whose last name is Young

SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'


-- Create our JSON index
CREATE JSON INDEX IXJ_PersonJSON_CustomerJson
ON Person.PersonOrders_JSON(CustomerJson)
   FOR ('$') -- path is root, so we are covering the contents
   WITH (DATA_COMPRESSION=PAGE, FILLFACTOR=80, PAD_INDEX=ON);


-- Let's look for any customer whose last name is Young
SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'


SELECT *
FROM Person.PersonOrders_JSON WITH (INDEX(IXJ_PersonJSON_CustomerJson), FORCESEEK)
WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'


CHECKPOINT;
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
DBCC FREESYSTEMCACHE ('ALL');
DBCC FREESESSIONCACHE;
EXEC sp_recompile 'Person.PersonOrders_JSON';
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
DBCC SHOW_STATISTICS ('Person.PersonOrders_JSON','PK_PersonOrders_JSON') WITH HISTOGRAM;
UPDATE STATISTICS sys.json_index_1895677801_1216000 WITH FULLSCAN; 
DBCC SHOW_STATISTICS ('sys.json_index_1895677801_1216000','IXJ_PersonJSON_CustomerJson') WITH HISTOGRAM;
OPTION (OPTIMIZE FOR UNKNOWN);

SELECT cp.plan_handle,
  st.text,
  qp.query_plan
FROM sys.dm_exec_cached_plans cp
  CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
  CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
WHERE st.text LIKE '%PersonOrders_JSON%'

AND Convert(varchar(max), query_plan) LIKE '%JSON Index Seek%'






-- Two things of note in the Execution Plan:
-- 1. We introduced a CONVERT_IMPLICIT warning. (What is the datatype being converted?)
-- 2. It may or may not have used the JSON index.

-- Improve Cardinality Feedback if "StatementEstRows=1"
-- Turn OFF "Display Actual Execution Plans" (Cntl-M) !!!

SELECT *
FROM Person.PersonOrders_JSON WITH (INDEX(IXJ_PersonJSON_CustomerJson), FORCESEEK)
WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'
OPTION (RECOMPILE)

DECLARE @_i int = 1
WHILE @_i < 100
	BEGIN
		SET NOCOUNT ON
		
		SELECT *
        FROM Person.PersonOrders_JSON WITH (INDEX(IXJ_PersonJSON_CustomerJson), FORCESEEK)
        WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'

		SET @_i += 1
	END
-- Turn on "Display Actual Execution Plans" (Cntl-M)


SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'
OPTION (RECOMPILE)

-- JSON index hits, Subtree cost of 0.064

SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_VALUE(CustomerJson,'$.json_expert') = Convert(bit, 1)
-- JSON index hits, Subtree cost of 0.006

SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_VALUE(CustomerJson,'$.json_expert') = Convert(bit, 1)
  AND JSON_VALUE(CustomerJson,'$.LastName') = 'Young'
-- JSON index hits twice, Subtree cost of 0.013




-- Even when you force the index, SQL may not want it...
-- Run together:

    SELECT *
    FROM Person.PersonOrders_JSON
    WHERE JSON_VALUE(CustomerJson,'$.Orders[1].SalesOrderNumber') = 'SO51421'
    -- Does not use JSON index

    SELECT *
    FROM Person.PersonOrders_JSON WITH (FORCESEEK)
    WHERE JSON_VALUE(CustomerJson,'$.Orders[1].SalesOrderNumber') = 'SO51421'
    -- Subtree cost of 0.879

    SELECT *
    FROM Person.PersonOrders_JSON WITH (INDEX(IXJ_PersonJSON_CustomerJson))
    WHERE JSON_VALUE(CustomerJson,'$.Orders[1].SalesOrderNumber') = 'SO51421'
    -- Subtree cost of 0.629


-- Let's search on an integer within the recordset...
    SELECT *
    FROM Person.PersonOrders_JSON
    WHERE CustomerID = 11002

    SELECT * FROM [Person].[PersonOrders_JSON__json_index_1895677801_1216000]
    WHERE posting_1 = 11002
    ORDER BY posting_1, json_path, LEN(json_array_index), json_array_index

--Which of these statements will run the fastest? Which the slowest?

    SELECT *
    FROM Person.PersonOrders_JSON
    WHERE JSON_VALUE(CustomerJson,'$.Orders[2].SalesOrderID') = 53237

    SELECT *
    FROM Person.PersonOrders_JSON
    WHERE JSON_VALUE(CustomerJson,'$.Orders[2].SalesOrderID' RETURNING int) = 53237
     
    SELECT *
    FROM Person.PersonOrders_JSON
    WHERE Convert(int, JSON_VALUE(CustomerJson,'$.Orders[2].SalesOrderID')) = 53237
    
    SELECT *
    FROM Person.PersonOrders_JSON
    WHERE JSON_VALUE(CustomerJson,'$.Orders[2].SalesOrderID') = '53237'



    -- Confused? JSON_VALUE returns nvarchar(4000)
    -- JSON index storage type is being forced into nvarchar(4000) by JSON_VALUE.
    -- Converting it again kills the option to use the JSON index