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
	, ISJSON([LongJson]) AS [IsJson]
	, LEN([LongJson]) AS [Length]
FROM [dbo].[BigJsonAsOneRow]

-- Show them again under "Results as Text"

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