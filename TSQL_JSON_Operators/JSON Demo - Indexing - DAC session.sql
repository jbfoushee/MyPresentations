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

DECLARE @_$internal_object_name varchar(128)
DECLARE @_$parent_object_schema varchar(128)
DECLARE @_$parent_object_name varchar(128)

DECLARE MyCursor CURSOR FOR
    SELECT sit.[name] AS internal_object_name
      , SCHEMA_NAME(so.[schema_id]) AS parent_object_schema
      , so.[name] AS parent_object_name
    FROM sys.internal_tables sit
      INNER JOIN sys.objects so
          ON sit.parent_object_id = so.[object_id]
    WHERE internal_type_desc = 'JSON_INDEX_TABLE'

OPEN MyCursor
FETCH NEXT FROM MyCursor 
  INTO @_$internal_object_name, @_$parent_object_schema, @_$parent_object_name

-- Loop through the result set
WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @_newTableName varchar(128)
    SET @_newTableName = CONCAT(@_$parent_object_name, '__', @_$internal_object_name)
    
    DECLARE @_sql varchar(8000)
    SET @_sql = CONCAT('DROP TABLE IF EXISTS [', @_$parent_object_schema, '].[', @_newTableName, ']')

    EXEC(@_sql)

    SET @_sql = CONCAT(
        'SELECT * INTO [', @_$parent_object_schema, '].[', @_newTableName, '] ',
        'FROM sys.', @_$internal_object_name)

    EXEC(@_sql)

    FETCH NEXT FROM MyCursor 
        INTO @_$internal_object_name, @_$parent_object_schema, @_$parent_object_name
END

CLOSE MyCursor
DEALLOCATE MyCursor

-- Exit the DAC session once complete
---------------------------------------------------------------------------------
