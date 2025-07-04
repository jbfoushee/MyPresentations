--------------------------------------------------------------------
-- REGEX demo: REGEXP_MATCHES, REGEXP_SPLIT_TO_TABLE
--------------------------------------------------------------------

-- Setup:

IF EXISTS (SELECT 1
            FROM sys.databases 
            WHERE name = DB_NAME()
              AND compatibility_level < 170)
    BEGIN
        DECLARE @_ErrMessage varchar(8000) = 
           CONCAT('Compatibility level too low for expected results.', CHAR(13), CHAR(13)
                   , 'Run "ALTER DATABASE [', DB_NAME(), '] SET COMPATIBILITY_LEVEL = 170;')
        RAISERROR(@_ErrMessage, 16, 1)
    END

--------------------------------------------------------------------
-- REGEXP_MATCHES 
--    ( string, RegExPtrn [, flags = 'c'] )

-- Returns a table of metadata for every occurrence 
-- of Regex pattern found within string.Nothing may 
-- be returned if no pattern-matches exist.
--------------------------------------------------------------------

SELECT *
FROM REGEXP_MATCHES
  ('Learning #AzureSQL #AzureSQLDB', '#([A-Za-z0-9_]+)');

SELECT *
FROM REGEXP_MATCHES
  ('Learning #AzureSQL #AzureSQLDB', '!([A-Za-z0-9_]+)');
--									  ^ difference

--------------------------------------------------------------------
-- REGEXP_SPLIT_TO_TABLE 
--    ( string, RegExPtrn [, flags = 'c'] )

-- Returns a table of metadata, each entry 
-- delimited from the original string by the 
-- pattern. Everything will be returned in one 
-- row if the delimiter pattern is not found.
--------------------------------------------------------------------

-- A statement that uses all letters of the 
-- alphabet is a "pangram."
SELECT *
FROM REGEXP_SPLIT_TO_TABLE
  ('the quick brown fox jumps over the lazy dog', '\s+');

SELECT *
FROM REGEXP_SPLIT_TO_TABLE
  ('the quick brown fox jumps over the lazy dog', '!');

