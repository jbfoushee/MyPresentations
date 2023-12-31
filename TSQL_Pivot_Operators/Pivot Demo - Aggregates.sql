SELECT *
INTO #tmp
FROM
  ( SELECT Convert(float,1) AS Number
	UNION ALL 
	SELECT Convert(float,2) AS Number
	UNION ALL 
	SELECT Convert(float, NULL) AS Number
	) a

SELECT Count(*) FROM #tmp
SELECT Count(Number) FROM #tmp
SELECT AVG(Number) FROM #tmp WHERE Number IS NOT NULL
SELECT AVG(Number) FROM #tmp
---------------------------------------------------------------------
SELECT *
INTO #tmp2
FROM
  ( SELECT Convert(float, NULL) AS Number
	UNION ALL 
	SELECT Convert(float, NULL) AS Number
	UNION ALL 
	SELECT Convert(float, NULL) AS Number
	) a

SELECT Count(*) FROM #tmp2
SELECT Count(Number) FROM #tmp2