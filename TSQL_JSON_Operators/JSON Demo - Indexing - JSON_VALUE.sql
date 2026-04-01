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
   WITH (DATA_COMPRESSION=PAGE, FILLFACTOR=80, PAD_INDEX=ON);


-- Let's look for any customer whose last name is Young
SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'
-- Two things of note in the Execution Plan:
-- 1. We introduced a CONVERT_IMPLICIT warning. (What is the datatype being converted?)
--    However, this is not the reason it went with the Clustered Index Scan.
--    It is just noise.
-- 2. I cannot guarantee that it did or did not pick the JSON Index Seek at this point.
--    Things that encourage the condition we want (which is to NOT use the JSON index)
--       1. Remove the AdventureWorks2025 database.
--       2. Restart the MSSQL Service.
--       3. Restore the AdventureWorks2025 database.
--       4. Run the CREATE JSON Index script from top to bottom.
--       5. Run this JSON_VALUE script to this line.



-- What's the subtree cost of the original statement? (0.576)


-- It's not using the JSON index.
-- Review the Execution Plan for StatementEstRows and SamplingPercent
-- Can we force it?
SELECT *
FROM Person.PersonOrders_JSON WITH (INDEX(IXJ_PersonJSON_CustomerJson), FORCESEEK)
WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'
-- Review if Subtree cost is better (and it's not!? Over 2.0)

-- Run together to compare
    SELECT *
    FROM Person.PersonOrders_JSON
    WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'

    SELECT *
    FROM Person.PersonOrders_JSON WITH (INDEX(IXJ_PersonJSON_CustomerJson), FORCESEEK)
    WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'


-- Let's remove all these plans from the cache...

    DECLARE @_planhandle varbinary(400)

    WHILE 1 = 1
        BEGIN
            SET @_planhandle = NULL

            SELECT TOP 1 @_planhandle = cp.plan_handle -- , st.text, qp.query_plan
            FROM sys.dm_exec_cached_plans cp
              CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
              CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
            WHERE st.text LIKE '%PersonOrders_JSON%'
              
            IF @_planhandle IS NULL
                BREAK

            DBCC FREEPROCCACHE(@_planhandle)
        END

    DROP INDEX IXJ_PersonJSON_CustomerJson ON Person.PersonOrders_JSON

    -- Create our JSON index
    CREATE JSON INDEX IXJ_PersonJSON_CustomerJson
    ON Person.PersonOrders_JSON(CustomerJson)
       FOR ('$') -- path is root, so we are covering the contents
       WITH (DATA_COMPRESSION=PAGE, FILLFACTOR=80, PAD_INDEX=ON, OPTIMIZE_FOR_ARRAY_SEARCH = ON);
                                                          --     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                                                          -- Add this parameter even if unneeded

-- Run the indexed version with OPTION (OPTIMIZE FOR UNKNOWN)
-- This will ignore the parameter values, use statistics to generate the plan
    SELECT *
    FROM Person.PersonOrders_JSON
    WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'

    SELECT *
    FROM Person.PersonOrders_JSON WITH (INDEX(IXJ_PersonJSON_CustomerJson), FORCESEEK)
    WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'
    OPTION (OPTIMIZE FOR UNKNOWN, RECOMPILE)


-- Note the subtree costs of the queries. Now run them individually. What happened?


-- Let's see how the original statement looks like now:

SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_VALUE(CustomerJson,'$.LastName') = 'Young'
--It uses the JSON Index now without explicity using 4 hints.

/* ------------------------------------
---    The graveyard of ideas 
---------------------------------------
CHECKPOINT;
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
DBCC FREESYSTEMCACHE ('ALL');
DBCC FREESESSIONCACHE;
EXEC sp_recompile 'Person.PersonOrders_JSON';
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
DBCC SHOW_STATISTICS ('Person.PersonOrders_JSON','PK_PersonOrders_JSON') WITH HISTOGRAM;
UPDATE STATISTICS sys.json_index_1895677801_1216000 WITH FULLSCAN; 
UPDATE STATISTICS sys.json_index_1895677801_1216000 _WA_Sys_00000004_74CE504D WITH FULLSCAN;
DBCC SHOW_STATISTICS('sys.json_index_1895677801_1216000', '_WA_Sys_00000002_74CE504D')
DBCC SHOW_STATISTICS('sys.json_index_1895677801_1216000','IXJ_PersonJSON_CustomerJson') WITH HISTOGRAM;
ALTER INDEX [IXJ_PersonJSON_CustomerJson] ON [Person].[PersonOrders_JSON] REBUILD
SELECT... FROM... OPTION (RECOMPILE);
SELECT... FROM... OPTION (OPTIMIZE FOR UNKNOWN);
OPTION (TABLE HINT( Person.PersonOrders_JSON, FORCESEEK))
*/


SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_VALUE(CustomerJson,'$.json_expert') = Convert(bit, 1)
-- JSON index hits, Subtree cost of 0.006


SELECT *
FROM Person.PersonOrders_JSON
WHERE JSON_VALUE(CustomerJson,'$.json_expert') = Convert(bit, 1)
  AND JSON_VALUE(CustomerJson,'$.LastName') = 'Young'
-- JSON index hits twice, Subtree cost of 0.013




-- Let's search on an integer within the recordset...
    --SELECT *
    --FROM Person.PersonOrders_JSON
    --WHERE CustomerID = 11002

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


