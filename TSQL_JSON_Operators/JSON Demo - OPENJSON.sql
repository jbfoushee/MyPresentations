DECLARE @_json varchar(8000) = '
{
   "name":"Jeff Foushee"
   , "parents":[{"name":"Mom"},{"name":"Dad"}]
   , "json_expert":false
}'

SELECT j.[key] AS [j.key]
    , j.[value] AS  [j.value]
FROM OPENJSON(@_json, '$') j

CREATE TABLE #json
( ArbitaryID int IDENTITY(1,1) NOT NULL
  , json_col varchar(8000) NOT NULL
)

INSERT INTO #json(json_col)
VALUES(@_json)
--------------------------------------------
-- Now this data is in a table

SELECT ArbitaryID, json_col
FROM #json

--------------------------------------------
-- How do I query the json column?
SELECT t.json_col
FROM #json t

SELECT j.
FROM OPENJSON(t.json_col) j
     FROM #json t

SELECT t.json_col, j.*
FROM #json t
  CROSS APPLY OPENJSON(json_col, '$') j

--------------------------------------------
-- We select from the table and CROSS APPLY the json column

SELECT t.ArbitaryID
	, t.json_col
	, '|' AS '|'
	, j.[key] AS [j.key]
    , j.[value] AS [j.value]
	, j.[type] AS [j.type]
FROM #json t
  CROSS APPLY OPENJSON(json_col, '$') j

--------------------------------------------
-- If I want to break down more JSON,
-- I CROSS APPLY the next object downstream

-- **** (take a pic of this dataset for later) ****

SELECT t.ArbitaryID
	, t.json_col
	, '|' AS '|'
	, j.[key] AS [j.key]
    , j.[value] AS  [j.value]
	, '|' AS '|'
	, k.[key]
    , k.[value] AS [k.value]
    , JSON_VALUE(k.[value], '$.name') AS '$.name'
FROM #json t
  CROSS APPLY OPENJSON(json_col, '$') j
    CROSS APPLY OPENJSON(json_col, '$.parents') k

--------------------------------------------
-- The break-down of parents only applies to the "parents"
-- key, so I will introduce a WHERE filter

SELECT t.ArbitaryID
	, t.json_col
	, '|' AS '|'
	, j.[key] AS [j.key]
    , j.[value] AS  [j.value]
	, '|' AS '|'
    , k.[key]
    , k.[value] AS [k.value]
    , JSON_VALUE(k.[value], '$.name') AS '$.name'
FROM #json t
  CROSS APPLY OPENJSON(json_col, '$') j
    CROSS APPLY OPENJSON(json_col, '$.parents') k
WHERE j.[key] = 'parents'

--------------------------------------------
-- And rather than OPENJSON the entire json each time,
-- I will create a dependency between the CROSS APPLY statements

SELECT t.ArbitaryID
	, t.json_col
	, '|' AS '|'
	, j.[key] AS [j.key]
    , j.[value] AS [j.value]
	, '|' AS '|'
    , k.[key]
    , k.[value] AS [k.value]
    , JSON_VALUE(k.[value], '$.name') AS '$.name'
FROM #json t
  CROSS APPLY OPENJSON(json_col, '$') j
    CROSS APPLY OPENJSON(j.[value], '$') k
WHERE j.[key] = 'parents'

--What happens if I remove (comment) the WHERE clause now?

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

SELECT t.ArbitaryID
	, t.json_col
	, '|' AS '|'
	, j.[key] AS [j.key]
    , j.[value] AS  [j.value]
	, '|' AS '|'
    , k.[value] AS [k.value]
    , JSON_VALUE(k.[value], '$.name') AS '$.name'
FROM #json t
  CROSS APPLY OPENJSON(json_col, '$') j
    CROSS APPLY OPENJSON(j.[value], '$') k
WHERE j.[key] = 'parents'

---------------------------------------------
-- Change the 2 rows into 1 row with an array-based JSON

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

SELECT t.ArbitaryID
	, t.json_col
	, '|' AS '|'
	, j.[key] AS [j.key]
    , j.[value] AS  [j.value]
	, '|' AS '|'
    , k.[value] AS [k.value]
    , JSON_VALUE(k.[value], '$.name') AS '$.name'
FROM #json t
  CROSS APPLY OPENJSON(json_col, '$') j
    CROSS APPLY OPENJSON(j.[value], '$') k
WHERE j.[key] = 'parents'

-- No, because all the data shifted down one indentation

--------------------------------------------------

SELECT t.ArbitaryID
	, t.json_col
	, '|' AS '|'
    , j.[key] AS [j.key]
    , j.[value] AS  [j.value]
    , '|' AS '|'
	, k.[key] AS [k.key]
    , k.[value] AS [k.value]
FROM #json t
  CROSS APPLY OPENJSON(json_col, '$') j
    CROSS APPLY OPENJSON(j.[value], '$') k

-- For one, j.key is now an integer

------------------------------------------------
-- Let's introduce yet another CROSS APPLY because of
-- the indentation-shift, filter on k.key being "parents"

SELECT t.ArbitaryID
	, t.json_col
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
  CROSS APPLY OPENJSON(json_col, '$') j
    CROSS APPLY OPENJSON(j.[value], '$') k
	   CROSS APPLY OPENJSON(k.[value], '$') l
WHERE k.[key] = 'parents'

-----------------------------------------------
-- Now we have the query we want

SELECT t.ArbitaryID
	, t.json_col
	, '|' AS '|'
    , j.[key] AS [j.key]
    , j.[value] AS  [j.value]
    , '|' AS '|'
	, k.[key]
    , k.[value] AS [k.value]
	, '|' AS '|'
	, l.[key]
    , l.[value] AS [l.value]
	, JSON_VALUE(l.[value], '$.name') AS '$.name'
FROM #json t
  CROSS APPLY OPENJSON(json_col, '$') j
    CROSS APPLY OPENJSON(j.[value], '$') k
	   CROSS APPLY OPENJSON(k.[value], '$') l
WHERE k.[key] = 'parents'

--------------------------------------------------
-- What would happen if we didn't form a relationship
-- between the CROSS APPLY statements? If every one
-- referenced json_col again?

SELECT t.ArbitaryID
	, t.json_col
	, '|' AS '|'
    , j.[key] AS [j.key]
    , j.[value] AS  [j.value]
    , '|' AS '|'
	, k.[key]
    , k.[value] AS [k.value]
	, '|' AS '|'
	, l.[key]
    , l.[value] AS [l.value]
	, JSON_VALUE(l.[value], '$.name') AS '$.name'
FROM #json t
  CROSS APPLY OPENJSON(json_col, '$') j
    CROSS APPLY OPENJSON(json_col, '$') k
	   CROSS APPLY OPENJSON(json_col, '$') l
WHERE k.[key] = 'parents'

-- Comment out   WHERE k.[key] = 'parents'
-- Now what happens?