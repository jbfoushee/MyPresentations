--Review some truncated JSON

SELECT [ArbitraryID]
	,[LongJson]
	, ISJSON([LongJson]) AS [IsJson]
	, LEN([LongJson]) AS [Length]
FROM [JsonDemo].[dbo].[BigJsonAsOneRow]

-- Show them again under "Results as Text"

------------------------------------------------
-- Rebuild the original JSON using FOR JSON AUTO

SELECT [LongJson]
FROM [JsonDemo].[dbo].[BigJsonAsOneRow]

SELECT JSON_QUERY(LongJson, '$') AS [value]
FROM [JsonDemo].[dbo].[BigJsonAsOneRow]
FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER

------------------------------------------------
-- Caution though... any additional columns
-- will get wrapped-up into the JSON results

SELECT ArbitraryID, JSON_QUERY(LongJson, '$') AS [value]
FROM [JsonDemo].[dbo].[BigJsonAsOneRow]
FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER