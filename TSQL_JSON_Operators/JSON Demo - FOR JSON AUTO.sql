--Review some truncated JSON

SELECT [ArbitraryID]
	,[LongJson]
	, ISJSON([LongJson]) AS [IsJson]
	, LEN([LongJson]) AS [Length]
FROM [JsonDemo].[dbo].[BigJsonAsOneRow]

------------------------------------------------
-- Rebuild the original JSON using FOR JSON AUTO

SELECT JSON_QUERY(LongJson, '$') AS [value]
FROM [JsonDemo].[dbo].[BigJsonAsOneRow]
FOR JSON AUTO

------------------------------------------------
-- Caution though... any additional columns
-- will get wrapped-up into the JSON results

SELECT ArbitraryID, JSON_QUERY(LongJson, '$') AS [value]
FROM [JsonDemo].[dbo].[BigJsonAsOneRow]
FOR JSON AUTO