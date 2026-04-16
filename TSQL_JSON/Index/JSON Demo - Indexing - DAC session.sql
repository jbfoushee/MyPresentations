-- This script manifests your JSON indexes into viewable tables
--   -- view their contents
--   -- estimate their impact on database space
-- No warranties, explicit or implied exist with this script. - Jeff Foushee

-- 1. Begin a DAC session...
--     Setup: Need to activate DAC?
--         Configure SQL Server Configuration Manager. 
--             Expand SQL Server Network Configuration → Protocols → Enable TCP/IP.
--             Restart SQL Service
--         Issue SQL script: EXEC sp_configure 'remote admin connections', 1; RECONFIGURE;

--     1a. Click the "Database Engine Query" button (the button to the right of New Query)
--         Keep the same connection string, but prefix the servername with "ADMIN:"
--     1b. Or change the current session to a DAC connection:
--         Go to the [Q]uery menuitem, Connection, Change Connection...
--             Keep the same connection string, but prefix the servername with "ADMIN:"

--   Don't forget you can only have 1 DAC session globally to this server
--   (Don't accidentally make it the one to SSMS Object Explorer!)

-- 2. Issue this:

USE AdventureWorks2025

-- Touch nothing below this line
--------------------------------------------------------------------------------

DECLARE @_endpoint_name varchar(128) 
SELECT @_endpoint_name  = e.name
FROM sys.dm_exec_sessions s
  LEFT JOIN sys.tcp_endpoints e
    ON s.endpoint_id = e.endpoint_id
WHERE s.session_id = @@SPID

IF IsNull(@_endpoint_name,'') != 'Dedicated Admin Connection'
    RAISERROR('You must be running this from the Dedicated Admin Connection (DAC)', 20, 1) WITH LOG


DECLARE @_$parent_object_schema varchar(128)
DECLARE @_$parent_object_name varchar(128)
DECLARE @_$clus_index_name varchar(128)
DECLARE @_$internal_object_name varchar(128)
DECLARE @_opt_array_search bit

DECLARE MyCursor CURSOR FOR
    SELECT SCHEMA_NAME(t.schema_id) AS parent_object_schema
        , t.name AS parent_object_name
        , ind.name AS clus_IndexName
        , sit.[name] AS internal_object_name
        , sji.optimize_for_array_search
    FROM sys.indexes ind
      INNER JOIN sys.json_indexes sji
          ON ind.object_id = sji.object_id
          AND ind.index_id = sji.index_id
      INNER JOIN sys.index_columns ic
          ON ind.object_id = ic.object_id
          AND ind.index_id  = ic.index_id
        INNER JOIN sys.columns col
            ON ic.object_id = col.object_id
            AND ic.column_id = col.column_id
        INNER JOIN sys.tables t
            ON ind.object_id = t.object_id
          INNER JOIN sys.internal_tables sit
              ON t.object_id = sit.parent_object_id
              AND ind.index_id = sit.parent_minor_id
    WHERE ind.is_primary_key = 0
      AND ind.is_unique = 0
      AND ind.is_unique_constraint = 0
      AND t.is_ms_shipped = 0
      AND ind.type_desc = 'JSON'


OPEN MyCursor
FETCH NEXT FROM MyCursor 
  INTO @_$parent_object_schema, @_$parent_object_name, @_$clus_index_name
    , @_$internal_object_name, @_opt_array_search

-- Loop through the result set
WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @_newTableName varchar(128)
    SET @_newTableName = CONCAT(@_$parent_object_name, '__', @_$internal_object_name)
    
    DECLARE @_sql varchar(8000)
    SET @_sql = CONCAT('DROP TABLE IF EXISTS [', @_$parent_object_schema, '].[', @_newTableName, ']')

    PRINT REPLICATE('-', 80)
    PRINT 'Removing older versions of manifested tables if they exist...'
    PRINT REPLICATE('-', 80)
    EXEC(@_sql)

    DECLARE @_postingPKs varchar(7000)

    SELECT @_postingPKs = STRING_AGG(QUOTENAME(c.name), ', ') 
         WITHIN GROUP (ORDER BY c.column_id) 
    FROM sys.columns c
      INNER JOIN sys.internal_tables t ON c.object_id = t.object_id
        INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name = @_$internal_object_name
      AND s.name = 'sys'
      AND c.name LIKE 'posting%'

    PRINT REPLICATE('-', 80)
    PRINT CONCAT('Creating new table from sys.[', @_$internal_object_name, ']...')
    PRINT REPLICATE('-', 80)
    SET @_sql = CONCAT(
        'SELECT * INTO [', @_$parent_object_schema, '].[', @_newTableName, '] ',
        'FROM sys.', @_$internal_object_name)

    EXEC(@_sql)
    
    DECLARE @index_count tinyint = 2
    SET @index_count += Convert(tinyint, @_opt_array_search)

    PRINT REPLICATE('-', 80)
    PRINT CONCAT('Creating ', @index_count,' indexes...')
    PRINT REPLICATE('-', 80)
    SET @_sql = CONCAT(
        'CREATE CLUSTERED INDEX [', @_$clus_index_name, '] ',
        ' ON [', @_$parent_object_schema, '].[', @_newTableName, '] ', 
        '  ([json_path], [json_array_index], [sql_value])')

    EXEC(@_sql)

    SET @_sql = CONCAT(
        'CREATE NONCLUSTERED INDEX [json_index_posting_col_nci]  ',
        ' ON [', @_$parent_object_schema, '].[', @_newTableName, '] ', 
        '  (', @_postingPKs, ')')

    EXEC(@_sql)

    IF (@_opt_array_search = 1)
        BEGIN

            SET @_sql = CONCAT(
                'CREATE NONCLUSTERED INDEX [json_index_search_optimization_nci] ',
                ' ON [', @_$parent_object_schema, '].[', @_newTableName, '] ', 
                '  ([json_path], [sql_value], [json_array_index], [status]) 
                  INCLUDE (', @_postingPKs, ')')

            EXEC(@_sql)     

        END


    FETCH NEXT FROM MyCursor 
        INTO @_$parent_object_schema, @_$parent_object_name, @_$clus_index_name
            , @_$internal_object_name, @_opt_array_search
END

CLOSE MyCursor
DEALLOCATE MyCursor

-- Exit the DAC session once complete
---------------------------------------------------------------------------------

PRINT REPLICATE('-', 80)
PRINT 'Be sure to delete the objects after your investigation.'
PRINT 'They offer no benefit, take up space, and go stale.'