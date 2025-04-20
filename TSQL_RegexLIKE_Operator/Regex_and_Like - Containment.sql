DECLARE @_value varchar(20) = ''
IF @_value LIKE '[]'
   PRINT 'yes, `` LIKE []'
ELSE 
   PRINT 'no, `` NOT LIKE []'

----------------------------------------------------------------------------

SELECT * FROM dbo.Table_1
WHERE [value] LIKE 'm[aeiou]d'

SELECT * FROM dbo.Table_1
WHERE [value] LIKE '%'

SELECT * FROM dbo.Table_1
WHERE [value] LIKE '[%]'

SELECT * FROM dbo.Table_1
WHERE ArbitraryID LIKE '%[2%]9[86][90]'

SELECT * FROM dbo.Table_1
WHERE ArbitraryID LIKE '_[2%]9[86][90]'

----------------------------------------------------------------------------

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
 
-- Wait, I thought...

SELECT * FROM dbo.Table_1
WHERE [value] LIKE '[abcd][f]'