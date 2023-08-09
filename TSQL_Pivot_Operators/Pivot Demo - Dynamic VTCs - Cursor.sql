SELECT DISTINCT Year FROM dbo.[3ColPivot]
----------------------------------------------------

DECLARE @VTCNames varchar(MAX); SET @VTCNames = ''

DECLARE Cursor_VTCNames CURSOR LOCAL FAST_FORWARD FOR
  SELECT DISTINCT [Year]  FROM dbo.[3ColPivot] ORDER BY [Year]

DECLARE @variable varchar(50)
DECLARE @rowcount integer; SET @rowcount = 0

OPEN Cursor_VTCNames

FETCH NEXT FROM Cursor_VTCNames INTO @variable

WHILE @@FETCH_STATUS = 0
  BEGIN
    SET @rowcount = @rowcount + 1
    IF @rowcount > 1 SET @VTCNames = @VTCNames + ','
    SET @VTCNames = @VTCNames + '[' + @variable + ']'
    FETCH NEXT FROM Cursor_VTCNames INTO @variable 
  END

CLOSE Cursor_VTCNames; DEALLOCATE Cursor_VTCNames

PRINT @VTCNames

----------------------------------------------------

DECLARE @VTCNames varchar(MAX); SET @VTCNames = ''

DECLARE Cursor_VTCNames CURSOR LOCAL FAST_FORWARD FOR
  SELECT DISTINCT [Year] FROM dbo.[3ColPivot] ORDER BY [Year]

DECLARE @variable varchar(50)
DECLARE @rowcount integer; SET @rowcount = 0

OPEN Cursor_VTCNames

FETCH NEXT FROM Cursor_VTCNames INTO @variable

WHILE @@FETCH_STATUS = 0
  BEGIN
    SET @rowcount = @rowcount + 1
    IF @rowcount > 1 SET @VTCNames = @VTCNames + ','
    SET @VTCNames = @VTCNames + '[' + @variable + ']'
    FETCH NEXT FROM Cursor_VTCNames INTO @variable 
  END

CLOSE Cursor_VTCNames; DEALLOCATE Cursor_VTCNames

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
