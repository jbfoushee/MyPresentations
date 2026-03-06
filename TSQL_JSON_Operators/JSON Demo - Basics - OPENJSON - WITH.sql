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
	, j.*
FROM #json t
  CROSS APPLY OPENJSON(t.json_col, '$') j

-- CROSS APPLY using WITH()
SELECT t.*
	, '|' AS '|'
	, j.*
FROM #json t
  CROSS APPLY OPENJSON(t.json_col, '$')
       WITH ( [name] nvarchar(255)
	          , parents nvarchar(MAX) AS JSON
			  , json_expert bit
			) j

--------------------------------------------
-- Put a label on all the columns

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

-- and select only the JSON-based ones

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

SELECT t.ArbitraryID AS [t.ArbitraryID]
	, t.json_col AS [t.json_col]
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
    CROSS APPLY OPENJSON(t.json_col, '$.parents')  -- the same original t.json_col
		WITH
		    ( [name] nvarchar(255) 
			) k

--------------------------------------------
-- And rather than OPENJSON the entire json each time,
-- I will create a dependency between the CROSS APPLY statements
-- (There will be no change in output)

SELECT t.ArbitraryID AS [t.ArbitraryID]
	, t.json_col AS [t.json_col]
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
    CROSS APPLY OPENJSON(j.parents, '$')  -- this line changed to j.parents
		WITH
		    ( [name] nvarchar(255) 
			) k


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
    CROSS APPLY OPENJSON(j.parents, '$')  -- still j.parents
		WITH
		    ( [name] nvarchar(255) 
			) k

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

SELECT * FROM #json

--------------------------------------------------
-- Does our original CROSS APPLY statement work?

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
    CROSS APPLY OPENJSON(j.parents, '$')
		WITH
		    ( [name] nvarchar(255) 
			) k

-- Yes!

-- Did I really need that second CROSS APPLY to get the parents' names?
-- Could I not add parents to the first CROSS APPLY?

SELECT t.ArbitraryID
	, t.json_col
	, '|' AS '|'
	, j.[name] AS [j.name]
    , j.[json_expert] AS [j.json_expert]
	, '|' AS '|'
	, j.[parent] AS [k.name]
FROM #json t
  CROSS APPLY OPENJSON(t.json_col, '$')
       WITH ( [name] nvarchar(255)
	          , parent nvarchar(255) '$.parents.name'
			  , json_expert bit
			) j

-- No, because parents is an array.. 
-- Now you could add an index like so...

SELECT t.ArbitraryID
	, t.json_col
	, '|' AS '|'
	, j.[name] AS [j.name]
    , j.[json_expert] AS [j.json_expert]
	, '|' AS '|'
	, j.[parent] AS [k.name]
FROM #json t
  CROSS APPLY OPENJSON(t.json_col, '$')
       WITH ( [name] nvarchar(255)
	          , parent nvarchar(255) '$.parents[0].name'  -- [0] added
			  , json_expert bit
			) j

-- but you only get half the results.