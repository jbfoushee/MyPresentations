DECLARE @_json varchar(8000) = '
{
   "name":"Jeff Foushee"
   , "parents":[{"name":"Mom"},{"name":"Dad"}]
   , "json_expert":false
   , "spouse_name":"Ann Onymous" 
   , "children":[]
}'


	SELECT 'JSON_VALUE' AS [Function], '$' AS [path], JSON_VALUE(@_json, '$') AS Value
	UNION SELECT 'JSON_VALUE', '$.parents', JSON_VALUE(@_json, '$.parents')
	UNION SELECT 'JSON_VALUE', '$.name', JSON_VALUE(@_json, '$.name')
	UNION SELECT 'JSON_VALUE', '$.parents[0]', JSON_VALUE(@_json, '$.parents[0]')
	UNION SELECT 'JSON_VALUE', '$.parents[0].name', JSON_VALUE(@_json, '$.parents[0].name')
	UNION SELECT 'JSON_VALUE', '$.parents[1].name', JSON_VALUE(@_json, '$.parents[1].name')
	UNION SELECT 'JSON_VALUE', '$.json_expert', JSON_VALUE(@_json, '$.json_expert')
	UNION SELECT 'JSON_VALUE', '$.spouse_name', JSON_VALUE(@_json, '$.spouse_name')
	UNION SELECT 'JSON_VALUE', '$.children', JSON_VALUE(@_json, '$.children')

	UNION SELECT 'JSON_QUERY', '$', JSON_QUERY(@_json, '$')
	UNION SELECT 'JSON_QUERY', '$.parents', JSON_QUERY(@_json, '$.parents')
	UNION SELECT 'JSON_QUERY', '$.name', JSON_QUERY(@_json, '$.name')
	UNION SELECT 'JSON_QUERY', '$.parents[0]', JSON_QUERY(@_json, '$.parents[0]')
	UNION SELECT 'JSON_QUERY', '$.parents[0].name', JSON_QUERY(@_json, '$.parents[0].name')
	UNION SELECT 'JSON_QUERY', '$.parents[1].name', JSON_QUERY(@_json, '$.parents[1].name')
	UNION SELECT 'JSON_QUERY', '$.json_expert', JSON_QUERY(@_json, '$.json_expert')
	UNION SELECT 'JSON_QUERY', '$.spouse_name', JSON_QUERY(@_json, '$.spouse_name')
	UNION SELECT 'JSON_QUERY', '$.children', JSON_QUERY(@_json, '$.children')

---------------------------------------------------------------------
-- PIVOT the results..

DECLARE @_json varchar(8000) = '
{
   "name":"Jeff Foushee"
   , "parents":[{"name":"Mom"},{"name":"Dad"}]
   , "json_expert":false
   , "spouse_name":"Ann Onymous" 
   , "children":[]
}'

SELECT PivotResults.*
FROM
(
	SELECT 'JSON_VALUE' AS [Function], '$' AS [path], JSON_VALUE(@_json, '$') AS Value
	UNION SELECT 'JSON_VALUE', '$.parents', JSON_VALUE(@_json, '$.parents')
	UNION SELECT 'JSON_VALUE', '$.name', JSON_VALUE(@_json, '$.name')
	UNION SELECT 'JSON_VALUE', '$.parents[0]', JSON_VALUE(@_json, '$.parents[0]')
	UNION SELECT 'JSON_VALUE', '$.parents[0].name', JSON_VALUE(@_json, '$.parents[0].name')
	UNION SELECT 'JSON_VALUE', '$.parents[1].name', JSON_VALUE(@_json, '$.parents[1].name')
	UNION SELECT 'JSON_VALUE', '$.json_expert', JSON_VALUE(@_json, '$.json_expert')
	UNION SELECT 'JSON_VALUE', '$.spouse_name', JSON_VALUE(@_json, '$.spouse_name')
	UNION SELECT 'JSON_VALUE', '$.children', JSON_VALUE(@_json, '$.children')

	UNION SELECT 'JSON_QUERY', '$', JSON_QUERY(@_json, '$')
	UNION SELECT 'JSON_QUERY', '$.parents', JSON_QUERY(@_json, '$.parents')
	UNION SELECT 'JSON_QUERY', '$.name', JSON_QUERY(@_json, '$.name')
	UNION SELECT 'JSON_QUERY', '$.parents[0]', JSON_QUERY(@_json, '$.parents[0]')
	UNION SELECT 'JSON_QUERY', '$.parents[0].name', JSON_QUERY(@_json, '$.parents[0].name')
	UNION SELECT 'JSON_QUERY', '$.parents[1].name', JSON_QUERY(@_json, '$.parents[1].name')
	UNION SELECT 'JSON_QUERY', '$.json_expert', JSON_QUERY(@_json, '$.json_expert')
	UNION SELECT 'JSON_QUERY', '$.spouse_name', JSON_QUERY(@_json, '$.spouse_name')
	UNION SELECT 'JSON_QUERY', '$.children', JSON_QUERY(@_json, '$.children')
) RawData
PIVOT
( MAX([Value])
  FOR [Function] IN ([JSON_QUERY], [JSON_VALUE])
) PivotResults

-- Change "Ann Onymous" to NULL. What happens?
-- Can you tell a difference between a legit NULL value,
-- and a illegit NULL value (called by the wrong function usage)?