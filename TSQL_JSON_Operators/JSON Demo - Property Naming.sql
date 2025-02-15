﻿-- To get this to work, I had to declare as nvarchar,
-- add an N' to preserve the emoji in the JSON and
-- JSON_VALUE path

DECLARE @_json nvarchar(4000) = N'
{
   "name":"Jeff Foushee"
   , "parents":[{"name":"Mom"},{"name":"Dad"}]
   , "json_expert":false
   , "🐶":"Bayly" 
   , "*~@#$%^&*()_+=><?/": "is a valid json"
   , "" : "this too"
}'

SELECT @_json
-- What happens to the dog emoji if you declare @_json 
-- as varchar instead of nvarchar?

-- The N' is the preserve the Unicode
SELECT JSON_VALUE(@_json, N'$."🐶"')      -- Bayly
-- What happens if you remove the "N'" from the previous line?

SELECT JSON_VALUE(@_json, '$."*~@#$%^&*()_+=><?/"') -- is a valid json
SELECT JSON_VALUE(@_json, '$.""')      -- this too