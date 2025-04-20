IF NOT EXISTS (SELECT 1 FROM dbo.Table_1 WHERE [value] = 'acf')
    INSERT INTO dbo.Table_1([value]) VALUES ('acf')

IF NOT EXISTS (SELECT 1 FROM dbo.Table_1 WHERE [value] = 'adf')
    INSERT INTO dbo.Table_1([value]) VALUES ('adf')

IF NOT EXISTS (SELECT 1 FROM dbo.Table_1 WHERE [value] = 'bcf')
    INSERT INTO dbo.Table_1([value]) VALUES ('bcf')

IF NOT EXISTS (SELECT 1 FROM dbo.Table_1 WHERE [value] = 'bdf')
    INSERT INTO dbo.Table_1([value]) VALUES ('bdf')

ALTER TABLE dbo.Table_1
  ALTER COLUMN [value] varchar(4)

INSERT INTO dbo.Table_1([value])
VALUES ('[c]f')
   , ('ac]f')
   , ('bc]f')
   , ('[d]f')
   , ('ad]f')
   , ('bd]f')

SELECT * FROM dbo.Table_1
WHERE [value] LIKE '[[ab][cd]][f]'
  