DROP TABLE IF EXISTS [dbo].[Persons];

CREATE TABLE [dbo].[Persons](
	[PersonID] [int] IDENTITY(1,1) NOT NULL,
	[JsonData] [varchar](8000) NOT NULL,
 
	CONSTRAINT [PK_Persons] PRIMARY KEY CLUSTERED 
	([PersonID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]

) ON [PRIMARY]

INSERT INTO dbo.Persons (JsonData)
VALUES('{
   "name":"Jeff Foushee"
   , "parents":[{"name":"Mom"},{"name":"Dad"}]
   , "json_expert":false
}')

DECLARE @_count int = 0

SET NOCOUNT ON;
WHILE @_count < 70000
	BEGIN
		SET @_count += 1

		DECLARE @_id uniqueidentifier = NEWID()

		DECLARE @_json varchar(8000)
		SET @_json = CONCAT(
			'{
			   "name":"', @_id, '"
			   , "parents":[{"name":"', @_id, '"},{"name":"', @_id, '"}]
			   , "json_expert":false
			}')

		INSERT INTO [dbo].[Persons] (JsonData)
		VALUES(@_json)
	END

-- Turn on Actual Execution Plan

SELECT * 
FROM dbo.Persons
WHERE JsonData LIKE '%"name":"Jeff Foushee"%'

SELECT *
FROM dbo.Persons
WHERE JSON_VALUE(JsonData, '$.name') = 'Jeff Foushee'

-- Add an index on JsonData

CREATE NONCLUSTERED INDEX [IX_dbo.Persons__JsonData] ON [dbo].[Persons]
(
	[JsonData] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]

-- Did anything change?

SELECT * 
FROM dbo.Persons
WHERE JsonData LIKE '%"name":"Jeff Foushee"%'

SELECT *
FROM dbo.Persons
WHERE JSON_VALUE(JsonData, '$.name') = 'Jeff Foushee'

-- then drop that crap index

DROP INDEX [IX_dbo.Persons__JsonData] ON [dbo].[Persons]

-- Add a vanilla computed column by script

ALTER TABLE dbo.Persons 
 ADD  name  
   AS JSON_VALUE([JsonData],'$.name') PERSISTED 

-- and an index on that computed column

CREATE NONCLUSTERED INDEX [IX_dbo.Persons__name] ON [dbo].[Persons]
(
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]

-- now the JSON_VALUE query is a seek

SELECT *
FROM dbo.Persons
WHERE JSON_VALUE(JsonData, '$.name') = 'Jeff Foushee'

-- But if we want to search by last name, this index is not effective

SELECT *
FROM dbo.Persons
WHERE JSON_VALUE(JsonData, '$.name') LIKE '%Foushee%'


-- Add a computed column (show manually for nuances)

ALTER TABLE dbo.Persons 
 ADD last_name  
   AS Convert(varchar(128)
		, RIGHT(JSON_VALUE([JsonData],'$.name')
             , LEN(JSON_VALUE([JsonData],'$.name'))
			    - CHARINDEX(' ',JSON_VALUE([JsonData],'$.name')) 
			)) PERSISTED 

-- Build index on last_name

CREATE NONCLUSTERED INDEX [IX_dbo.Persons__last_name] ON [dbo].[Persons]
(
	[last_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]

-- Did anything change?

SELECT *
FROM dbo.Persons
WHERE last_name = 'Foushee'