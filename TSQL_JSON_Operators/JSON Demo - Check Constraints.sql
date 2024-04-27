CREATE TABLE [dbo].[Table1](
	[PersonID] [int] IDENTITY(1,1) NOT NULL,
	[JsonData] [varchar](8000) NOT NULL,
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Table1]  WITH CHECK 
	ADD CONSTRAINT [chk_dbo.Table1_JsonData__IsJson] 
		CHECK ( ISJSON([JsonData]) = 1 )
GO

ALTER TABLE [dbo].[Table1]  WITH CHECK 
	ADD CONSTRAINT [chk_dbo.Table1_JsonData__name.Exists] 
		CHECK ( JSON_PATH_EXISTS([JsonData], '$.name') = 1 )
GO

ALTER TABLE [dbo].[Table1]  WITH CHECK 
	ADD  CONSTRAINT [chk_dbo.Table1_JsonData__name.HasValue] 
		CHECK (
              TRIM(JSON_VALUE([JsonData],'$.name')) != ''
             AND JSON_VALUE([JsonData],'$.name') IS NOT NULL
           )
GO
------------------------------------------------------

--Which CHECK constraint fails for each of these statements? Why?
INSERT INTO [dbo].[Table1] (JsonData)
VALUES ('garbage')

INSERT INTO [dbo].[Table1] (JsonData)
VALUES ('{}')

INSERT INTO [dbo].[Table1] (JsonData)
VALUES ('{ "name" : null }')

INSERT INTO [dbo].[Table1] (JsonData)
VALUES ('{ "name" : NULL }')

INSERT INTO [dbo].[Table1] (JsonData)
VALUES ('{ "name" : "" }')

INSERT INTO [dbo].[Table1] (JsonData)
VALUES ('{ "name" : "                          " }')

--Why do these statements work?

INSERT INTO [dbo].[Table1] (JsonData)
VALUES ('{ "name" : "Jeff" }')

INSERT INTO [dbo].[Table1] (JsonData)
VALUES ('{ "name" : 1 }')

INSERT INTO [dbo].[Table1] (JsonData)
VALUES ('{ "name" : "null" }')  


-- "NA", "N/A", "Not Applicable", "00000", "99999"

-- Do I really want to go down this rabbit-hole? Or just allow NULL?
-- If this is an import, do I have the luxury of policing someone else's data?
-- Or do I have an ability to send bad records to another table?