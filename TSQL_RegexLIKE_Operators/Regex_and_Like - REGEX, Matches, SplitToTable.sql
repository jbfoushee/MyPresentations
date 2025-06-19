--------------------------------------------------------------------
-- REGEX demo: REGEXP_MATCHES, REGEXP_SPLIT_TO_TABLE
--------------------------------------------------------------------

-- No setup

--------------------------------------------------------------------
-- REGEXP_MATCHES 
--    ( string, RegExPtrn [, flags = 'c'] )

-- Returns a table of metadata for every occurrence of Regex pattern found within string. 
-- Nothing may be returned if no pattern matches exist.
--------------------------------------------------------------------

SELECT *
FROM REGEXP_MATCHES
  ('Learning #AzureSQL #AzureSQLDB', '#([A-Za-z0-9_]+)');

SELECT *
FROM REGEXP_MATCHES
  ('Learning #AzureSQL #AzureSQLDB', '!([A-Za-z0-9_]+)');

--------------------------------------------------------------------
-- REGEXP_SPLIT_TO_TABLE 
--    ( string, RegExPtrn [, flags = 'c'] )

-- Returns a table of metadata, each entry delimited from the original string by the pattern.
-- Everything will be returned in one row if the delimiter pattern is not found.
--------------------------------------------------------------------

SELECT *
FROM REGEXP_SPLIT_TO_TABLE
  ('the quick brown fox jumps over the lazy dog', '\s+');

SELECT *
FROM REGEXP_SPLIT_TO_TABLE
  ('the quick brown fox jumps over the lazy dog', '!');