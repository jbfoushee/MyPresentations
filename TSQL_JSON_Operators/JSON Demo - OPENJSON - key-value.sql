DECLARE @_json varchar(8000) = '
{
   "name":"Jeff Foushee"
   , "parents":[{"name":"Mom"},{"name":"Dad"}]
   , "json_expert":false
}'

CREATE TABLE #json
( ArbitraryID int IDENTITY(1,1) NOT NULL
  , json_col varchar(8000) NOT NULL
)

INSERT INTO #json(json_col)
VALUES(@_json)
--------------------------------------------
-- Now this data is in a table

SELECT ArbitraryID, json_col
FROM #json

--------------------------------------------
-- How do I query the json column?

-- Normal CROSS APPLY
SELECT t.*
	, '|' AS '|'
	, ca.*
FROM #json t
  CROSS APPLY OPENJSON(t.json_col, '$') ca

--------------------------------------------
-- Put a label on all the columns

SELECT t.ArbitraryID AS [t.ArbitraryID]
	, t.json_col AS [t.json_col]
	, '|' AS '|'
	, ca.[key] AS [ca.key]
    , ca.[value] AS [ca.value]
	, ca.[type] AS [ca.type]
FROM #json t
  CROSS APPLY OPENJSON(t.json_col, '$') ca

-- and select only the JSON-based ones

SELECT -- t.ArbitraryID AS [t.ArbitraryID]
	-- , t.json_col AS [t.json_col]
	-- , '|' AS '|'
	 ca.[key] AS [ca.key]
    , ca.[value] AS [ca.value]
	, ca.[type] AS [ca.type]
FROM #json t
  CROSS APPLY OPENJSON(t.json_col, '$') ca

--------------------------------------------
-- If I want to break down more JSON,
-- I CROSS APPLY the next object downstream

-- **** (take a pic of this dataset for later) ****

SELECT t.ArbitraryID
	, t.json_col
	, '|' AS '|'
	, j.[key] AS [j.key]
    , j.[value] AS  [j.value]
	, '|' AS '|'
	, k.[key]
    , k.[value] AS [k.value]
    , JSON_VALUE(k.[value], '$.name') AS '$.name'
FROM #json t
  CROSS APPLY OPENJSON(t.json_col, '$') j
    CROSS APPLY OPENJSON(t.json_col, '$.parents') k

--------------------------------------------
-- The break-down of parents only applies to the "parents"
-- key, so I will introduce a WHERE filter

SELECT t.ArbitraryID
	, t.json_col
	, '|' AS '|'
	, j.[key] AS [j.key]
    , j.[value] AS  [j.value]
	, '|' AS '|'
    , k.[key]
    , k.[value] AS [k.value]
    , JSON_VALUE(k.[value], '$.name') AS '$.name'
FROM #json t
  CROSS APPLY OPENJSON(t.json_col, '$') j
    CROSS APPLY OPENJSON(t.json_col, '$.parents') k
WHERE j.[key] = 'parents'

--------------------------------------------
-- And rather than OPENJSON the entire json each time,
-- I will create a dependency between the CROSS APPLY statements
-- (There will be no change in output)

SELECT t.ArbitraryID
	, t.json_col
	, '|' AS '|'
	, j.[key] AS [j.key]
    , j.[value] AS [j.value]
	, '|' AS '|'
    , k.[key]
    , k.[value] AS [k.value]
    , JSON_VALUE(k.[value], '$.name') AS '$.name'
FROM #json t
  CROSS APPLY OPENJSON(t.json_col, '$') j
    CROSS APPLY OPENJSON(j.[value], '$') k  
					--   ^^^^^^^^^  my 'root' starts here now
WHERE j.[key] = 'parents'

--What happens if I remove (comment) the WHERE clause now?
--Review the pic of the earlier dataset;
--Hint 1: How would OPENJSON react to a value that isn't a JSON object/array?
--Hint 2: Too bad CROSS APPLY doesn't ON+AND like JOIN. What if you replace 
		WHERE j.[key] = 'parents'
