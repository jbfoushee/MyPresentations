SELECT DISTINCT Year FROM dbo.[3ColPivot]
----------------------------------------------------

SELECT CONCAT(', [', [Year] , ']')
FROM ( SELECT DISTINCT Year FROM dbo.[3ColPivot] ) AS T
ORDER BY Year
----------------------------------------------------

SELECT CONCAT(', [', [Year] , ']')
FROM ( SELECT DISTINCT Year FROM dbo.[3ColPivot] ) AS T
ORDER BY Year
FOR XML PATH(''), TYPE
----------------------------------------------------

DECLARE @VTCNames varchar(MAX); SET @VTCNames = ''

SET @VTCNames = STUFF(
(
  SELECT CONCAT(', [', [Year] , ']')
  FROM ( SELECT DISTINCT [Year] FROM dbo.[3ColPivot]  ) AS T
  ORDER BY [Year]
  FOR XML PATH(''), TYPE
).value('(./text())[1]', 'varchar(MAX)'), 1, 2, '');

SELECT @VTCNames


----------------------------------------------------

DECLARE @VTCNames varchar(MAX); SET @VTCNames = ''

SET @VTCNames = STUFF(
(
  SELECT CONCAT(', [', [Year] , ']')
  FROM ( SELECT DISTINCT [Year] FROM dbo.[3ColPivot] ) AS T
  ORDER BY [Year]
  FOR XML PATH(''), TYPE
).value('(./text())[1]', 'varchar(MAX)'), 1, 2, '');

DECLARE @Stmt varchar(MAX); SET @Stmt = ''

SET @Stmt = @Stmt + ' SELECT PivotResults.* '						+ CHAR(13)
SET @Stmt = @Stmt + ' FROM ( '										+ CHAR(13)
SET @Stmt = @Stmt + '      SELECT StoreID, [Year], Sales '			+ CHAR(13)
SET @Stmt = @Stmt + '      FROM [dbo].[3ColPivot] '					+ CHAR(13)
SET @Stmt = @Stmt + ' ) AS RawData '								+ CHAR(13)
SET @Stmt = @Stmt + ' PIVOT ( '										+ CHAR(13)
SET @Stmt = @Stmt + '   SUM(Sales) '								+ CHAR(13)
SET @Stmt = @Stmt + '   FOR [Year] '								+ CHAR(13)
SET @Stmt = @Stmt + '   IN (' + @VTCNames + ')'						+ CHAR(13)
SET @Stmt = @Stmt + '  ) AS PivotResults'							+ CHAR(13)
SET @Stmt = @Stmt + ' ORDER BY 1 ASC; '								+ CHAR(13)

PRINT @Stmt

EXEC(@Stmt)
