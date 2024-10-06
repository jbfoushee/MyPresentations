DECLARE @_json varchar(8000) = '
{
   "name":"Jeff Foushee"
   , "parents":[{"name":"Mom"},{"name":"Dad"}]
   , "json_expert":false
}'

SELECT [name]
    , parents
	, json_expert
FROM OPENJSON(@_json, '$')
       WITH ( [name] nvarchar(255)
	          , parents nvarchar(MAX) AS JSON
			  , json_expert bit
			) j

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
SELECT t.json_col
FROM #json t

SELECT *
FROM #json t
  CROSS APPLY OPENJSON(t.json_col, '$')
       WITH ( [name] nvarchar(255)
	          , parents nvarchar(MAX) AS JSON
			  , json_expert bit
			) j

--------------------------------------------
-- We select from the table and CROSS APPLY the json column

SELECT t.ArbitraryID AS [t.ArbitraryID]
	, t.json_col AS [t.json_col]
	, '|' AS '|'
	, j.[name] AS [j.name]
    , j.parents AS [j.parents]
	, j.json_expert AS [j.json_expert]
FROM #json t
  CROSS APPLY OPENJSON(t.json_col, '$')
       WITH ( [name] nvarchar(255)
	          , parents nvarchar(MAX) AS JSON
			  , json_expert bit
			) j

SELECT -- t.ArbitraryID AS [t.ArbitraryID]
	-- , t.json_col AS [t.json_col]
	-- , '|' AS '|'
	 j.[name] AS [j.name]
    , j.parents AS [j.parents]
	, j.json_expert AS [j.json_expert]
FROM #json t
  CROSS APPLY OPENJSON(t.json_col, '$')
       WITH ( [name] nvarchar(255)
	          , parents nvarchar(MAX) AS JSON
			  , json_expert bit
			) j

--------------------------------------------
-- If I want to break down more JSON,
-- I CROSS APPLY the next object downstream

-- **** (take a pic of this dataset for later) ****

SELECT t.ArbitraryID
	, t.json_col
	, '|' AS '|'
	, j.[name] AS [j.name]
    , j.[json_expert] AS [j.json_expert]
	, '|' AS '|'
	, k.[name] AS [k.name]
FROM #json t
  CROSS APPLY OPENJSON(t.json_col, '$')
       WITH ( [name] nvarchar(255)
	          , parents nvarchar(MAX) AS JSON
			  , json_expert bit
			) j
    CROSS APPLY OPENJSON(t.json_col, '$.parents')
		WITH
		    ( 
			  [name] nvarchar(255) 
			) k

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
  CROSS APPLY OPENJSON(json_col, '$') j
    CROSS APPLY OPENJSON(json_col, '$.parents') k
WHERE j.[key] = 'parents'

--------------------------------------------
-- And rather than OPENJSON the entire json each time,
-- I will create a dependency between the CROSS APPLY statements

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
  CROSS APPLY OPENJSON(json_col, '$') j
    CROSS APPLY OPENJSON(j.[value], '$') k  --this line changed
WHERE j.[key] = 'parents'

--What happens if I remove (comment) the WHERE clause now?
--Review the pic of the earlier dataset;
--How would OPENJSON react to a value that isn't JSON?

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

SELECT t.ArbitraryID
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

SELECT t.ArbitraryID
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

SELECT t.ArbitraryID
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

SELECT t.ArbitraryID
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
	, JSON_VALUE(l.[value], '$.name') AS '$.name'  --added
FROM #json t
  CROSS APPLY OPENJSON(json_col, '$') j
    CROSS APPLY OPENJSON(j.[value], '$') k
	   CROSS APPLY OPENJSON(k.[value], '$') l
WHERE k.[key] = 'parents'

--------------------------------------------------
-- What would happen if we didn't form a relationship
-- between the CROSS APPLY statements? If every one
-- referenced json_col again?

SELECT t.ArbitraryID
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