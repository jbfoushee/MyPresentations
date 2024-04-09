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

SELECT ArbitaryID, json_col
FROM #json

SELECT t.ArbitaryID
	, t.json_col
	, '|' AS '|'
	, j.[key] AS [j.key]
    , j.[value] AS  [j.value]
FROM #json t
  CROSS APPLY OPENJSON(json_col, '$') j

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



DECLARE @_json varchar(8000) = '
{
   "name":"Jesús Castillo"
   , "parents":[{"name":"Mary"},{"name":"Joseph"}]
   , "json_expert":true
}
'

INSERT INTO #json VALUES (@_json)

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

SELECT t.ArbitaryID
	, t.json_col
	, '|' AS '|'
    , j.[key] AS [j.key]
    , j.[value] AS  [j.value]
    , '|' AS '|'
	, k.[key]
    , k.[value] AS [k.value]
FROM #json t
  CROSS APPLY OPENJSON(json_col, '$') j
    CROSS APPLY OPENJSON(j.[value], '$') k

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

DROP TABLE #temp