--   with
		WHERE ISJSON(j.[value]) = 1

--------------------------------------------
--Add another row to the table

DECLARE @_json varchar(8000) = '
{
   "name":"Jesús Castillo"
   , "parents":[{"name":"Mary"},{"name":"Joseph"}]
   , "json_expert":true
}
'

INSERT INTO #json VALUES (@_json)

--------------------------------------------
SELECT * FROM #json

--------------------------------------------
-- Does the CROSS APPLY still work?

SELECT t.ArbitraryID
	, t.json_col
	, '|' AS '|'
	, j.[key] AS [j.key]
    , j.[value] AS  [j.value]
	, '|' AS '|'
    , k.[value] AS [k.value]
    , JSON_VALUE(k.[value], '$.name') AS '$.name'
FROM #json t
  CROSS APPLY OPENJSON(t.json_col, '$') j
    CROSS APPLY OPENJSON(j.[value], '$') k
WHERE j.[key] = 'parents'

-- Yes!

---------------------------------------------
-- Change the 2 rows into a one-row array-based JSON

DELETE FROM #json

DECLARE @_json varchar(8000) = '
[{
   "name":"Jeff Foushee"
   , "parents":[{"name":"Mom"},{"name":"Dad"}]
   , "json_expert":false
},
{
   "name":"Jesús Castillo"
   , "parents":[{"name":"Mary"},{"name":"Joseph"}]
   , "json_expert":true
}]
'

INSERT INTO #json VALUES (@_json)

--------------------------------------------------
-- Does our original CROSS APPLY statement work?

SELECT t.ArbitraryID
	, t.json_col
	, '|' AS '|'
	, j.[key] AS [j.key]
    , j.[value] AS  [j.value]
	, '|' AS '|'
    , k.[value] AS [k.value]
    , JSON_VALUE(k.[value], '$.name') AS '$.name'
FROM #json t
  CROSS APPLY OPENJSON(t.json_col, '$') j
    CROSS APPLY OPENJSON(j.[value], '$') k
WHERE j.[key] = 'parents'

-- It 'works', but we get no data 
-- because all the data shifted down one indentation

--------------------------------------------------

SELECT t.ArbitraryID
	, t.json_col
	, '|' AS '|'
    , j.[key] AS [j.key]
    , j.[value] AS  [j.value]
    , '|' AS '|'
	, k.[key] AS [k.key]
    , k.[value] AS [k.value]
FROM #json t
  CROSS APPLY OPENJSON(t.json_col, '$') j
    CROSS APPLY OPENJSON(j.[value], '$') k

-- For one, j.key is now an integer

------------------------------------------------
-- Let's introduce yet another CROSS APPLY because of
-- the indentation-shift, filter on k.key being "parents"

SELECT t.ArbitraryID
	--, t.json_col
	, '|' AS '|'
    , j.[key] AS [j.key]
    , j.[value] AS  [j.value]
    , '|' AS '|'
	, k.[key]
    , k.[value] AS [k.value]
	, '|' AS '|'
	, l.[key]
    , l.[value] AS [l.value]
FROM #json t
  CROSS APPLY OPENJSON(t.json_col, '$') j
    CROSS APPLY OPENJSON(j.[value], '$') k
	   CROSS APPLY OPENJSON(k.[value], '$') l
WHERE k.[key] = 'parents'

-----------------------------------------------
-- Now we have the query we want

SELECT t.ArbitraryID
	--, t.json_col
	, '|' AS '|'
    , j.[key] AS [j.key]
    , j.[value] AS  [j.value]
    , '|' AS '|'
	, k.[key]
    , k.[value] AS [k.value]
	, '|' AS '|'
	, l.[key]
    , l.[value] AS [l.value]
	, JSON_VALUE(l.[value], '$.name') AS '$.name'  --added
FROM #json t
  CROSS APPLY OPENJSON(t.json_col, '$') j
    CROSS APPLY OPENJSON(j.[value], '$') k
	   CROSS APPLY OPENJSON(k.[value], '$') l
WHERE k.[key] = 'parents'

