-- Assuming SQL Management Studio ver 22.3 +

-- Let's show how FOR JSON AUTO can show beyond 65K characters, or even beyond the 2MB limit

CREATE TABLE [dbo].[BigJsonAsOneRow](
	[ArbitraryID] [int] IDENTITY (1,1) NOT NULL,
	[nvarchar_as_json] [nvarchar](max) NOT NULL,
    [json_as_json] json NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[BigJsonAsOneRow] WITH CHECK 
  ADD CONSTRAINT [chk_dbo.BigJsonAsOneRow__IsJson] 
    CHECK (ISJSON([nvarchar_as_json]) = 1)
GO

INSERT INTO [dbo].[BigJsonAsOneRow] ([nvarchar_as_json])
VALUES ('
-- Content of https://microsoftedge.github.io/Demos/json-dummy-data/128KB.json
')
UPDATE [dbo].[BigJsonAsOneRow]
SET [json_as_json] = [nvarchar_as_json]


--Review some truncated JSON

SELECT [ArbitraryID]
	, [nvarchar_as_json]
	, ISJSON([nvarchar_as_json]) AS [ISJSON(nvarchar)]
	, LEN([nvarchar_as_json]) AS [LEN(nvarchar)]
	, '|' AS '|'
	, json_as_json
	, DATALENGTH(json_as_json) AS [DATALENGTH(json)]
FROM [dbo].[BigJsonAsOneRow]
-- Can I take the text from the [nvarchar_as_json] field 
-- and paste it well-formed into Notepad?

------------------------------------------------
-- Rebuild the original JSON using FOR JSON AUTO

SELECT [nvarchar_as_json]
FROM [dbo].[BigJsonAsOneRow]

SELECT JSON_QUERY([nvarchar_as_json], '$') AS [value]
FROM [dbo].[BigJsonAsOneRow]
FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER

------------------------------------------------
-- Caution though... any additional columns
-- will get wrapped-up into the JSON results

SELECT ArbitraryID
  , JSON_QUERY([nvarchar_as_json], '$') AS [value]
FROM [dbo].[BigJsonAsOneRow]
FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER