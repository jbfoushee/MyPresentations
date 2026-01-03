-- Assuming SQL Management Studio ver 22
-- Go to Tools, Options...
-- Query Results, SQL Server
-- Results to Grid
-- Non-XML data is expected to be set to 65535

DECLARE @_json varchar(max)

SET @_json = '{ "key": "' 
SET @_json += REPLICATE('a', 8000) 
SET @_json += REPLICATE('b', 8000) 
SET @_json += REPLICATE('c', 8000) 
SET @_json += REPLICATE('d', 8000) 
SET @_json += REPLICATE('e', 8000) 
SET @_json += REPLICATE('f', 8000) 
SET @_json += REPLICATE('g', 8000) 
SET @_json += REPLICATE('h', 8000) 
SET @_json += REPLICATE('i', 1523)  
SET @_json += '"}'

-- We receive the hyperlink because we are in the limit of characters for Results to Grid
SELECT @_json, ISJSON(@_json) AS [ISJSON(@_json)], LEN(@_json) AS [LEN(@_json)]

----------------------------------------------------------------------------

DECLARE @_json varchar(max)

SET @_json = '{ "key": "' 
SET @_json += REPLICATE('a', 8000) 
SET @_json += REPLICATE('b', 8000) 
SET @_json += REPLICATE('c', 8000) 
SET @_json += REPLICATE('d', 8000) 
SET @_json += REPLICATE('e', 8000) 
SET @_json += REPLICATE('f', 8000) 
SET @_json += REPLICATE('g', 8000) 
SET @_json += REPLICATE('h', 8000) 
SET @_json += REPLICATE('i', 1523)  --<-- one more character
SET @_json += '"}'

-- Yet, here we no longer receive the hyperlink because we exceed the limit of characters for Results to Grid
SELECT @_json, ISJSON(@_json) AS [ISJSON(@_json)], LEN(@_json) AS [LEN(@_json)]

-----------------------------------------------------------------

-- Let's show how FOR JSON AUTO can show beyond 65K characters, or even beyond the 2MB limit

CREATE TABLE [dbo].[BigJsonAsOneRow](
	[ArbitraryID] [int] IDENTITY (1,1) NOT NULL,
	[LongJson] [nvarchar](max) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[BigJsonAsOneRow] WITH CHECK 
  ADD CONSTRAINT [chk_dbo.BigJsonAsOneRow__IsJson] 
    CHECK (ISJSON([LongJson]) = 1)
GO

INSERT INTO [dbo].[BigJsonAsOneRow] ([LongJson])
VALUES ('
-- Content of https://microsoftedge.github.io/Demos/json-dummy-data/128KB.json
')


--Review some truncated JSON

SELECT [ArbitraryID]
	, [LongJson]
	, ISJSON([LongJson]) AS [ISJSON(LongJson)]
	, LEN([LongJson]) AS [LEN(LongJson)]
FROM [dbo].[BigJsonAsOneRow]

------------------------------------------------
-- Rebuild the original JSON using FOR JSON AUTO

SELECT [LongJson]
FROM [dbo].[BigJsonAsOneRow]

SELECT JSON_QUERY(LongJson, '$') AS [value]
FROM [dbo].[BigJsonAsOneRow]
FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER

------------------------------------------------
-- Caution though... any additional columns
-- will get wrapped-up into the JSON results

SELECT ArbitraryID
  , JSON_QUERY(LongJson, '$') AS [value]
FROM [dbo].[BigJsonAsOneRow]
FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER