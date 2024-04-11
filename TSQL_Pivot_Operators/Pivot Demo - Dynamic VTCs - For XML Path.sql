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

DECLARE @_VTCNames varchar(MAX); SET @_VTCNames = ''

SET @_VTCNames = STUFF(
(
  SELECT CONCAT(', [', [Year] , ']')
  FROM ( SELECT DISTINCT [Year] FROM dbo.[3ColPivot]  ) AS T
  ORDER BY [Year]
  FOR XML PATH(''), TYPE
).value('(./text())[1]', 'varchar(MAX)'), 1, 2, '');

SELECT @_VTCNames


----------------------------------------------------

DECLARE @_VTCNames varchar(MAX); SET @_VTCNames = ''

SET @_VTCNames = STUFF(
(
  SELECT CONCAT(', [', [Year] , ']')
  FROM ( SELECT DISTINCT [Year] FROM dbo.[3ColPivot] ) AS T
  ORDER BY [Year]
  FOR XML PATH(''), TYPE
).value('(./text())[1]', 'varchar(MAX)'), 1, 2, '');

DECLARE @_Stmt varchar(MAX); SET @_Stmt = ''

SET @_Stmt = @_Stmt + ' SELECT PivotResults.* '				 + CHAR(13)
SET @_Stmt = @_Stmt + ' FROM ( '							 + CHAR(13)
SET @_Stmt = @_Stmt + '      SELECT StoreID, [Year], Sales ' + CHAR(13)
SET @_Stmt = @_Stmt + '      FROM [dbo].[3ColPivot] '		 + CHAR(13)
SET @_Stmt = @_Stmt + ' ) AS RawData '						 + CHAR(13)
SET @_Stmt = @_Stmt + ' PIVOT ( '							 + CHAR(13)
SET @_Stmt = @_Stmt + '   SUM(Sales) '						 + CHAR(13)
SET @_Stmt = @_Stmt + '   FOR [Year] '						 + CHAR(13)
SET @_Stmt = @_Stmt + '   IN (' + @_VTCNames + ')'			 + CHAR(13)
SET @_Stmt = @_Stmt + '  ) AS PivotResults'					 + CHAR(13)
SET @_Stmt = @_Stmt + ' ORDER BY 1 ASC; '					 + CHAR(13)

PRINT @_Stmt

EXEC(@_Stmt)
